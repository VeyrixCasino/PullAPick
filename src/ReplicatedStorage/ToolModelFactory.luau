-- ToolModelFactory: builds a model for every tool and every backpack.
--
-- 70 tools (25 pickaxes, 15 drills, 15 ranged, 15 explosives) and every
-- backpack, all procedural. 77 hand-placed models would be 77 things that drift
-- apart; here a tool's look is derived from its family and how far up its ladder
-- it sits, so the whole set stays coherent and a new rung costs nothing.
--
-- Silhouette first. A shape has to be recognisable as a black cutout at ten
-- studs, which rules out the obvious approach of stacking axis-aligned boxes --
-- that is what makes a procedural pickaxe read as a mallet. So:
--
--   * pickaxes get a genuine swept double-pick arc, not a flat crossbar
--   * drills get a conical bit with a helical flight wound round it
--   * ranged gets a real barrel with a muzzle brake, scope and magazine
--   * explosives get a round casing with riveted bands and a curling fuse
--
-- Escalation up a ladder is geometry, not just tint: higher tiers grow longer
-- arcs, more flights, shrouds, vents, cells and lit edges.
local ToolModelFactory = {}

local function C3(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Walk a list of colours as one continuous ramp.
local function ramp(list, t)
	t = math.clamp(t, 0, 1)
	local n = #list
	if n == 1 then
		return list[1]
	end
	local x = t * (n - 1)
	local i = math.floor(x)
	local f = x - i
	return list[math.min(i + 1, n)]:Lerp(list[math.min(i + 2, n)], f)
end

--------------------------------------------------------------------------------
-- PRIMITIVES
--------------------------------------------------------------------------------

local function base(p, parent)
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function box(o, parent)
	local p = Instance.new("Part")
	p.Name = o.Name or "Piece"
	p.Size = o.Size or Vector3.one
	p.CFrame = o.CFrame or CFrame.identity
	p.Color = o.Color or C3(200, 200, 200)
	p.Material = o.Material or Enum.Material.SmoothPlastic
	p.Reflectance = o.Reflectance or 0
	p.Transparency = o.Transparency or 0
	return base(p, parent)
end

-- Cylinder along its own +Y, which is how every shape here is authored.
-- (Roblox's cylinder part runs along X, so it is rotated once, here.)
local function cyl(o, parent)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Name = o.Name or "Cyl"
	local len, dia = o.Length or 1, o.Dia or 1
	p.Size = Vector3.new(len, dia, o.Dia2 or dia)
	p.CFrame = (o.CFrame or CFrame.identity) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = o.Color or C3(200, 200, 200)
	p.Material = o.Material or Enum.Material.SmoothPlastic
	p.Reflectance = o.Reflectance or 0
	p.Transparency = o.Transparency or 0
	return base(p, parent)
end

local function ball(o, parent)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Name = o.Name or "Ball"
	local d = o.Dia or 1
	p.Size = Vector3.new(d, d, d)
	p.CFrame = o.CFrame or CFrame.identity
	p.Color = o.Color or C3(200, 200, 200)
	p.Material = o.Material or Enum.Material.SmoothPlastic
	p.Reflectance = o.Reflectance or 0
	p.Transparency = o.Transparency or 0
	return base(p, parent)
end

-- A cone, as a short stack of shrinking cylinders. Roblox has no cone part and
-- a mesh would mean an upload per tier; at these sizes the stack reads smooth.
local function cone(o, parent)
	local segs = o.Segs or 5
	local len, d0, d1 = o.Length or 1, o.Dia or 1, o.Tip or 0.06
	local cf = o.CFrame or CFrame.identity
	for i = 0, segs - 1 do
		local f0, f1 = i / segs, (i + 1) / segs
		cyl({
			Name = o.Name or "Cone",
			Length = len / segs + 0.012,
			Dia = d0 + (d1 - d0) * ((f0 + f1) * 0.5),
			CFrame = cf * CFrame.new(0, len * (f0 + f1) * 0.5, 0),
			Color = o.Color, Material = o.Material, Reflectance = o.Reflectance,
		}, parent)
	end
end

-- A chisel edge: two thin plates closing to a line. Cheaper and more legible
-- than a wedge, and it has no orientation gotchas.
local function edge(o, parent)
	local len, w, h = o.Length or 0.5, o.Width or 0.3, o.Height or 0.3
	local cf = o.CFrame or CFrame.identity
	for _, s in ipairs({ -1, 1 }) do
		box({
			Name = o.Name or "Edge",
			Size = Vector3.new(len, h * 0.55, w),
			CFrame = cf * CFrame.new(len * 0.5, s * h * 0.2, 0)
				* CFrame.Angles(0, 0, -s * math.rad(16)),
			Color = o.Color, Material = o.Material, Reflectance = o.Reflectance,
		}, parent)
	end
end

local function weldAll(model, handle)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= handle then
			local w = Instance.new("WeldConstraint")
			w.Part0 = handle
			w.Part1 = d
			w.Parent = handle
		end
	end
end

--------------------------------------------------------------------------------
-- PALETTES
--------------------------------------------------------------------------------

-- Pickaxe head, low tier to high.
local PICK_METAL = {
	C3(150, 132, 104), -- Splintered Haft, Chipped Crown: bone and weather
	C3(176, 148, 96),  -- Knapped Tooth, Bound Head: flint and amber
	C3(120, 128, 138), -- Tempered Bite, Trueheart: honest dull iron
	C3(122, 162, 192), -- Coldforge, Widow's Notch, Harrowpoint: blue steel
	C3(214, 118, 62),  -- Cinderbite, Glassbreaker: ember
	C3(96, 186, 148),  -- Verdigris Fang, Tidewrack: green corrosion and sea
	C3(186, 146, 255), -- Skyfallen, Voidworn, Starbitten: off-world violet
	C3(255, 214, 120), -- Eclipsefall to Worldsplitter: gold
}
-- Haft: raw wood, bound, charred, cold, scorched, corroded, void, gilded.
local PICK_HAFT = {
	C3(122, 90, 56),
	C3(96, 70, 44),
	C3(74, 68, 62),
	C3(66, 78, 92),
	C3(92, 58, 40),
	C3(46, 70, 62),
	C3(46, 42, 72),
	C3(102, 86, 44),
}
-- Drill body, by maker.
local DRILL_BODY = {
	C3(168, 108, 58),  -- Grendt: brass
	C3(196, 132, 66),  -- Grendt
	C3(150, 84, 62),   -- Grendt: oxblood
	C3(206, 168, 72),  -- Halvard: plant yellow
	C3(226, 186, 62),  -- Halvard
	C3(120, 128, 140), -- Halvard: bare steel
	C3(126, 140, 196), -- Kessler: cold
	C3(176, 150, 255), -- Kessler: deep violet
}
-- Drill bit: always the brightest thing on the model.
local DRILL_BIT = {
	C3(214, 196, 150),
	C3(190, 192, 198),
	C3(220, 224, 232),
	C3(184, 230, 255),
	C3(146, 212, 255),
	C3(204, 162, 255),
	C3(140, 108, 255),
	C3(226, 202, 132),
}
local GUN_BODY = {
	C3(88, 96, 112), C3(108, 120, 140), C3(88, 136, 178), C3(84, 168, 212),
	C3(104, 202, 242), C3(160, 168, 255), C3(116, 116, 242), C3(228, 184, 80),
}
local CELL = {
	C3(120, 224, 255), C3(104, 244, 220), C3(140, 255, 168), C3(255, 232, 116),
	C3(255, 158, 116), C3(224, 138, 255), C3(150, 118, 255), C3(255, 226, 132),
}
-- Charge casing, by grade.
local BOMB_BODY = {
	C3(78, 80, 60),    -- Snapfuse, Popcap: olive drab
	C3(96, 92, 64),
	C3(120, 96, 56),   -- Kegshot: brass casing
	C3(140, 78, 56),   -- Shatterstick
	C3(164, 72, 60),   -- Scattershot, Quickfire
	C3(184, 64, 92),   -- the lances
	C3(150, 56, 136),  -- the volleys
	C3(255, 152, 88),  -- Last Volley
}
local BOMB_TRIM = {
	C3(198, 132, 58), C3(218, 152, 70), C3(234, 180, 84), C3(255, 202, 96),
	C3(255, 170, 88), C3(255, 128, 108), C3(224, 120, 255), C3(238, 206, 120),
}

-- Body material by rung. Neon is deliberately NOT in this list: a Neon body
-- self-illuminates every face at once, so a top-tier tool came out as a white
-- blob with no readable form. Neon is for gems, cells and runes only; polished
-- Foil plus the reflectance ramp is what carries the high end.
local function metalFor(t)
	if t < 0.16 then
		return Enum.Material.Slate
	elseif t < 0.36 then
		return Enum.Material.Metal
	elseif t < 0.58 then
		return Enum.Material.DiamondPlate
	end
	return Enum.Material.Foil
end

local DARK = C3(26, 26, 32)

--------------------------------------------------------------------------------
-- PICKAXE
--
-- A swept double-pick. Each arm is a chain of tapering plates that turns a few
-- degrees per link, so the head curves down into a point instead of sticking out
-- flat. Low tiers are stubby with a hard hook; high tiers are long and shallow.
--------------------------------------------------------------------------------

local function pickArm(model, root, t, col, mat, lit)
	-- Roughly 45 degrees of sweep, spread over more links the higher the tier:
	-- enough for a hooked pick, well short of the crescent you get if each link
	-- turns as far as it wants to.
	--
	-- Arm length matters as much as curvature. An arm as long as the haft reads
	-- as a bow no matter how gently it curves, so one arm stays around 1.3-1.7
	-- studs against a 3.4-stud haft.
	local segs = 4 + math.floor(t * 1.5)
	local len = 0.26 + t * 0.02
	local turn = math.rad(7.5 - t * 2)
	local thick = 0.54 - t * 0.10
	local depth = 0.46 - t * 0.08

	local cur = CFrame.new(0.24, 0, 0) * CFrame.Angles(0, 0, math.rad(9))
	for j = 1, segs do
		local f = (j - 1) / segs
		box({
			Name = "Arm",
			Size = Vector3.new(len + 0.02, thick * (1 - f * 0.40), depth * (1 - f * 0.28)),
			CFrame = root * cur * CFrame.new(len * 0.5, 0, 0),
			Color = col:Lerp(C3(255, 255, 255), f * 0.14),
			Material = mat, Reflectance = 0.04 + t * 0.22,
		}, model)
		cur = cur * CFrame.new(len, 0, 0) * CFrame.Angles(0, 0, -turn)
	end
	edge({
		Name = "Tip", Length = 0.36 + t * 0.12, Width = depth * 0.62, Height = thick * 0.6,
		CFrame = root * cur,
		Color = col:Lerp(C3(255, 255, 255), 0.34), Material = mat, Reflectance = 0.1 + t * 0.3,
	}, model)
	if lit then
		box({
			Name = "Rune", Size = Vector3.new(len * segs * 0.72, 0.07, 0.09),
			CFrame = root * CFrame.new(0.24, 0, 0) * CFrame.Angles(0, 0, math.rad(-6))
				* CFrame.new(len * segs * 0.36, thick * 0.34, depth * 0.34),
			Color = lit, Material = Enum.Material.Neon,
		}, model)
	end
end

local function buildPickaxe(t, model)
	local metal = ramp(PICK_METAL, t)
	local haft = ramp(PICK_HAFT, t)
	local mat = metalFor(t)
	local lit = t > 0.66 and ramp(CELL, t) or nil

	-- Haft: a real shaft, tapered, with a flared pommel so it does not read as
	-- a broom handle.
	local handle = cyl({
		Name = "Handle", Length = 3.0, Dia = 0.32,
		CFrame = CFrame.new(0, -0.25, 0),
		Color = haft, Material = t < 0.5 and Enum.Material.Wood or Enum.Material.Metal,
	}, model)
	cyl({
		Name = "Taper", Length = 0.5, Dia = 0.39,
		CFrame = CFrame.new(0, 0.95, 0), Color = haft, Material = handle.Material,
	}, model)
	cyl({
		Name = "Pommel", Length = 0.24, Dia = 0.44,
		CFrame = CFrame.new(0, -1.66, 0), Color = metal, Material = mat, Reflectance = 0.1 + t * 0.2,
	}, model)
	ball({
		Name = "Cap", Dia = 0.34, CFrame = CFrame.new(0, -1.8, 0),
		Color = metal, Material = mat, Reflectance = 0.1 + t * 0.25,
	}, model)

	-- Grip winding: leather low down, machined collars once it is a real tool.
	for i = 0, 4 do
		cyl({
			Name = "Wrap", Length = 0.16, Dia = 0.37,
			CFrame = CFrame.new(0, -1.44 + i * 0.24, 0),
			Color = t < 0.55 and C3(60, 44, 30) or metal:Lerp(DARK, 0.4),
			Material = t < 0.55 and Enum.Material.Fabric or Enum.Material.Metal,
		}, model)
	end

	-- Eye: the collar the head is socketed through.
	box({
		Name = "Eye", Size = Vector3.new(0.56, 0.66, 0.5),
		CFrame = CFrame.new(0, 1.26, 0), Color = metal, Material = mat,
		Reflectance = 0.06 + t * 0.2,
	}, model)
	for _, s in ipairs({ -1, 1 }) do
		ball({
			Name = "Rivet", Dia = 0.15, CFrame = CFrame.new(s * 0.2, 1.26, 0.26),
			Color = metal:Lerp(C3(255, 255, 255), 0.3), Material = Enum.Material.Metal,
		}, model)
	end

	local head = CFrame.new(0, 1.32, 0)
	pickArm(model, head, t, metal, mat, lit)
	pickArm(model, head * CFrame.Angles(0, math.pi, 0), t, metal, mat, lit)

	-- A gem set in the eye from mid-ladder, a lit crown near the top.
	if t > 0.30 then
		ball({
			Name = "Gem", Dia = 0.30, CFrame = CFrame.new(0, 1.28, 0.3),
			Color = ramp(CELL, t), Material = Enum.Material.Neon,
		}, model)
		ball({
			Name = "Gem", Dia = 0.30, CFrame = CFrame.new(0, 1.28, -0.3),
			Color = ramp(CELL, t), Material = Enum.Material.Neon,
		}, model)
	end
	if t > 0.80 then
		cone({
			Name = "Crown", Length = 0.5, Dia = 0.26, Tip = 0.05, Segs = 4,
			CFrame = CFrame.new(0, 1.58, 0), Color = ramp(CELL, t), Material = Enum.Material.Neon,
		}, model)
	end
	return handle
end

--------------------------------------------------------------------------------
-- DRILL
--
-- Pistol grip, a barrel-shaped motor with a cooling shroud, a chuck, and a
-- conical bit with a helical flight wound round it. The helix is what makes it
-- read as a drill rather than a stack of discs.
--------------------------------------------------------------------------------

local function buildDrill(t, model)
	local body = ramp(DRILL_BODY, t)
	local bit = ramp(DRILL_BIT, t)
	local mat = metalFor(t)
	local lit = ramp(CELL, t)

	-- Everything is authored pointing along -Z, so the bit leads.
	local handle = box({
		Name = "Handle", Size = Vector3.new(0.42, 1.25, 0.5),
		CFrame = CFrame.new(0, -1.0, 0.32) * CFrame.Angles(math.rad(10), 0, 0),
		Color = DARK, Material = Enum.Material.Metal,
	}, model)
	cyl({
		Name = "GripPad", Length = 1.0, Dia = 0.44,
		CFrame = CFrame.new(0, -1.0, 0.36) * CFrame.Angles(math.rad(10), 0, 0),
		Color = C3(40, 40, 48), Material = Enum.Material.Fabric,
	}, model)
	box({
		Name = "Trigger", Size = Vector3.new(0.16, 0.36, 0.2),
		CFrame = CFrame.new(0, -0.5, 0.06), Color = C3(200, 190, 120), Material = Enum.Material.Metal,
	}, model)
	box({
		Name = "Guard", Size = Vector3.new(0.2, 0.1, 0.6),
		CFrame = CFrame.new(0, -0.72, 0.14), Color = DARK, Material = Enum.Material.Metal,
	}, model)

	-- Motor: a cylinder lying along -Z, with a ribbed shroud.
	cyl({
		Name = "Motor", Length = 1.9, Dia = 1.12,
		CFrame = CFrame.new(0, 0, 0.3) * CFrame.Angles(math.rad(90), 0, 0),
		Color = body, Material = mat, Reflectance = 0.05 + t * 0.2,
	}, model)
	for i = 0, 3 do
		cyl({
			Name = "Rib", Length = 0.1, Dia = 1.22,
			CFrame = CFrame.new(0, 0, 0.95 - i * 0.38) * CFrame.Angles(math.rad(90), 0, 0),
			Color = body:Lerp(DARK, 0.4), Material = Enum.Material.Metal,
		}, model)
	end
	box({
		Name = "Spine", Size = Vector3.new(0.36, 0.32, 1.6),
		CFrame = CFrame.new(0, 0.62, 0.3), Color = body:Lerp(DARK, 0.25), Material = mat,
	}, model)

	-- Chuck and bit. The cone is authored up its own +Y, so it is turned -90
	-- about X to send that down -Z; +90 would bury the whole bit in the motor.
	cyl({
		Name = "Chuck", Length = 0.44, Dia = 0.9,
		CFrame = CFrame.new(0, 0, -0.82) * CFrame.Angles(math.rad(90), 0, 0),
		Color = bit:Lerp(DARK, 0.3), Material = Enum.Material.Metal, Reflectance = 0.2,
	}, model)
	for i = 0, 5 do
		box({
			Name = "Jaw", Size = Vector3.new(0.1, 0.1, 0.46),
			CFrame = CFrame.new(0, 0, -0.82) * CFrame.Angles(0, 0, math.rad(i * 60))
				* CFrame.new(0, 0.42, 0),
			Color = bit, Material = Enum.Material.Metal, Reflectance = 0.3,
		}, model)
	end

	local blen = 1.75 + t * 1.15
	local bz = -1.02
	cone({
		Name = "Bit", Length = blen, Dia = 0.76, Tip = 0.08, Segs = 8,
		CFrame = CFrame.new(0, 0, bz) * CFrame.Angles(math.rad(-90), 0, 0),
		Color = bit, Material = mat, Reflectance = 0.15 + t * 0.3,
	}, model)
	-- Helical flight: plates spiralling down the cone, riding just proud of its
	-- surface so the bit reads as cut, not as a stack of discs.
	local flights = 14 + math.floor(t * 10)
	for i = 0, flights - 1 do
		local f = i / flights
		local r = 0.38 - f * 0.31
		local ang = f * math.rad(500)
		box({
			Name = "Flight",
			Size = Vector3.new(0.11, 0.34 - f * 0.24, 0.26),
			CFrame = CFrame.new(0, 0, bz - blen * f)
				* CFrame.Angles(0, 0, ang)
				* CFrame.new(r, 0, 0)
				* CFrame.Angles(0, math.rad(30), 0),
			Color = bit:Lerp(C3(255, 255, 255), 0.2 + f * 0.3),
			Material = mat, Reflectance = 0.2 + t * 0.3,
		}, model)
	end

	-- Power cell on the tail, then intakes and fins as the ladder climbs.
	cyl({
		Name = "Cell", Length = 0.66, Dia = 0.46,
		CFrame = CFrame.new(0, 0.06, 1.45) * CFrame.Angles(math.rad(90), 0, 0),
		Color = lit, Material = Enum.Material.Neon,
	}, model)
	cyl({
		Name = "CellCap", Length = 0.12, Dia = 0.56,
		CFrame = CFrame.new(0, 0.06, 1.2) * CFrame.Angles(math.rad(90), 0, 0),
		Color = body:Lerp(DARK, 0.4), Material = Enum.Material.Metal,
	}, model)
	if t > 0.35 then
		for _, s in ipairs({ -1, 1 }) do
			box({
				Name = "Intake", Size = Vector3.new(0.13, 0.48, 1.0),
				CFrame = CFrame.new(s * 0.62, 0.1, 0.45) * CFrame.Angles(0, 0, s * math.rad(10)),
				Color = body:Lerp(DARK, 0.3), Material = mat,
			}, model)
		end
	end
	if t > 0.62 then
		box({
			Name = "Gauge", Size = Vector3.new(0.36, 0.18, 0.26),
			CFrame = CFrame.new(0, 0.76, 0.95), Color = lit, Material = Enum.Material.Neon,
		}, model)
	end
	if t > 0.80 then
		for _, s in ipairs({ -1, 1 }) do
			box({
				Name = "Fin", Size = Vector3.new(0.1, 0.78, 0.78),
				CFrame = CFrame.new(s * 0.66, 0.34, 0.55) * CFrame.Angles(0, 0, s * math.rad(24)),
				Color = lit, Material = Enum.Material.Neon,
			}, model)
		end
	end
	return handle
end

--------------------------------------------------------------------------------
-- RANGED
--
-- A mining blaster: barrel with a muzzle brake, receiver, angled foregrip,
-- magazine cell, scope on a rail, and a stock. Authored down -Z.
--------------------------------------------------------------------------------

local function buildRanged(t, model)
	local body = ramp(GUN_BODY, t)
	local lit = ramp(CELL, t)
	local mat = metalFor(t)

	local handle = box({
		Name = "Handle", Size = Vector3.new(0.34, 1.05, 0.44),
		CFrame = CFrame.new(0, -0.78, 0.42) * CFrame.Angles(math.rad(14), 0, 0),
		Color = DARK, Material = Enum.Material.Metal,
	}, model)
	box({
		Name = "GripPad", Size = Vector3.new(0.38, 0.72, 0.2),
		CFrame = CFrame.new(0, -0.8, 0.62) * CFrame.Angles(math.rad(14), 0, 0),
		Color = C3(44, 44, 52), Material = Enum.Material.Fabric,
	}, model)
	box({
		Name = "Guard", Size = Vector3.new(0.16, 0.1, 0.6),
		CFrame = CFrame.new(0, -0.34, 0.24), Color = DARK, Material = Enum.Material.Metal,
	}, model)
	box({
		Name = "Trigger", Size = Vector3.new(0.1, 0.26, 0.12),
		CFrame = CFrame.new(0, -0.2, 0.3), Color = C3(200, 190, 120), Material = Enum.Material.Metal,
	}, model)

	-- Receiver, with a chamfer rail so it is not a plain slab.
	box({
		Name = "Receiver", Size = Vector3.new(0.56, 0.66, 2.0),
		CFrame = CFrame.new(0, 0.06, -0.25), Color = body, Material = mat,
		Reflectance = 0.05 + t * 0.2,
	}, model)
	box({
		Name = "Rail", Size = Vector3.new(0.3, 0.14, 1.7),
		CFrame = CFrame.new(0, 0.44, -0.35), Color = DARK, Material = Enum.Material.Metal,
	}, model)
	box({
		Name = "Ejector", Size = Vector3.new(0.6, 0.3, 0.5),
		CFrame = CFrame.new(0, 0.1, 0.2), Color = body:Lerp(DARK, 0.35), Material = mat,
	}, model)

	-- Stock: two struts and a butt plate, so it reads as a frame.
	box({
		Name = "Strut", Size = Vector3.new(0.16, 0.14, 1.1),
		CFrame = CFrame.new(0, 0.3, 1.15), Color = body:Lerp(DARK, 0.3), Material = mat,
	}, model)
	box({
		Name = "Strut", Size = Vector3.new(0.16, 0.14, 1.1),
		CFrame = CFrame.new(0, -0.16, 1.15) * CFrame.Angles(math.rad(-6), 0, 0),
		Color = body:Lerp(DARK, 0.3), Material = mat,
	}, model)
	box({
		Name = "Butt", Size = Vector3.new(0.4, 0.8, 0.22),
		CFrame = CFrame.new(0, 0.1, 1.68) * CFrame.Angles(math.rad(-6), 0, 0),
		Color = DARK, Material = Enum.Material.Metal,
	}, model)

	-- Barrel, shroud and muzzle brake. Length is the clearest tier signal.
	local blen = 1.5 + t * 1.7
	cyl({
		Name = "Barrel", Length = blen, Dia = 0.26,
		CFrame = CFrame.new(0, 0.08, -1.25 - blen * 0.5) * CFrame.Angles(math.rad(90), 0, 0),
		Color = body:Lerp(C3(255, 255, 255), 0.16), Material = mat, Reflectance = 0.12 + t * 0.28,
	}, model)
	local rings = 3 + math.floor(t * 3)
	for i = 0, rings - 1 do
		cyl({
			Name = "Shroud", Length = 0.12, Dia = 0.48 - i * 0.02,
			CFrame = CFrame.new(0, 0.08, -1.35 - (blen * 0.86) * (i / rings))
				* CFrame.Angles(math.rad(90), 0, 0),
			Color = body:Lerp(DARK, 0.25), Material = mat,
		}, model)
	end
	cyl({
		Name = "Brake", Length = 0.34, Dia = 0.42,
		CFrame = CFrame.new(0, 0.08, -1.3 - blen) * CFrame.Angles(math.rad(90), 0, 0),
		Color = body:Lerp(DARK, 0.15), Material = mat, Reflectance = 0.2,
	}, model)
	for i = 0, 3 do
		box({
			Name = "Port", Size = Vector3.new(0.08, 0.08, 0.26),
			CFrame = CFrame.new(0, 0.08, -1.3 - blen) * CFrame.Angles(0, 0, math.rad(45 + i * 90))
				* CFrame.new(0, 0.2, 0),
			Color = DARK, Material = Enum.Material.Metal,
		}, model)
	end
	cyl({
		Name = "Muzzle", Length = 0.14, Dia = 0.3,
		CFrame = CFrame.new(0, 0.08, -1.48 - blen) * CFrame.Angles(math.rad(90), 0, 0),
		Color = lit, Material = Enum.Material.Neon,
	}, model)

	-- Foregrip.
	box({
		Name = "Foregrip", Size = Vector3.new(0.24, 0.6, 0.28),
		CFrame = CFrame.new(0, -0.28, -1.5) * CFrame.Angles(math.rad(-12), 0, 0),
		Color = DARK, Material = Enum.Material.Metal,
	}, model)

	-- Magazine cell.
	box({
		Name = "Cell", Size = Vector3.new(0.36, 0.5, 0.6),
		CFrame = CFrame.new(0, -0.42, -0.2) * CFrame.Angles(math.rad(-6), 0, 0),
		Color = lit, Material = Enum.Material.Neon,
	}, model)
	box({
		Name = "CellClamp", Size = Vector3.new(0.42, 0.16, 0.66),
		CFrame = CFrame.new(0, -0.2, -0.2), Color = body:Lerp(DARK, 0.4), Material = mat,
	}, model)

	-- Optics: irons low down, a lit scope higher up.
	if t < 0.4 then
		box({
			Name = "Sight", Size = Vector3.new(0.08, 0.24, 0.08),
			CFrame = CFrame.new(0, 0.62, -1.0), Color = DARK, Material = Enum.Material.Metal,
		}, model)
		box({
			Name = "Sight", Size = Vector3.new(0.2, 0.18, 0.08),
			CFrame = CFrame.new(0, 0.6, 0.1), Color = DARK, Material = Enum.Material.Metal,
		}, model)
	else
		cyl({
			Name = "Scope", Length = 0.95, Dia = 0.34,
			CFrame = CFrame.new(0, 0.64, -0.5) * CFrame.Angles(math.rad(90), 0, 0),
			Color = DARK, Material = Enum.Material.Metal, Reflectance = 0.15,
		}, model)
		cyl({
			Name = "Lens", Length = 0.07, Dia = 0.3,
			CFrame = CFrame.new(0, 0.64, -0.99) * CFrame.Angles(math.rad(90), 0, 0),
			Color = lit, Material = Enum.Material.Neon,
		}, model)
		for _, s in ipairs({ -1, 1 }) do
			box({
				Name = "Mount", Size = Vector3.new(0.1, 0.2, 0.12),
				CFrame = CFrame.new(0, 0.5, -0.5 + s * 0.34), Color = DARK,
				Material = Enum.Material.Metal,
			}, model)
		end
	end
	if t > 0.68 then
		for _, s in ipairs({ -1, 1 }) do
			box({
				Name = "Coil", Size = Vector3.new(0.1, 0.16, blen * 0.5),
				CFrame = CFrame.new(s * 0.2, 0.08, -1.5 - blen * 0.3),
				Color = lit, Material = Enum.Material.Neon,
			}, model)
		end
	end
	return handle
end

--------------------------------------------------------------------------------
-- EXPLOSIVE
--
-- Round casing on a throwing haft: riveted bands, a curling fuse at the bottom
-- of the ladder, a finned detonator with an antenna at the top.
--------------------------------------------------------------------------------

local function buildExplosive(t, model)
	local body = ramp(BOMB_BODY, t)
	local trim = ramp(BOMB_TRIM, t)
	local mat = t < 0.5 and Enum.Material.Metal or Enum.Material.DiamondPlate
	local lit = ramp(CELL, t)

	-- The charge is the object; the haft is just something to hold it by. Keep
	-- the stick short or the whole thing reads as a lollipop.
	local r = 1.35 + t * 0.7
	local cy = r * 0.5 + 0.35

	local handle = cyl({
		Name = "Handle", Length = 1.15, Dia = 0.36,
		CFrame = CFrame.new(0, -0.35, 0),
		Color = C3(78, 58, 40), Material = t < 0.5 and Enum.Material.Wood or Enum.Material.Metal,
	}, model)
	for i = 0, 2 do
		cyl({
			Name = "Wrap", Length = 0.14, Dia = 0.43,
			CFrame = CFrame.new(0, -0.72 + i * 0.26, 0),
			Color = C3(52, 38, 26), Material = Enum.Material.Fabric,
		}, model)
	end
	cyl({
		Name = "Cap", Length = 0.16, Dia = 0.46,
		CFrame = CFrame.new(0, -0.95, 0), Color = trim, Material = Enum.Material.Metal,
	}, model)
	cyl({
		Name = "Collar", Length = 0.34, Dia = 0.62,
		CFrame = CFrame.new(0, cy - r * 0.48, 0), Color = trim, Material = Enum.Material.Metal,
		Reflectance = 0.15,
	}, model)

	ball({
		Name = "Casing", Dia = r, CFrame = CFrame.new(0, cy, 0),
		Color = body, Material = mat, Reflectance = 0.06 + t * 0.2,
	}, model)
	-- Equator band plus two latitude bands, with rivets round the belt.
	for _, o in ipairs({ { 0, 1.015 }, { 0.3, 0.9 }, { -0.3, 0.9 } }) do
		cyl({
			Name = "Band", Length = 0.11, Dia = r * o[2],
			CFrame = CFrame.new(0, cy + o[1] * r, 0), Color = trim,
			Material = Enum.Material.Metal, Reflectance = 0.2,
		}, model)
	end
	for i = 0, 7 do
		ball({
			Name = "Rivet", Dia = 0.13,
			CFrame = CFrame.new(0, cy, 0) * CFrame.Angles(0, math.rad(i * 45), 0)
				* CFrame.new(0, 0, r * 0.51),
			Color = trim:Lerp(C3(255, 255, 255), 0.35), Material = Enum.Material.Metal,
		}, model)
	end

	if t < 0.45 then
		-- Fuse: a curling chain of small cylinders with an ember on the end.
		local cur = CFrame.new(0, cy + r * 0.46, 0)
		cyl({
			Name = "Neck", Length = 0.22, Dia = 0.34, CFrame = cur,
			Color = trim, Material = Enum.Material.Metal,
		}, model)
		for _ = 1, 6 do
			cur = cur * CFrame.Angles(0, 0, math.rad(15)) * CFrame.new(0, 0.21, 0)
			cyl({
				Name = "Fuse", Length = 0.23, Dia = 0.11, CFrame = cur,
				Color = C3(196, 176, 138), Material = Enum.Material.Fabric,
			}, model)
		end
		ball({
			Name = "Ember", Dia = 0.26, CFrame = cur * CFrame.new(0, 0.15, 0),
			Color = C3(255, 214, 120), Material = Enum.Material.Neon,
		}, model)
	else
		-- Detonator: housing, readout, antenna, and fins that make it fly.
		box({
			Name = "Detonator", Size = Vector3.new(0.56, 0.38, 0.44),
			CFrame = CFrame.new(0, cy + r * 0.5, 0), Color = DARK, Material = Enum.Material.Metal,
		}, model)
		box({
			Name = "Readout", Size = Vector3.new(0.38, 0.2, 0.06),
			CFrame = CFrame.new(0, cy + r * 0.5, 0.23), Color = C3(255, 96, 84),
			Material = Enum.Material.Neon,
		}, model)
		cyl({
			Name = "Antenna", Length = 0.68, Dia = 0.08,
			CFrame = CFrame.new(0.16, cy + r * 0.5 + 0.46, 0) * CFrame.Angles(0, 0, math.rad(-12)),
			Color = C3(150, 154, 162), Material = Enum.Material.Metal,
		}, model)
		ball({
			Name = "Beacon", Dia = 0.17,
			CFrame = CFrame.new(0.23, cy + r * 0.5 + 0.8, 0), Color = lit, Material = Enum.Material.Neon,
		}, model)
		for i = 0, 3 do
			box({
				Name = "Fin", Size = Vector3.new(0.1, 0.62, 0.5),
				CFrame = CFrame.new(0, cy - r * 0.26, 0) * CFrame.Angles(0, math.rad(i * 90 + 45), 0)
					* CFrame.new(r * 0.5, 0, 0) * CFrame.Angles(0, 0, math.rad(8)),
				Color = trim, Material = Enum.Material.Metal,
			}, model)
		end
	end

	-- Warning chevrons, then a lit core at the top of the ladder.
	if t > 0.25 then
		for i = 0, 4 do
			box({
				Name = "Stripe", Size = Vector3.new(0.11, 0.3, 0.04),
				CFrame = CFrame.new(0, cy, 0) * CFrame.Angles(0, math.rad(i * 22 - 44), 0)
					* CFrame.new(0, -r * 0.16, r * 0.5),
				Color = C3(250, 224, 92), Material = Enum.Material.SmoothPlastic,
			}, model)
		end
	end
	-- Glow through vents cut in the shell, rather than a translucent shell over
	-- the whole thing -- that just fogs the casing out to a white ball.
	if t > 0.6 then
		for i = 0, 5 do
			box({
				Name = "Vent", Size = Vector3.new(0.1, r * 0.44, 0.06),
				CFrame = CFrame.new(0, cy, 0) * CFrame.Angles(0, math.rad(i * 60 + 30), 0)
					* CFrame.new(0, 0, r * 0.5) * CFrame.Angles(0, 0, math.rad(18)),
				Color = lit, Material = Enum.Material.Neon,
			}, model)
		end
		ball({
			Name = "Core", Dia = r * 0.34, CFrame = CFrame.new(0, cy, 0),
			Color = lit, Material = Enum.Material.Neon,
		}, model)
	end
	return handle
end

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- LUNAR / HALF-MOON PICK (Battle Pass)
-- One crescent blade only — reads as a half moon at a glance, not a twin-arm pick.
--------------------------------------------------------------------------------

local function buildLunarPickaxe(variant, model)
	local eclipse = variant == "lunar_eclipse"
	local metal = eclipse and C3(48, 52, 78) or C3(198, 214, 236)
	local haft = eclipse and C3(28, 24, 40) or C3(72, 68, 88)
	local lit = eclipse and C3(180, 120, 255) or C3(160, 210, 255)
	local mat = Enum.Material.Metal

	local handle = cyl({
		Name = "Handle", Length = 3.05, Dia = 0.30,
		CFrame = CFrame.new(0, -0.28, 0),
		Color = haft, Material = Enum.Material.Wood,
	}, model)
	cyl({
		Name = "Wrap", Length = 0.9, Dia = 0.36,
		CFrame = CFrame.new(0, -0.95, 0),
		Color = eclipse and C3(40, 32, 52) or C3(90, 86, 110),
		Material = Enum.Material.Fabric,
	}, model)
	cyl({
		Name = "Pommel", Length = 0.22, Dia = 0.42,
		CFrame = CFrame.new(0, -1.72, 0),
		Color = metal, Material = mat, Reflectance = 0.35,
	}, model)
	ball({
		Name = "MoonCap", Dia = 0.38, CFrame = CFrame.new(0, -1.88, 0),
		Color = lit, Material = Enum.Material.Neon,
	}, model)

	box({
		Name = "Eye", Size = Vector3.new(0.52, 0.62, 0.48),
		CFrame = CFrame.new(0, 1.22, 0), Color = metal, Material = mat, Reflectance = 0.28,
	}, model)

	local segs = 10
	local len = 0.28
	local turn = math.rad(17)
	local thick = 0.42
	local depth = 0.34
	local cur = CFrame.new(0.18, 0, 0) * CFrame.Angles(0, 0, math.rad(4))
	local head = CFrame.new(0, 1.28, 0)
	for j = 1, segs do
		local f = (j - 1) / segs
		box({
			Name = "Crescent",
			Size = Vector3.new(len + 0.02, thick * (1 - f * 0.35), depth * (1 - f * 0.25)),
			CFrame = head * cur * CFrame.new(len * 0.5, 0, 0),
			Color = metal:Lerp(C3(255, 255, 255), f * 0.22),
			Material = mat, Reflectance = 0.2 + f * 0.25,
		}, model)
		if j % 2 == 0 then
			box({
				Name = "MoonEdge",
				Size = Vector3.new(len * 0.9, 0.06, 0.08),
				CFrame = head * cur * CFrame.new(len * 0.5, thick * 0.28, depth * 0.28),
				Color = lit, Material = Enum.Material.Neon,
			}, model)
		end
		cur = cur * CFrame.new(len, 0, 0) * CFrame.Angles(0, 0, -turn)
	end
	edge({
		Name = "Tip", Length = 0.42, Width = depth * 0.45, Height = thick * 0.4,
		CFrame = head * cur,
		Color = lit, Material = Enum.Material.Neon, Reflectance = 0.4,
	}, model)

	ball({
		Name = "Gem", Dia = 0.28, CFrame = CFrame.new(0, 1.24, 0.28),
		Color = lit, Material = Enum.Material.Neon,
	}, model)
	if eclipse then
		ball({
			Name = "Umbra", Dia = 0.22, CFrame = CFrame.new(0.06, 1.24, 0.32),
			Color = C3(12, 10, 18), Material = Enum.Material.SmoothPlastic,
		}, model)
	end
	return handle
end

local BUILDERS = {
	pickaxe = buildPickaxe, drill = buildDrill, explosive = buildExplosive,
}
-- buildRanged is deliberately not in BUILDERS: the ranged family was cut, and
-- build() falls back to pickaxe for anything it does not recognise. Kept in the
-- file because the shape is good and weapons are still a planned family.
local _ = buildRanged

-- How each family sits in the hand.
--
-- Roblox welds a tool as
--     Handle.CFrame = RightHand.CFrame * RightGrip.C0 * Grip:Inverse()
-- so applying a rotation L in the handle's OWN frame means Grip = L:Inverse().
--
-- Measured, not guessed, and the measurement had to be redone once: reading
-- Handle.CFrame.UpVector looked correct while the pick was visibly sideways,
-- because cyl() builds a Roblox cylinder (which runs along its own X) and then
-- turns the part 90 degrees about Z. The haft is therefore the part's
-- RightVector, not its UpVector. Reading the wrong axis is what made three
-- earlier "verified" grips ship broken.
--
-- With an identity grip the haft lies along the character's +X -- straight out
-- to the side, which is exactly the sideways hold players saw. HAFT_UP is the
-- cyclic map X->Y, Y->Z, Z->X: it stands the haft up and turns the head into
-- the fore/aft swing plane so one point leads.
local HAFT_UP = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 1, 0), Vector3.new(0, 0, 1))

local GRIPS = {
	-- Hafted tools: stand it up, lean it forward, and slide the grip down the
	-- haft so the hand sits on the lower third and the head rides at shoulder
	-- height rather than swinging round the knees.
	pickaxe = (HAFT_UP * CFrame.Angles(0, 0, math.rad(14)) * CFrame.new(0.7, 0, 0)):Inverse(),
	explosive = (HAFT_UP * CFrame.Angles(0, 0, math.rad(10)) * CFrame.new(0.45, 0, 0)):Inverse(),
	-- Machines are authored with the grip up +Y and the working end down -Z,
	-- which is already how an identity grip lands them: up is up, forward is
	-- forward. They only need settling into the palm.
	drill = CFrame.new(0, -0.25, 0.2),
}

-- Each family is authored at whatever proportions read best on its own, then
-- brought to a common held size here. A drill drawn to look like a drill comes
-- out over five studs long, which on a character is a lance; one knob per
-- family beats re-tuning thirty literals every time the shape changes.
--
-- Target: a held tool reads at roughly 3.5 studs against a 5-stud character,
-- with the pickaxe deliberately larger because it is the two-handed one.
local SCALE = { pickaxe = 1.28, drill = 0.68, explosive = 0.74 }

--[[
	NAMED HQ MESHES IN THE HAND.

	The named meshes (ReplicatedStorage.ToolModels_50) arrive at wild authored
	sizes and in whatever orientation their author left them. Each one is fitted
	to a held size in the same band as the ladder builds (a ladder pick is ~4.6
	studs, a drill 3.1-3.9, a bomb 2.6-3.2), then posed:

	  pickaxe: the haft runs up +X of the Handle to the head, the head's widest
	    spread lies fore/aft so a point leads the swing, and the hand sits 28% of
	    the way up the handle.
	  drill: the bit points down -Z, +Y is up, the hand is on the grip group (or
	    the body when there is none).
	  explosive: fuse or cap up, sitting on the fist.

	Measure GEOMETRY, never Part.Position. Many of these meshes are unions whose
	CFrame sits at the authoring origin, up to 16 studs from what you see;
	ExtentsCFrame/ExtentsSize describe the visible shape. Reading Position is
	what put Hillforge's hand 15 studs down its haft and held a dozen of these
	upside down.
]]
local NAMED_FIT = {
	pickaxe = 4.1,
	drill = 3.2,
	explosive = 2.6,
	default = 3.8,
}

-- Only for callers that pass no family. The server and the shop both pass the
-- ladder row's family; names alone mislead (Doublebit is a pick, Rockjack and
-- Divepod are drills).
local NAMED_FAMILY = {
	["Twig Auger"] = "drill", Twistauger = "drill", Rockjack = "drill", Jackbore = "drill", Sootgear = "drill",
	Violetbit = "drill", Pressurebit = "drill", Brassbit = "drill", Divepod = "drill",
	Coraluger = "drill",
	["Spark Charge"] = "explosive", Clayfuse = "explosive", Crimpsticks = "explosive", Nightorb = "explosive",
	Depthdrum = "explosive", Capbrick = "explosive", Seedsack = "explosive",
	Urchinmine = "explosive", Glassfloat = "explosive", Eclipse = "explosive",
	["Prototype Alpha"] = "pickaxe", ["Prototype Beta"] = "drill", ["Prototype Gamma"] = "explosive",
	["Geothermal Nuke"] = "explosive",
}

-- Hand-set axes, in the stored model's world axes, for meshes with no named
-- groups to read or whose groups mislead. Checked one by one on a contact
-- sheet of all 42 held in a raised hand.
--   axis    = the haft direction, head at the + end (pickaxes)
--   forward = the way the bit points; up = which side is up (drills)
--   up      = the fuse/cap side (explosives)
local NAMED_POSE = {
	Basaltiron = { axis = Vector3.yAxis },
	Coilpick = { axis = Vector3.yAxis },
	Irongrasp = { axis = Vector3.yAxis },
	Ironvine = { axis = Vector3.yAxis },
	Pressurebit = { forward = Vector3.yAxis, up = -Vector3.zAxis },
	Violetbit = { forward = -Vector3.yAxis, up = Vector3.zAxis },
	Sootgear = { forward = Vector3.zAxis },
	Capbrick = { up = Vector3.xAxis },
	Crimpsticks = { up = Vector3.xAxis },
	-- Generated single meshes whose ends measure too even to call, or whose
	-- body stands taller than the bit is long. Checked by eye.
	Heartbore = { forward = -Vector3.yAxis },
	Latticecage = { forward = Vector3.yAxis },
	Penumbraring = { forward = Vector3.yAxis },
	Rootjack = { forward = -Vector3.yAxis },
	Arctorch = { forward = Vector3.xAxis, up = Vector3.yAxis },
	Twoflute = { forward = -Vector3.zAxis, up = Vector3.yAxis },
	Umbrajack = { forward = -Vector3.zAxis, up = Vector3.yAxis },
	Sodauger = { forward = -Vector3.zAxis, up = Vector3.yAxis },
	Shadebrick = { up = -Vector3.zAxis },
	Fossilstrut = { forward = Vector3.new(0, 0.83, -0.56).Unit },
	Prismbore = { forward = Vector3.new(0, -0.76, -0.65).Unit },
	Podjack = { forward = Vector3.new(0, -0.45, 0.9).Unit, up = Vector3.yAxis },
	Voidbit = { forward = -Vector3.xAxis, up = Vector3.yAxis },
}

local HAFT_LEAN = { pickaxe = 14, explosive = 10 }

local function nameKey(s)
	return (string.lower(tostring(s)):gsub("[%s_]+", ""))
end

local function namedParts(inst)
	local t = {}
	if inst:IsA("BasePart") then
		t[#t + 1] = inst
	end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then
			t[#t + 1] = d
		end
	end
	return t
end

-- Volume-weighted centre of the visible geometry.
local function geoCentroid(parts)
	local sum, w = Vector3.zero, 0
	for _, p in ipairs(parts) do
		local s = p.ExtentsSize
		local v = math.max(s.X * s.Y * s.Z, 1e-4)
		sum += p.ExtentsCFrame.Position * v
		w += v
	end
	return w > 0 and sum / w or nil
end

-- How far the geometry reaches along `dir`, measured from `origin`.
local function geoSpan(parts, origin, dir)
	local lo, hi = math.huge, -math.huge
	for _, p in ipairs(parts) do
		local cf, h = p.ExtentsCFrame, p.ExtentsSize * 0.5
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local d = (cf:PointToWorldSpace(Vector3.new(sx * h.X, sy * h.Y, sz * h.Z)) - origin):Dot(dir)
					if d < lo then lo = d end
					if d > hi then hi = d end
				end
			end
		end
	end
	return lo, hi
end

-- Parts under the model's top-level groups whose names contain any key.
local function groupParts(model, keys)
	local t = {}
	for _, c in ipairs(model:GetChildren()) do
		local k = nameKey(c.Name)
		for _, want in ipairs(keys) do
			if k:find(want, 1, true) then
				for _, p in ipairs(namedParts(c)) do
					t[#t + 1] = p
				end
				break
			end
		end
	end
	return t
end

-- The stored meshes are axis-aligned, so directions snap to a world axis.
local WORLD_AXES = { Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis }
local function snapAxis(v, notAlong)
	local best, bd = Vector3.yAxis, -math.huge
	for _, a in ipairs(WORLD_AXES) do
		if not notAlong or math.abs(a:Dot(notAlong)) < 0.5 then
			local d = a:Dot(v)
			if d > bd then
				best, bd = a, d
			end
		end
	end
	return best
end

local SHAFT_NAME_SCORE = {
	gripshaft = 100, mainhaft = 95, coreshaft = 95, mainshaft = 95, woodshaft = 90,
	coppershaft = 90, shaftcore = 90, centralshaft = 90, maingrip = 85,
	haft = 80, shaft = 75, grip = 70, handle = 60, body = 10,
}

local function scoreShaftCandidate(part)
	local ln = nameKey(part.Name)
	local nameScore = 0
	for key, sc in pairs(SHAFT_NAME_SCORE) do
		if ln:find(key, 1, true) then
			nameScore = math.max(nameScore, sc)
		end
	end
	local s = part.ExtentsSize
	local dims = { s.X, s.Y, s.Z }
	table.sort(dims)
	return nameScore * 10 + (dims[3] / math.max(dims[1], 0.01)) * dims[3] - s.X * s.Y * s.Z * 0.02
end

-- Long axis of a part's visible geometry, plus the two across it.
local function longestGeoAxis(part)
	local cf, s = part.ExtentsCFrame, part.ExtentsSize
	if s.X >= s.Y and s.X >= s.Z then
		return cf.RightVector, cf.UpVector, cf.LookVector
	elseif s.Y >= s.Z then
		return cf.UpVector, cf.RightVector, cf.LookVector
	end
	return cf.LookVector, cf.RightVector, cf.UpVector
end

-- AABB fraction sits in empty padding on generated single-mesh picks.
-- Walk the real silhouette and put the hand on the first solid shaft slice.
local function gripOnMesh(model, center, axis, lo, hi)
	local mesh, n = nil, 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			n += 1
			mesh = d
		end
	end
	if n ~= 1 or not mesh then
		return nil
	end
	local span = hi - lo
	if span < 0.05 then
		return nil
	end
	local probe = mesh:Clone()
	for _, c in ipairs(probe:GetChildren()) do
		c:Destroy()
	end
	probe.Anchored = true
	probe.CanCollide = false
	probe.CanTouch = false
	probe.CanQuery = true
	probe.Transparency = 1
	local lift = Vector3.new(0, 22000, 0) - mesh.Position
	probe.CFrame = mesh.CFrame + lift
	probe.Parent = workspace
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { probe }
	local perp = axis:Cross(Vector3.yAxis)
	if perp.Magnitude < 0.2 then
		perp = axis:Cross(Vector3.xAxis)
	end
	perp = perp.Unit
	local perp2 = axis:Cross(perp).Unit
	local function occupied(w)
		for k = 0, 5 do
			local a = k * math.pi / 6
			local dir = (perp * math.cos(a) + perp2 * math.sin(a))
			if workspace:Raycast(w + dir * 4, -dir * 8, params) then
				return true
			end
		end
		return false
	end
	local first, last
	for i = 0, 40 do
		local t = lo + span * (i / 40)
		if occupied(center + axis * t + lift) then
			first = first or t
			last = t
		end
	end
	probe:Destroy()
	if not first or not last then
		return nil
	end
	local sit = math.clamp(0.5, 0, math.max(0.2, (last - first) * 0.18))
	return center + axis * math.clamp(first + sit, lo, hi)
end

-- Pickaxes (and anything else on a haft). Returns the Handle CFrame, the Grip
-- and the handle's length.
local function poseHafted(model, o, family)
	local all = namedParts(model)
	local handleParts = groupParts(model, { "handle", "haft", "shaft" })
	local pool = #handleParts > 0 and handleParts or all
	local shaft, best = nil, -math.huge
	for _, p in ipairs(pool) do
		local sc = scoreShaftCandidate(p)
		if sc > best then
			shaft, best = p, sc
		end
	end
	if not shaft then
		return nil
	end
	local axis, perpA, perpB
	if o.axis then
		axis = o.axis
		perpA = snapAxis(Vector3.yAxis, axis)
		perpB = axis:Cross(perpA).Unit
	else
		axis, perpA, perpB = longestGeoAxis(shaft)
	end
	local center = shaft.ExtentsCFrame.Position
	local inHandle = {}
	for _, p in ipairs(handleParts) do
		inHandle[p] = true
	end
	local head = {}
	for _, p in ipairs(all) do
		if not inHandle[p] and p ~= shaft then
			head[#head + 1] = p
		end
	end
	local headSet = #head > 0 and head or all
	-- The head end is where the non-handle mass is. An explicit axis already
	-- says which end that is.
	local hc = geoCentroid(headSet)
	if o.flip or (o.flip == nil and not o.axis and hc and (hc - center):Dot(axis) < 0) then
		axis = -axis
	end
	local lo, hi = geoSpan(#handleParts > 0 and handleParts or { shaft }, center, axis)
	-- The blade plane comes from the head itself, not from vines or charms
	-- hanging off the haft. The heavier side of the head leads (-Y).
	local headOnly = groupParts(model, { "head", "blade" })
	local spreadSet = #headOnly > 0 and headOnly or headSet
	local a0, a1 = geoSpan(spreadSet, center, perpA)
	local b0, b1 = geoSpan(spreadSet, center, perpB)
	local yAxis = o.spread or (((a1 - a0) >= (b1 - b0)) and perpA or perpB)
	local sc = geoCentroid(spreadSet) or center
	if (sc - center):Dot(yAxis) > 0.05 then
		yAxis = -yAxis
	end
	local zAxis = axis:Cross(yAxis).Unit
	yAxis = zAxis:Cross(axis).Unit
	local along = o.gripAt or 0.16
	if along > 0.5 then
		along = 1 - along
	end
	along = math.clamp(along, 0.08, 0.32)
	local gripPoint = gripOnMesh(model, center, axis, lo, hi)
		or (center + axis * (lo + (hi - lo) * along))
	local lean = o.lean or HAFT_LEAN[family] or HAFT_LEAN.pickaxe
	local grip = (HAFT_UP * CFrame.Angles(0, 0, math.rad(lean))):Inverse()
	return CFrame.fromMatrix(gripPoint, axis, yAxis, zAxis), grip, hi - lo
end

-- Drills: bit forward, hand on the grip.
local function poseDrill(model, o)
	local all = namedParts(model)
	local c = geoCentroid(all)
	if not c then
		return nil
	end
	local bit = groupParts(model, { "drillbit", "augerbit", "bit", "drill" })
	local grip = groupParts(model, { "mainhandle", "handles", "tophandle", "handle", "grip", "haft" })
	local bc = #bit > 0 and geoCentroid(bit) or nil
	local gc = #grip > 0 and geoCentroid(grip) or c
	local fwd = o.forward or (bc and snapAxis(bc - gc)) or -Vector3.zAxis
	local up = o.up or snapAxis(Vector3.yAxis, fwd)
	return CFrame.lookAt(gc, gc + fwd, up), CFrame.identity, 0
end

-- Throwables: fuse or cap up, resting on the fist.
local function poseBomb(model, o)
	local all = namedParts(model)
	local c = geoCentroid(all)
	if not c then
		return nil
	end
	local top = groupParts(model, { "fuse", "cork", "cap", "toploop", "topdome", "flame" })
	local up = o.up or (#top > 0 and snapAxis(geoCentroid(top) - c)) or Vector3.yAxis
	local fwd = snapAxis(-Vector3.zAxis, up)
	local lo, hi = geoSpan(all, c, up)
	local rest = c + up * (lo + (hi - lo) * (o.gripAt or 0.3))
	return CFrame.lookAt(rest, rest + fwd, up), CFrame.identity, 0
end

--[[
	Single meshes (the generated tools: one textured MeshPart each) carry no
	named groups, so the pose is MEASURED, once per tool name per server or
	client: the silhouette is sampled by raycast, its principal axis is the
	tool's long direction (tools generated at a slant included), and the mass
	at each end says which end is which. A pick's head is its fat end; a
	drill's bit is its thin end. Bombs stay upright. A hand-set NAMED_POSE entry
	always wins.

	Checked against the seven single meshes posed by eye (Basaltiron, Coilpick,
	Violetbit, Pressurebit, Sootgear, Depthdrum, Nightorb): all agree.
]]
local WORLD_XYZ = { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis }
local measuredPose = {} -- [toolName] = pose table, or false when unmeasurable

local function singleMeshOf(model)
	local only
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			if only then
				return nil
			end
			only = d
		end
	end
	return only
end

local function measureSingleMesh(mesh)
	local probe = mesh:Clone()
	for _, c in ipairs(probe:GetChildren()) do
		c:Destroy()
	end
	probe.Anchored = true
	probe.CanCollide = false
	probe.CanTouch = false
	probe.CanQuery = true
	probe.Transparency = 1
	probe.CFrame = CFrame.new(0, 20000, 0) * (mesh.CFrame - mesh.CFrame.Position)
	probe.Parent = workspace
	local ok, result = pcall(function()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { probe }
		local cf, size = probe.ExtentsCFrame, probe.ExtentsSize
		local lo, hi
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local c = cf:PointToWorldSpace(Vector3.new(sx * size.X / 2, sy * size.Y / 2, sz * size.Z / 2))
					lo = lo and lo:Min(c) or c
					hi = hi and hi:Max(c) or c
				end
			end
		end
		local ext, center = hi - lo, (lo + hi) / 2
		local dims = { ext.X, ext.Y, ext.Z }
		local order = { 1, 2, 3 }
		table.sort(order, function(x, y)
			return dims[x] > dims[y]
		end)
		local A, B, C = WORLD_XYZ[order[1]], WORLD_XYZ[order[2]], WORLD_XYZ[order[3]]
		local LA, LB, LC = dims[order[1]], dims[order[2]], dims[order[3]]

		-- The tool's silhouette in the plane of its two long sides, each sample
		-- weighted by how thick the mesh is there.
		local G = 24
		local pts, sw, sa, sb = {}, 0, 0, 0
		for i = 1, G do
			for j = 1, G do
				local pa = -LA / 2 + (i - 0.5) * LA / G
				local pb = -LB / 2 + (j - 0.5) * LB / G
				local base = center + A * pa + B * pb
				local r1 = workspace:Raycast(base - C * (LC / 2 + 1), C * (LC + 2), params)
				local r2 = r1 and workspace:Raycast(base + C * (LC / 2 + 1), -C * (LC + 2), params)
				if r2 then
					local w = math.max(0.02, (r2.Position - r1.Position):Dot(C))
					pts[#pts + 1] = { pa, pb, w }
					sw += w
					sa += pa * w
					sb += pb * w
				end
			end
		end
		if sw <= 0 then
			return nil
		end

		-- Its long direction is the principal axis of that silhouette -- not the
		-- longest side of its box, which a wide head or a tool generated at a
		-- slant both get wrong.
		local ma, mb = sa / sw, sb / sw
		local caa, cbb, cab = 0, 0, 0
		for _, p in ipairs(pts) do
			local da, db = p[1] - ma, p[2] - mb
			caa += p[3] * da * da
			cbb += p[3] * db * db
			cab += p[3] * da * db
		end
		local theta = 0.5 * math.atan2(2 * cab, caa - cbb)
		local ua, ub = math.cos(theta), math.sin(theta)
		local lowT, highT = math.huge, -math.huge
		for _, p in ipairs(pts) do
			local t = p[1] * ua + p[2] * ub
			lowT, highT = math.min(lowT, t), math.max(highT, t)
		end
		-- Mass at each end, and where the heavy end's mass sits across the axis
		-- (which side an axe's blade is on).
		local cut = (highT - lowT) * 0.3
		local low, high, lowSide, highSide = 0, 0, 0, 0
		for _, p in ipairs(pts) do
			local t = p[1] * ua + p[2] * ub
			local across = -p[1] * ub + p[2] * ua
			if t < lowT + cut then
				low += p[3]
				lowSide += p[3] * across
			elseif t > highT - cut then
				high += p[3]
				highSide += p[3] * across
			end
		end
		local u = (A * ua + B * ub).Unit
		local v = (A * -ub + B * ua).Unit
		local heavySide = (high > low) and highSide or lowSide
		-- Within 25 degrees of a world axis, snap to it: a lopsided head should
		-- not tip the whole tool. (Picks generated at a slant sit at 30-42.)
		local best, bestDot = u, 0
		for _, w in ipairs(WORLD_XYZ) do
			local d = u:Dot(w)
			if math.abs(d) > bestDot then
				best, bestDot = (d >= 0) and w or -w, math.abs(d)
			end
		end
		if bestDot >= math.cos(math.rad(25)) then
			local vSign = (v:Dot(C:Cross(best)) >= 0) and 1 or -1
			u = best
			v = C:Cross(best).Unit * vSign
		end
		-- The heavy side of the head leads the swing: poseHafted wants it on -spread.
		local spread = (heavySide > 0) and -v or v
		-- Machines are L-shaped (body plus pistol grip), which tips their
		-- principal axis by as much as a slanted mesh; for them the box's long
		-- side is the better guess, so its end masses come back too.
		-- (Width across the box, slice by slice: the profile that got the
		-- machines right the first time round.)
		local boxLow, boxHigh = 0, 0
		local N, GB = 14, 8
		local kk = math.floor(N * 0.3)
		for i = 1, N do
			local ta = -LA / 2 + (i - 0.5) * LA / N
			local width = 0
			for j = 1, GB do
				local base = center + A * ta + C * (-LC / 2 + (j - 0.5) * LC / GB)
				local r1 = workspace:Raycast(base - B * (LB / 2 + 1), B * (LB + 2), params)
				local r2 = r1 and workspace:Raycast(base + B * (LB / 2 + 1), -B * (LB + 2), params)
				if r2 then
					width += math.max(0, (r2.Position - r1.Position):Dot(B))
				end
			end
			if i <= kk then
				boxLow += width
			elseif i > N - kk then
				boxHigh += width
			end
		end
		-- Sit the hand on the thin shaft, not in empty bbox space beside a T-head.
		local bins = 20
		local occ = table.create(bins, 0)
		local spanT = math.max(1e-4, highT - lowT)
		for _, p in ipairs(pts) do
			local t = p[1] * ua + p[2] * ub
			local u01 = (t - lowT) / spanT
			local b = math.clamp(math.floor(u01 * bins) + 1, 1, bins)
			occ[b] += p[3]
		end
		local maxOcc = 0
		for i = 1, bins do
			maxOcc = math.max(maxOcc, occ[i])
		end
		local thresh = maxOcc * 0.12
		local lightIsLow = low <= high
		local start, dir = 1, 1
		if not lightIsLow then
			start, dir = bins, -1
		end
		local gripBin = start
		for i = start, lightIsLow and bins or 1, dir do
			if occ[i] >= thresh then
				gripBin = i
				break
			end
		end
		gripBin = math.clamp(gripBin + dir * 2, 1, bins)
		local gripFromLow = (gripBin - 0.5) / bins
		local gripAt = lightIsLow and gripFromLow or (1 - gripFromLow)
		return { axis = u, spread = spread, low = low, high = high, boxAxis = A, boxLow = boxLow, boxHigh = boxHigh, gripAt = gripAt }
	end)
	probe:Destroy()
	return ok and result or nil
end

-- The pose a single mesh measures to, or nil to fall back to the defaults.
local function measuredPoseFor(toolName, model, family)
	if family == "explosive" then
		return nil
	end
	local key = toolName .. "|" .. family
	if measuredPose[key] ~= nil then
		return measuredPose[key] or nil
	end
	local mesh = singleMeshOf(model)
	local m = mesh and measureSingleMesh(mesh)
	local pose = false
	if m then
		local heavyPlus = m.high > m.low
		local sure = math.max(m.high, m.low) >= 1.25 * math.max(0.01, math.min(m.high, m.low))
		if family == "drill" then
			local boxHeavyPlus = m.boxHigh > m.boxLow
			local boxSure = math.max(m.boxHigh, m.boxLow) >= 1.25 * math.max(0.01, math.min(m.boxHigh, m.boxLow))
			if boxSure then
				pose = { forward = boxHeavyPlus and -m.boxAxis or m.boxAxis }
			elseif m.boxAxis == Vector3.zAxis then
				-- Too even to call: the generator authors machines facing -Z.
				pose = { forward = -Vector3.zAxis }
			end
		else
			--[[
				WHICH END IS THE HEAD decides which end the HAND goes on:
				poseHafted seats the grip 16% along from the far end of `axis`,
				so getting this backwards hands the player the tool by its
				blade -- the gun by the barrel.

				Both fallbacks here used to throw the mass reading away:

				  * the vertical one forced +Y whatever the mass said, so any
				    tool modelled head-DOWN came out held by the head;
				  * and when the margin was thin and the axis was not vertical
				    it returned NO pose at all -- which is worse, because
				    poseHafted cannot work it out for a single mesh. Its "head"
				    set is every part that is not the shaft, and on a one-mesh
				    tool that set is empty, so it falls back to the whole mesh
				    and its flip test compares the centroid against itself.
				    Never fires. The axis sign then falls out of however the
				    part happened to be authored: a coin toss, on roughly 170 of
				    the 273 models.

				A thin margin is still a reading, and a reading beats a toss.
				Orient by the heavy end either way.
			]]
			local dir = heavyPlus and m.axis or -m.axis
			if not sure and math.abs(m.axis:Dot(Vector3.yAxis)) > 0.99 then
				dir = heavyPlus and Vector3.yAxis or -Vector3.yAxis
			end
			pose = { axis = dir, spread = m.spread, gripAt = m.gripAt }
		end
	end
	measuredPose[key] = pose
	return pose or nil
end

local function guessFamily(toolName)
	local known = NAMED_FAMILY[tostring(toolName or "")]
	if known then
		return known
	end
	local n = string.lower(tostring(toolName or ""))
	if n:find("bore", 1, true) or n:find("uger", 1, true) or n:find("drill", 1, true) then
		return "drill"
	end
	if n:find("bomb", 1, true) or n:find("mine", 1, true) or n:find("fuse", 1, true)
		or n:find("sack", 1, true) or n:find("orb", 1, true) or n:find("drum", 1, true) then
		return "explosive"
	end
	return "pickaxe"
end

local function fitNamedModel(model, family, pose)
	local ok, bb = pcall(function()
		local _, size = model:GetBoundingBox()
		return size
	end)
	if not ok or not bb then
		return 1
	end
	local largest = math.max(bb.X, bb.Y, bb.Z)
	if largest < 0.05 then
		return 1
	end
	local k = math.clamp((pose.size or NAMED_FIT[family] or NAMED_FIT.default) / largest, 0.05, 20)
	if math.abs(k - 1) > 0.02 then
		-- ScaleTo is absolute; multiply by the current scale or a model saved
		-- at a non-1 scale fits to the wrong size.
		pcall(function()
			model:ScaleTo(model:GetScale() * k)
		end)
	end
	return k
end

-- A named mesh, posed for the hand. Returns the Model, its Handle and the Grip.

-- Section chest tools are "Loam Briarpick" / "Loam Briardrill". Meshes live under
-- the band flagship folder (Briarpick, Sodauger, Flintpike, …).
local SECTION_MESH_ALIAS = {
	Briardrill = "Sodauger",
	Quartzpick = "Flintpike",
	Quartzdrill = "Chiselbore",
	Mistpick = "Foamspike",
	Mistdrill = "Pearlbit",
	Brasspick = "Wirepike",
	Brassdrill = "Coilbit",
	Crimsonpick = "Emberpike",
	Crimsondrill = "Scarbit",
	Eclipsepick = "Shadepike",
	Eclipsedrill = "Umbabit",
	Riftpick = "Tearpike",
	Riftdrill = "Faultbit",
	Starpick = "Dustpike",
	Stardrill = "Orbitbit",
	Mythpick = "Shardpike",
	Mythdrill = "Latticebit",
	Primepick = "Fossilpike",
	Primedrill = "Seedbit",
}

function ToolModelFactory.resolveMeshName(toolName, root)
	toolName = tostring(toolName or "")
	if toolName == "" then
		return nil
	end
	root = root or ToolModelFactory.toolModelsRoot()
	if not root then
		return nil
	end
	local function hit(n)
		if type(n) == "string" and n ~= "" and root:FindFirstChild(n) then
			return n
		end
		return nil
	end
	local found = hit(toolName)
	if found then
		return found
	end
	local last = string.match(toolName, "([^%s]+)$")
	found = hit(last) or hit(SECTION_MESH_ALIAS[last or ""]) or hit(SECTION_MESH_ALIAS[toolName])
	if found then
		return found
	end
	local rest = string.match(toolName, "^%S+%s+(.+)$")
	found = hit(rest)
	if found then
		return found
	end
	return hit((string.gsub(toolName, "%s+", "")))
end

function ToolModelFactory.fromNamed(toolName, finish, familyHint)
	toolName = tostring(toolName or "")
	finish = tostring(finish or "Normal")
	if toolName == "" then
		return nil
	end
	local root = ToolModelFactory.toolModelsRoot()
	if not root then
		return nil
	end
	local folderName = ToolModelFactory.resolveMeshName(toolName, root)
	local folder = folderName and root:FindFirstChild(folderName)
	if not folder then
		return nil
	end
	local srcModel = folder:FindFirstChild(finish) or folder:FindFirstChild("Normal")
	if not srcModel then
		return nil
	end

	-- The Shiny and Shadow variants are stored already fitted, posed and
	-- finished (see bakeFinishVariants): hand them over as they are.
	if srcModel:GetAttribute("Posed") then
		local baked = srcModel:Clone()
		baked.Name = toolName
		local bakedHandle = baked.PrimaryPart or baked:FindFirstChild("Handle")
		if not bakedHandle then
			baked:Destroy()
			return nil
		end
		for _, d in ipairs(baked:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = false
				d.CanCollide = false
				d.Massless = true
			end
		end
		return baked, bakedHandle, srcModel:GetAttribute("Grip") or GRIPS.pickaxe
	end

	local model = srcModel:Clone()
	model.Name = toolName
	-- Generated tools arrive as packages, and a PackageLink can never be
	-- reparented. The server hands a tool over by moving every child of this
	-- model into a Tool, so a link here throws and the player gets no tool at
	-- all. Rehome the parts in a plain model and let the copy (link and all)
	-- go.
	if model:FindFirstChildOfClass("PackageLink") then
		local plain = Instance.new("Model")
		plain.Name = toolName
		for _, c in ipairs(model:GetChildren()) do
			if not c:IsA("PackageLink") then
				c.Parent = plain
			end
		end
		plain.WorldPivot = model.WorldPivot
		model:Destroy()
		model = plain
	end

	do
		local wrap = model:FindFirstChild("world")
		if wrap then
			for _, d in ipairs(wrap:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Parent = model
				end
			end
			wrap:Destroy()
		end
		pcall(function()
			model:PivotTo(CFrame.new())
		end)
	end

	local family = familyHint or guessFamily(folderName or toolName)
	if family ~= "drill" and family ~= "explosive" then
		family = "pickaxe"
	end
	local pose = NAMED_POSE[folderName] or NAMED_POSE[toolName] or measuredPoseFor(folderName or toolName, model, family) or {}
	fitNamedModel(model, family, pose)

	-- Pose first: it reads the authored groups (Handle, Head, Bit...).
	local poser = (family == "drill" and poseDrill) or (family == "explosive" and poseBomb) or poseHafted
	local okPose, cf, grip, len = pcall(poser, model, pose, family)
	if not okPose or not cf then
		model:Destroy()
		return nil
	end

	-- A Tool finds its grip by the name "Handle", so nothing else may carry it:
	-- flatten a Handle group and rename any part already called Handle.
	local group = model:FindFirstChild("Handle")
	if group and not group:IsA("BasePart") then
		for _, c in ipairs(group:GetChildren()) do
			if not c:IsA("PackageLink") then
				c.Parent = model
			end
		end
		group:Destroy()
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Handle" then
			d.Name = "Shaft"
		end
	end

	-- The invisible Handle is the grip itself. Its long axis is the one the shop
	-- plinth stands upright and the finish trails run along: the haft for a
	-- pick, "up" for a drill or bomb.
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	if family == "pickaxe" then
		handle.Size = Vector3.new(math.clamp((len or 1) * 0.22, 0.55, 1.05), 0.22, 0.22)
	else
		handle.Size = Vector3.new(0.3, 0.9, 0.3)
	end
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.CastShadow = false
	handle.CFrame = cf
	handle.Parent = model
	model.PrimaryPart = handle

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
		end
	end
	weldAll(model, handle)

	model:SetAttribute("NamedFamily", family)
	return model, handle, grip
end

function ToolModelFactory.toolModelsRoot()
	local rs = game:GetService("ReplicatedStorage")
	local ss = game:GetService("ServerStorage")
	return rs:FindFirstChild("ToolModels_50")
		or ss:FindFirstChild("ToolModels_50")
		or workspace:FindFirstChild("ToolModels_50")
end

--[[
	Build a tool model. `tier` is 1-based; `count` is how many rungs the family
	has, which is what turns a tier into a position on the ramp.

	Returns the Model, its Handle, and the Grip that holds it correctly.
]]
local KIT_BODY_NAMES = { "FieldScrap", "TapedField", "Riveted", "MilSpec", "Alloy", "Composite" }
-- Escalate silhouette across the ladder, then body rarity within that shape.
local KIT_SHAPES = {
	pickaxe = { "Swing", { "Pickaxe", "Chisel", "IcePick", "Sledge", "Sledgehammer", "TrenchShovel" } },
	drill = { "Drill", { "Drill", "Auger", "BitArrayCutter", "Bore", "Frack" } },
	explosive = { "Explosive", { "Grenade", "Quickcharge", "Breacher", "Precision", "Proximity", "Cluster" } },
}

local function tryToolKitMesh(family, tier, count)
	local root = game:GetService("ReplicatedStorage"):FindFirstChild("ToolKitMeshes")
	if not root then return nil end
	local entry = KIT_SHAPES[family]
	if not entry then return nil end
	local famName, shapes = entry[1], entry[2]
	local famFolder = root:FindFirstChild(famName)
	if not famFolder then return nil end
	count = math.max(2, count or 15)
	tier = math.clamp(tier or 1, 1, count)
	local t = (tier - 1) / (count - 1)
	local si = math.clamp(math.floor(t * (#shapes - 1) + 1e-9) + 1, 1, #shapes)
	-- body rarity advances inside each shape band
	local band = 1 / #shapes
	local localT = math.clamp((t - (si - 1) * band) / band, 0, 1)
	local bi = math.clamp(math.floor(localT * (#KIT_BODY_NAMES - 1) + 0.5) + 1, 1, #KIT_BODY_NAMES)
	local toolFolder = famFolder:FindFirstChild(shapes[si])
	if not toolFolder then return nil end
	local body = toolFolder:FindFirstChild(KIT_BODY_NAMES[bi]) or toolFolder:FindFirstChild("FieldScrap")
	if not (body and body:IsA("MeshPart")) then return nil end
	local model = Instance.new("Model")
	model.Name = string.format("%s_%d", family, tier)
	local handle = body:Clone()
	handle.Name = "Handle"
	handle.Anchored = false
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	local k = (SCALE and SCALE[family]) or 1
	if k ~= 1 then
		handle.Size = handle.Size * k
	end
	handle.Parent = model
	model.PrimaryPart = handle
	model:SetAttribute("KitMesh", famName .. "/" .. shapes[si] .. "/" .. (body.Name))
	model:SetAttribute("KitShape", shapes[si])
	model:SetAttribute("KitBody", body.Name)
	return model, handle, GRIPS[family] or GRIPS.pickaxe
end

function ToolModelFactory.build(family, tier, count)
	family = BUILDERS[family] and family or "pickaxe"
	count = math.max(2, count or 15)
	do
		local km, kh, kg = tryToolKitMesh(family, tier, count)
		if kh then return km, kh, kg end
	end
	local t = (math.clamp(tier or 1, 1, count) - 1) / (count - 1)

	local model = Instance.new("Model")
	model.Name = string.format("%s_%d", family, tier or 1)
	local handle = BUILDERS[family](t, model)
	handle.Name = "Handle"

	-- Scale before welding, or the welds freeze the unscaled offsets.
	local k = SCALE[family] or 1
	if k ~= 1 then
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Size = p.Size * k
				p.CFrame = CFrame.new(p.CFrame.Position * k) * (p.CFrame - p.CFrame.Position)
			end
		end
	end

	model.PrimaryPart = handle
	weldAll(model, handle)
	return model, handle, GRIPS[family] or GRIPS.pickaxe
end

function ToolModelFactory.buildLunar(variant)
	variant = tostring(variant or "lunar_pick")
	local alias = ({
		lunar_pick = "LunarPickaxe",
		lunar_eclipse = "LunarEclipse",
		bp_eclipse = "Eclipse",
	})[variant]
	if alias and ToolModelFactory.fromNamed then
		local model, handle, grip = ToolModelFactory.fromNamed(alias, "Normal")
		if handle then
			return model, handle, grip or GRIPS.pickaxe
		end
	end
	local model = Instance.new("Model")
	model.Name = variant
	local handle = buildLunarPickaxe(variant, model)
	handle.Name = "Handle"
	model.PrimaryPart = handle
	weldAll(model, handle)
	return model, handle, GRIPS.pickaxe
end

function ToolModelFactory.gripFor(family)
	return GRIPS[family] or GRIPS.pickaxe
end

--------------------------------------------------------------------------------
-- BACKPACKS
--------------------------------------------------------------------------------

local BAG_CLOTH = {
	C3(132, 100, 64), C3(150, 118, 72), C3(96, 116, 92), C3(82, 110, 136),
	C3(96, 96, 146), C3(124, 92, 162), C3(164, 136, 76),
}

ToolModelFactory.BAG_ZONE_TINT = {
	meadow = Color3.fromRGB(118, 148, 72),
	sunscar = Color3.fromRGB(150, 146, 138),
	mistreef = Color3.fromRGB(56, 138, 128),
	arcwork = Color3.fromRGB(196, 138, 64),
	bloodmoon = Color3.fromRGB(168, 48, 52),
	eclipse = Color3.fromRGB(92, 64, 148),
	riftmarch = Color3.fromRGB(196, 108, 48),
	starfall = Color3.fromRGB(72, 96, 168),
	mythral = Color3.fromRGB(88, 196, 196),
	primordium = Color3.fromRGB(196, 72, 36),
	bigbang = Color3.fromRGB(48, 32, 88),
}

function ToolModelFactory._cloneBagMesh(row, tier, count)
	local mine = game:GetService("ReplicatedStorage"):FindFirstChild("Mine")
	local folder = mine and mine:FindFirstChild("BagModels")
	if not folder then
		return nil
	end
	if not row then
		pcall(function()
			local Bags = require(mine.Shared:WaitForChild("MineBags"))
			row = Bags.byTier(tier)
		end)
	end
	local skin = (row and row.skin) or ""
	-- Only the two limited bags keep a 10k mesh. Ladder satchels stay procedural.
	if skin ~= "founders" and skin ~= "wormhole" then
		return nil
	end
	local tmpl = folder:FindFirstChild(skin)
	if not tmpl then
		return nil
	end
	local model = tmpl:Clone()
	model.Name = "backpack_" .. tostring(tier or 1)
	local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not primary then
		model:Destroy()
		return nil
	end
	model.PrimaryPart = primary
	local _, sz = model:GetBoundingBox()
	local k = math.min(
		1.7 / math.max(sz.X, 0.05),
		2.05 / math.max(sz.Y, 0.05),
		1.15 / math.max(sz.Z, 0.05),
		1
	)
	if math.abs(k - 1) > 0.02 then
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Size = p.Size * k
				if p ~= primary then
					local rel = primary.CFrame:ToObjectSpace(p.CFrame)
					p.CFrame = primary.CFrame * CFrame.new(rel.Position * k) * (rel - rel.Position)
				end
			end
		end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = false
			if p:IsA("MeshPart") then
				p.CollisionFidelity = Enum.CollisionFidelity.Box
			end
		end
	end
	weldAll(model, primary)
	return model
end

--[[
	Build a backpack model. Escalates the way the tools do: a soft satchel at the
	bottom, a framed rig with lit canisters at the top. HQ meshes in BagModels
	win when present; this procedural build is the fallback.
]]
function ToolModelFactory.backpack(tier, count, row)
	count = math.max(2, count or 6)
	local hq = ToolModelFactory._cloneBagMesh(row, tier, count)
	if hq then
		return hq, hq.PrimaryPart
	end
	local t = (math.clamp(tier or 1, 1, count) - 1) / (count - 1)
	local cloth = ramp(BAG_CLOTH, t)
	do
		local zone = row and tostring(row.zoneId or "")
		local tint = zone ~= "" and ToolModelFactory.BAG_ZONE_TINT[zone]
		if tint then
			cloth = cloth:Lerp(tint, 0.5)
		end
	end
	local trim = cloth:Lerp(C3(56, 46, 38), 0.34)
	local lit = ramp(CELL, t)
	local hard = t >= 0.5

	local model = Instance.new("Model")
	model.Name = "backpack_" .. tostring(tier or 1)

	-- Taller than it is wide, with a domed top: a rucksack, not a footlocker.
	-- Everything faces +Z; the model is turned round when it is worn, so +Z is
	-- what an onlooker behind the player sees.
	-- Clearly taller than it is wide, or it reads as a footlocker -- but sized
	-- against an R15 UpperTorso (about 2 wide by 1.6 tall), not against the
	-- empty air of a review rack. At 2.9 studs tall it swallowed the character.
	local w = 1.45 + t * 0.35
	local h = 1.9 + t * 0.5
	local d = 0.62 + t * 0.22

	local body = box({
		Name = "Handle", Size = Vector3.new(w, h * 0.78, d), CFrame = CFrame.new(0, -h * 0.11, 0),
		Color = cloth, Material = hard and Enum.Material.Metal or Enum.Material.Fabric,
	}, model)
	-- Round off the sides and the top so the silhouette is a bag.
	for _, s in ipairs({ -1, 1 }) do
		cyl({
			Name = "Side", Length = h * 0.78, Dia = d,
			CFrame = CFrame.new(s * w * 0.5, -h * 0.11, 0),
			Color = cloth, Material = body.Material,
		}, model)
	end
	cyl({
		Name = "Dome", Length = w, Dia = d,
		CFrame = CFrame.new(0, h * 0.28, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = cloth, Material = body.Material,
	}, model)
	for _, s in ipairs({ -1, 1 }) do
		ball({
			Name = "Corner", Dia = d,
			CFrame = CFrame.new(s * w * 0.5, h * 0.28, 0),
			Color = cloth, Material = body.Material,
		}, model)
	end

	-- Storm flap: it caps the top of the bag and overhangs the front, which is
	-- what makes a rucksack read as a rucksack. Floating it mid-face -- the
	-- obvious placement -- just looks like a mail slot.
	box({
		Name = "Flap", Size = Vector3.new(w * 1.03, h * 0.24, d * 0.34),
		CFrame = CFrame.new(0, h * 0.19, d * 0.52) * CFrame.Angles(math.rad(7), 0, 0),
		Color = trim, Material = body.Material,
	}, model)
	cyl({
		Name = "FlapTop", Length = w * 1.03, Dia = d * 1.04,
		CFrame = CFrame.new(0, h * 0.28, 0.02) * CFrame.Angles(0, 0, math.rad(90)),
		Color = trim, Material = body.Material,
	}, model)
	cyl({
		Name = "FlapHem", Length = w * 1.03, Dia = d * 0.4,
		CFrame = CFrame.new(0, h * 0.05, d * 0.56) * CFrame.Angles(0, 0, math.rad(90)),
		Color = trim:Lerp(DARK, 0.2), Material = body.Material,
	}, model)

	-- Two compression straps down the front, each with a metal buckle.
	for _, s in ipairs({ -1, 1 }) do
		box({
			Name = "Strap", Size = Vector3.new(0.22, h * 0.42, 0.08),
			CFrame = CFrame.new(s * w * 0.26, h * 0.06, d * 0.72),
			Color = C3(72, 56, 42), Material = Enum.Material.Fabric,
		}, model)
		box({
			Name = "Buckle", Size = Vector3.new(0.3, 0.2, 0.13),
			CFrame = CFrame.new(s * w * 0.26, -h * 0.09, d * 0.74),
			Color = C3(224, 200, 148), Material = Enum.Material.Metal, Reflectance = 0.3,
		}, model)
	end

	-- Front pocket at the bottom of the bag.
	box({
		Name = "Pocket", Size = Vector3.new(w * 0.66, h * 0.24, 0.26),
		CFrame = CFrame.new(0, -h * 0.3, d * 0.52), Color = cloth:Lerp(C3(255, 255, 255), 0.12),
		Material = body.Material,
	}, model)
	cyl({
		Name = "PocketHem", Length = w * 0.66, Dia = 0.26,
		CFrame = CFrame.new(0, -h * 0.21, d * 0.52) * CFrame.Angles(0, 0, math.rad(90)),
		Color = trim, Material = body.Material,
	}, model)

	-- Shoulder straps, on the face that ends up against the player's back.
	for _, s in ipairs({ -1, 1 }) do
		box({
			Name = "Shoulder", Size = Vector3.new(0.32, h * 0.95, 0.18),
			CFrame = CFrame.new(s * w * 0.28, 0, -d * 0.56) * CFrame.Angles(0, s * math.rad(7), 0),
			Color = trim, Material = Enum.Material.Fabric,
		}, model)
	end
	-- Carry loop: every bag has one, and it breaks up the flat top.
	cyl({
		Name = "Loop", Length = 0.5, Dia = 0.12,
		CFrame = CFrame.new(0, h * 0.44, -d * 0.2) * CFrame.Angles(0, 0, math.rad(90)),
		Color = trim:Lerp(DARK, 0.2), Material = Enum.Material.Fabric,
	}, model)
	for _, s in ipairs({ -1, 1 }) do
		box({
			Name = "LoopLeg", Size = Vector3.new(0.12, 0.3, 0.12),
			CFrame = CFrame.new(s * 0.22, h * 0.34, -d * 0.2), Color = trim:Lerp(DARK, 0.2),
			Material = Enum.Material.Fabric,
		}, model)
	end

	if t > 0.2 then
		for _, s in ipairs({ -1, 1 }) do
			box({
				Name = "Pouch", Size = Vector3.new(0.4, h * 0.28, d * 0.7),
				CFrame = CFrame.new(s * (w * 0.5 + 0.18), -h * 0.24, 0.05),
				Color = trim, Material = body.Material,
			}, model)
			cyl({
				Name = "PouchLid", Length = 0.44, Dia = d * 0.7,
				CFrame = CFrame.new(s * (w * 0.5 + 0.18), -h * 0.24 + h * 0.14, 0.05)
					* CFrame.Angles(0, 0, math.rad(90)),
				Color = cloth:Lerp(C3(255, 255, 255), 0.12), Material = body.Material,
			}, model)
		end
	end
	if t > 0.45 then
		-- Rigid frame: uprights and a crossbar behind the bag.
		for _, s in ipairs({ -1, 1 }) do
			cyl({
				Name = "Frame", Length = h * 0.96, Dia = 0.15,
				CFrame = CFrame.new(s * (w * 0.5 + 0.06), -h * 0.05, 0),
				Color = C3(154, 158, 166), Material = Enum.Material.Metal, Reflectance = 0.25,
			}, model)
		end
		cyl({
			Name = "Crossbar", Length = w + 0.18, Dia = 0.15,
			CFrame = CFrame.new(0, h * 0.38, -d * 0.28) * CFrame.Angles(0, 0, math.rad(90)),
			Color = C3(154, 158, 166), Material = Enum.Material.Metal, Reflectance = 0.25,
		}, model)
	end
	if t > 0.7 then
		for _, s in ipairs({ -1, 1 }) do
			cyl({
				Name = "Canister", Length = h * 0.4, Dia = 0.38,
				CFrame = CFrame.new(s * (w * 0.5 + 0.28), h * 0.02, 0.06),
				Color = lit, Material = Enum.Material.Neon,
			}, model)
			cyl({
				Name = "CanCap", Length = 0.13, Dia = 0.45,
				CFrame = CFrame.new(s * (w * 0.5 + 0.28), h * 0.02 + h * 0.22, 0.06),
				Color = C3(154, 158, 166), Material = Enum.Material.Metal,
			}, model)
		end
	end
	if t > 0.9 then
		box({
			Name = "Sigil", Size = Vector3.new(0.42, 0.42, 0.07),
			CFrame = CFrame.new(0, -h * 0.3, d * 0.66) * CFrame.Angles(0, 0, math.rad(45)),
			Color = lit, Material = Enum.Material.Neon,
		}, model)
	end

	model.PrimaryPart = body
	weldAll(model, body)
	return model, body
end

--[[
	Finish / variant paint for equipped tools and showcase clones.

	3D rules (card language, different surfaces):
	  Normal / Golden / Prism / Rainbow  — original mesh skin. Golden/Prism/Rainbow
	    read on the *card* outline only (see CARD_OUTLINE / applyCardOutline).
	  Shiny   — original skin + white/gold sparkles + soft PointLight glow.
	  Shadow  — demonic reskin: #000 body, #6E0814 neon accents, #C41E3A glow
	            + ember particles + red Trail. Some tools get demonic eyes.

	Shiny and Shadow are mutually exclusive finishes.
]]
local FINISH = {
	Normal = true, Shiny = true, Shadow = true, Nightmare = true,
	Golden = true, Prism = true, Rainbow = true,
}

local SHADOW_BODY = Color3.fromRGB(0, 0, 0)
local SHADOW_NEON = Color3.fromRGB(0x6E, 0x08, 0x14) -- #6E0814
local SHADOW_GLOW = Color3.fromRGB(0xC4, 0x1E, 0x3A) -- #C41E3A
local NIGHTMARE_BODY = Color3.fromRGB(18, 0, 2)
local NIGHTMARE_NEON = Color3.fromRGB(220, 8, 28)

-- UI-only outline colours for Golden / Prism / Rainbow tool (and TCG) cards.
ToolModelFactory.CARD_OUTLINE = {
	Golden = Color3.fromRGB(255, 196, 64),
	Prism = Color3.fromRGB(140, 210, 255),
	Rainbow = Color3.fromRGB(255, 110, 200),
}

function ToolModelFactory.cardOutlineColor(finish)
	return ToolModelFactory.CARD_OUTLINE[tostring(finish or "")]
end

function ToolModelFactory.applyCardOutline(guiObject, finish)
	if not guiObject then return nil end
	local col = ToolModelFactory.cardOutlineColor(finish)
	local old = guiObject:FindFirstChild("FinishOutline")
	if old then old:Destroy() end
	if not col then return nil end
	local stroke = Instance.new("UIStroke")
	stroke.Name = "FinishOutline"
	stroke.Thickness = 2.5
	stroke.Color = col
	stroke.Transparency = 0.05
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = guiObject
	if finish == "Rainbow" then
		local g = Instance.new("UIGradient")
		g.Rotation = 35
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 255)),
		})
		g.Parent = stroke
	end
	return stroke
end

local function clearFinishDecor(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Texture") and (d.Name == "RainbowFlow" or d:GetAttribute("RainbowFlow")) then
			d:Destroy()
		elseif d.Name == "FinishFx" or d.Name == "DemonicEye" or d.Name == "ShinyGlint"
			or d.Name == "ShadowTrail" or d.Name == "ShadowTrailFx"
			or d.Name == "ShadowTrailA0" or d.Name == "ShadowTrailA1"
			or d.Name == "ShinyTrail" or d.Name == "ShinyTrailA0" or d.Name == "ShinyTrailA1" then
			d:Destroy()
		elseif d:IsA("PointLight") and d.Name == "FinishGlow" then
			d:Destroy()
		elseif d.Name == "FinishAura" or d.Name == "FinishRim" then
			d:Destroy()
		elseif d:IsA("Trail") and (d.Name == "ShadowTrail" or d.Name == "ShinyTrail") then
			d:Destroy()
		end
	end
	if root:IsA("Model") or root:IsA("Tool") then
		root:SetAttribute("RainbowFlow", nil)
	end
end

-- Kept for callers that still clear old rainbow overlays.
function ToolModelFactory.clearRainbowOverlay(root)
	clearFinishDecor(root)
end

local function paintShadowPart(d)
	if not d:IsA("BasePart") then return end
	local n = string.lower(d.Name)
	local vol = d.Size.X * d.Size.Y * d.Size.Z
	local detail = vol < 0.4
		or n:find("wrap", 1, true) or n:find("tip", 1, true) or n:find("edge", 1, true)
		or n:find("bit", 1, true) or n:find("rivet", 1, true) or n:find("band", 1, true)
		or n:find("fuse", 1, true) or n:find("camo", 1, true) or n:find("spot", 1, true)
		or n:find("collar", 1, true) or n:find("ring", 1, true) or n:find("inlay", 1, true)
		or n:find("corona", 1, true) or n:find("accent", 1, true) or n:find("eye", 1, true)
	if detail then
		d.Color = SHADOW_NEON
		d.Material = Enum.Material.Neon
		d.Reflectance = 0.02
	else
		d.Color = SHADOW_BODY
		d.Material = Enum.Material.Metal
		d.Reflectance = 0.08
	end
end

local function ensureShadowAccents(root)
	local parts, reds = {}, 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			local vol = d.Size.X * d.Size.Y * d.Size.Z
			table.insert(parts, { d = d, vol = vol })
			if d.Material == Enum.Material.Neon then
				reds += 1
			end
		end
	end
	if reds == 0 and #parts > 1 then
		table.sort(parts, function(a, b) return a.vol < b.vol end)
		local n = math.clamp(math.max(1, math.floor(#parts * 0.25)), 1, 4)
		local biggest = parts[#parts].d
		for i = 1, n do
			local p = parts[i] and parts[i].d
			if p and p ~= biggest then
				p.Color = SHADOW_NEON
				p.Material = Enum.Material.Neon
				p.Reflectance = 0.02
			end
		end
	end
end

local function attachGlow(handle, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Name = "FinishGlow"
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = handle
	return light
end

local function attachRibbonTrail(handle, opts)
	opts = opts or {}
	local prefix = opts.Prefix or "Trail"
	for _, suffix in ipairs({ "", "Fx", "A0", "A1" }) do
		local old = handle:FindFirstChild(prefix .. suffix)
		if old then old:Destroy() end
	end

	local sz = handle.Size
	local axis = math.max(sz.X, sz.Y, sz.Z)
	local half = math.clamp(axis * 0.35, 0.25, 1.1)
	local offset0, offset1
	if sz.Y >= sz.X and sz.Y >= sz.Z then
		offset0 = Vector3.new(0, half, 0)
		offset1 = Vector3.new(0, -half, 0)
	elseif sz.X >= sz.Z then
		offset0 = Vector3.new(half, 0, 0)
		offset1 = Vector3.new(-half, 0, 0)
	else
		offset0 = Vector3.new(0, 0, half)
		offset1 = Vector3.new(0, 0, -half)
	end

	local att0 = Instance.new("Attachment")
	att0.Name = prefix .. "A0"
	att0.Position = offset0
	att0.Parent = handle
	local att1 = Instance.new("Attachment")
	att1.Name = prefix .. "A1"
	att1.Position = offset1
	att1.Parent = handle

	local trail = Instance.new("Trail")
	trail.Name = prefix
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = opts.Color or ColorSequence.new(Color3.new(1, 1, 1))
	trail.Transparency = opts.Transparency or NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.55, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = opts.Lifetime or 2.75
	trail.MinLength = 0.08
	trail.MaxLength = opts.MaxLength or 30
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	trail.LightEmission = opts.LightEmission or 0.85
	trail.LightInfluence = 0
	trail.FaceCamera = true
	trail.Parent = handle
	return trail
end

local function attachShinyFx(handle)
	local old = handle:FindFirstChild("FinishFx")
	if old then old:Destroy() end
	local att = Instance.new("Attachment")
	att.Name = "FinishFx"
	att.Parent = handle
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Rate = 22
	sparks.Lifetime = NumberRange.new(0.45, 1.0)
	sparks.Speed = NumberRange.new(0.4, 1.8)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.14),
		NumberSequenceKeypoint.new(0.55, 0.07),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.LightEmission = 0.85
	sparks.LightInfluence = 0
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 230, 160))
	sparks.Parent = att
	attachGlow(handle, Color3.fromRGB(255, 240, 200), 0.55, 6)
	-- Same long ribbon idea as Shadow — white / soft gold wake.
	attachRibbonTrail(handle, {
		Prefix = "ShinyTrail",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 230, 170)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 210, 255)),
		}),
		Lifetime = 2.75,
		MaxLength = 30,
		LightEmission = 0.95,
	})
end

local function attachShadowTrail(handle)
	attachRibbonTrail(handle, {
		Prefix = "ShadowTrail",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, SHADOW_GLOW),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(140, 10, 28)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 0, 6)),
		}),
		Lifetime = 2.75,
		MaxLength = 30,
		LightEmission = 0.85,
	})
end

local function attachShadowFx(handle, root)
	local old = handle:FindFirstChild("FinishFx")
	if old then old:Destroy() end
	local att = Instance.new("Attachment")
	att.Name = "FinishFx"
	att.Parent = handle

	-- Local body embers (on top of the world-space trail wake).
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "ShadowBodyEmbers"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Rate = 36
	sparks.Lifetime = NumberRange.new(0.4, 0.9)
	sparks.Speed = NumberRange.new(0.6, 2.2)
	sparks.SpreadAngle = Vector2.new(80, 80)
	sparks.Acceleration = Vector3.new(0, 1.2, 0)
	sparks.Drag = 2
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.14),
		NumberSequenceKeypoint.new(0.55, 0.08),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.LightEmission = 0.9
	sparks.LightInfluence = 0
	sparks.Color = ColorSequence.new(SHADOW_GLOW, Color3.fromRGB(90, 0, 8))
	sparks.Parent = att

	attachGlow(handle, SHADOW_GLOW, 0.85, 8)
	attachShadowTrail(handle)

	-- Demonic eyes on ~half of tools (stable hash of tool id, not finish name).
	local name = (root and root.Parent and root.Parent.Name)
		or (root and root:GetAttribute("ToolId"))
		or (root and root.Name)
		or handle.Name
		or "x"
	name = tostring(name)
	local h = 0
	for i = 1, #name do
		h = (h * 31 + string.byte(name, i)) % 997
	end
	if (h % 2) == 0 then
		local eyeFold = Instance.new("Folder")
		eyeFold.Name = "DemonicEye"
		eyeFold.Parent = handle
		local function eye(ox)
			local p = Instance.new("Part")
			p.Name = "Eye"
			p.Shape = Enum.PartType.Ball
			p.Size = Vector3.new(0.14, 0.14, 0.14)
			p.Color = SHADOW_GLOW
			p.Material = Enum.Material.Neon
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = false
			p.CFrame = handle.CFrame * CFrame.new(ox, handle.Size.Y * 0.15, -handle.Size.Z * 0.35)
			p.Parent = eyeFold
			local w = Instance.new("WeldConstraint")
			w.Part0 = handle
			w.Part1 = p
			w.Parent = p
		end
		eye(-0.12)
		eye(0.12)
	end
end

--[[
	SHINY AND SHADOW YOU CAN READ FROM ACROSS THE PIT.

	The first finish FX hung off the Handle, and on a named tool the Handle is
	the grip: the sparkles came out of the player's fist while the head -- the
	part everyone looks at -- stayed plain. These emit from an invisible aura
	sized to the whole tool, and each finish gets a rim that reads at any
	distance: white for Shiny, #C41E3A for Shadow.
]]
local SPARKLE_TEX = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE_TEX = "rbxasset://textures/particles/fire_main.dds"
local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"

local function seq(points)
	local k = {}
	for _, p in ipairs(points) do
		k[#k + 1] = NumberSequenceKeypoint.new(p[1], p[2])
	end
	return NumberSequence.new(k)
end

-- The tool's visible parts: not the grip, not our own decor.
local function finishParts(root, handle)
	local t = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") and d ~= handle and d.Transparency < 0.95
			and d.Name ~= "FinishAura"
			and not (d.Parent and (d.Parent.Name == "DemonicEye" or d.Parent.Name == "ShinyGlint")) then
			t[#t + 1] = d
		end
	end
	return t
end

-- Corners of the visible geometry in the handle's space.
local function cornersInHandle(parts, handle)
	local hc = handle.CFrame
	local out = {}
	for _, p in ipairs(parts) do
		local cf, h = p.ExtentsCFrame, p.ExtentsSize * 0.5
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					out[#out + 1] = hc:PointToObjectSpace(cf:PointToWorldSpace(Vector3.new(sx * h.X, sy * h.Y, sz * h.Z)))
				end
			end
		end
	end
	return out
end

-- Invisible part wrapping the whole tool. Particles spawn on its SKIN, not in
-- its volume: inside a solid bomb they would be born hidden and die there.
local function finishAura(root, handle, parts)
	local corners = cornersInHandle(parts, handle)
	if #corners == 0 then
		return nil, 4
	end
	local lo, hi = corners[1], corners[1]
	for _, v in ipairs(corners) do
		lo, hi = lo:Min(v), hi:Max(v)
	end
	local size = hi - lo
	local aura = Instance.new("Part")
	aura.Name = "FinishAura"
	aura.Size = Vector3.new(math.max(size.X * 1.05, 0.5), math.max(size.Y * 1.05, 0.5), math.max(size.Z * 1.05, 0.5))
	aura.CFrame = handle.CFrame * CFrame.new((lo + hi) * 0.5)
	aura.Transparency = 1
	aura.CanCollide = false
	aura.CanQuery = false
	aura.CanTouch = false
	aura.Massless = true
	aura.CastShadow = false
	aura.Anchored = handle.Anchored
	aura.Parent = (root:IsA("BasePart") and root.Parent) or root
	local w = Instance.new("WeldConstraint")
	w.Part0 = handle
	w.Part1 = aura
	w.Parent = aura
	return aura, math.max(size.X, size.Y, size.Z)
end

local function finishRim(root, color, transparency)
	local rim = Instance.new("Highlight")
	rim.Name = "FinishRim"
	rim.FillTransparency = 1
	rim.OutlineColor = color
	rim.OutlineTransparency = transparency or 0.15
	rim.DepthMode = Enum.HighlightDepthMode.Occluded
	rim.Parent = root
	return rim
end

--[[
	SHINY YOU CAN SEE ON A CARD.

	Everything else Shiny does is reflectance, a rim Highlight and particles, and
	a ViewportFrame renders none of the three -- the inventory tile and the shop
	preview strip particles and lights outright before they draw. Measured before
	this existed: a Shiny pickaxe tile came out pixel-identical to a plain one
	(body luma 0.523 either way), which is a strange thing to charge a chase rate
	for. Shadow never had the problem because it repaints the tool, and paint
	survives anything.

	So Shiny gets GEOMETRY too: three small neon twinkles welded to the handle.
	Four parts each, and they cover EVERY skin in the game at once -- a named
	model or a procedurally reskinned rung -- because they hang off applyFinish
	rather than off any one tool.
]]
local function attachShinyGlints(root, handle, parts)
	local corners = cornersInHandle(parts, handle)
	if #corners == 0 then
		return
	end
	local lo, hi = corners[1], corners[1]
	for _, v in ipairs(corners) do
		lo, hi = lo:Min(v), hi:Max(v)
	end
	local size, mid = hi - lo, (lo + hi) * 0.5
	local span = math.max(size.X, size.Y, size.Z)
	local fold = Instance.new("Folder")
	fold.Name = "ShinyGlint"
	fold.Parent = handle
	-- Biggest at the business end, the other two smaller and tilted, so three
	-- read as a sparkle rather than as three identical beads.
	local spots = {
		{ Vector3.new(hi.X * 0.80, mid.Y + size.Y * 0.22, mid.Z), 0.20, 20 },
		{ Vector3.new(mid.X, mid.Y - size.Y * 0.18, hi.Z * 0.70), 0.13, -34 },
		{ Vector3.new(lo.X * 0.55, mid.Y + size.Y * 0.10, lo.Z * 0.55), 0.10, 48 },
	}
	for _, row in ipairs(spots) do
		-- Ceiling high enough that a five-stud pickaxe gets a glint you can see
		-- at tile size, low enough that a hand bomb does not wear a star.
		local len = math.clamp(span * row[2], 0.10, 0.85)
		local thin = len * 0.11
		local at = handle.CFrame * CFrame.new(row[1]) * CFrame.Angles(0, 0, math.rad(row[3]))
		for _, dim in ipairs({ Vector3.new(thin, len, thin), Vector3.new(len * 0.58, thin, thin) }) do
			local p = Instance.new("Part")
			p.Name = "Glint"
			p.Size = dim
			p.CFrame = at
			p.Color = Color3.fromRGB(240, 250, 255)
			p.Material = Enum.Material.Neon
			-- Matches the aura: anchored on a stored model, welded in a hand.
			p.Anchored = handle.Anchored
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = false
			p.Parent = fold
			local w = Instance.new("WeldConstraint")
			w.Part0 = handle
			w.Part1 = p
			w.Parent = p
		end
	end
end

local function attachShinyFinish(root, handle)
	local parts = finishParts(root, handle)
	-- A polish that scales with how bright the part already is: a white tool
	-- gets a real mirror, a dark one barely moves (flat reflectance greys out
	-- a black pick).
	for _, p in ipairs(parts) do
		if p.Material ~= Enum.Material.Neon then
			local c = p.Color
			p.Reflectance = math.clamp(p.Reflectance + 0.3 * (c.R + c.G + c.B) / 3, 0, 0.5)
		end
	end
	attachShinyGlints(root, handle, parts)
	local aura, span = finishAura(root, handle, parts)
	local host = aura or handle
	local k = math.clamp(span / 4, 0.6, 1.4)

	local flecks = Instance.new("ParticleEmitter")
	flecks.Name = "ShinyFlecks"
	flecks.Texture = SPARKLE_TEX
	flecks.Rate = 36
	flecks.Lifetime = NumberRange.new(0.5, 1.1)
	flecks.Speed = NumberRange.new(0.2, 0.9)
	flecks.SpreadAngle = Vector2.new(180, 180)
	flecks.Rotation = NumberRange.new(0, 360)
	flecks.RotSpeed = NumberRange.new(-90, 90)
	flecks.Size = seq({ { 0, 0.08 * k }, { 0.3, 0.32 * k }, { 1, 0 } })
	flecks.Transparency = seq({ { 0, 0.05 }, { 0.6, 0.25 }, { 1, 1 } })
	flecks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 236, 190)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 230, 255)),
	})
	flecks.LightEmission = 1
	flecks.LightInfluence = 0
	flecks.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	flecks.Parent = host

	-- A few big star flashes: the "ting" that says shiny at a glance.
	local glints = Instance.new("ParticleEmitter")
	glints.Name = "ShinyGlints"
	glints.Texture = SPARKLE_TEX
	glints.Rate = 4
	glints.Lifetime = NumberRange.new(0.25, 0.45)
	glints.Speed = NumberRange.new(0, 0)
	glints.Rotation = NumberRange.new(0, 360)
	glints.Size = seq({ { 0, 0 }, { 0.25, 1.1 * k }, { 1, 0 } })
	glints.Transparency = seq({ { 0, 0 }, { 1, 0.4 } })
	glints.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	glints.LightEmission = 1
	glints.LightInfluence = 0
	glints.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	glints.Parent = host

	attachGlow(host, Color3.fromRGB(255, 244, 214), 1.3, 8)
	finishRim(root, Color3.fromRGB(240, 252, 255), 0.2)
	attachRibbonTrail(handle, {
		Prefix = "ShinyTrail",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 230, 170)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 210, 255)),
		}),
		Lifetime = 2.75,
		MaxLength = 30,
		LightEmission = 0.95,
	})
end

-- Two glowing eyes on each side of the tool's head. "Up" comes from the Grip
-- (the hand's +Y in the handle's space), so it works for a pick held by its
-- haft and a drill held by its body alike.
local function placeDemonEyes(root, handle, parts, k)
	local grip = root:IsA("Tool") and root.Grip or CFrame.identity
	local up = grip:VectorToWorldSpace(Vector3.yAxis)
	local fwd = grip:VectorToWorldSpace(-Vector3.zAxis)
	local side = fwd:Cross(up).Unit
	local corners = cornersInHandle(parts, handle)
	if #corners == 0 then
		return
	end
	local minU, maxU = math.huge, -math.huge
	for _, v in ipairs(corners) do
		local u = v:Dot(up)
		minU, maxU = math.min(minU, u), math.max(maxU, u)
	end
	-- The head: whatever sits in the top third.
	local cut = maxU - (maxU - minU) * 0.33
	local sMin, sMax, fSum, n = math.huge, -math.huge, 0, 0
	for _, v in ipairs(corners) do
		if v:Dot(up) >= cut then
			local sv = v:Dot(side)
			sMin, sMax = math.min(sMin, sv), math.max(sMax, sv)
			fSum += v:Dot(fwd)
			n += 1
		end
	end
	if n == 0 then
		return
	end
	local fMid = fSum / n
	local uEye = maxU - (maxU - cut) * 0.45
	local fold = Instance.new("Folder")
	fold.Name = "DemonicEye"
	fold.Parent = handle
	local r = 0.15 * k
	local function eye(sv, df)
		local p = Instance.new("Part")
		p.Name = "Eye"
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(r, r, r)
		p.Color = SHADOW_GLOW
		p.Material = Enum.Material.Neon
		p.Anchored = handle.Anchored
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.CFrame = handle.CFrame * CFrame.new(up * uEye + fwd * (fMid + df) + side * sv)
		p.Parent = fold
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle
		w.Part1 = p
		w.Parent = p
	end
	for _, sv in ipairs({ sMax + r * 0.2, sMin - r * 0.2 }) do
		eye(sv, -r * 0.9)
		eye(sv, r * 0.9)
	end
end

-- Names that mark a part as trim rather than body.
local ACCENT_KEYS = {
	"edge", "tip", "rivet", "inlay", "glow", "eye", "gem", "crystal", "rune",
	"spark", "accent", "trim", "stripe", "fuse", "flame", "light", "corona",
}

--[[
	Obsidian paint. The body is black metal at zero reflectance (anything
	shinier catches the red light and reads pink); only real trim burns #6E0814.

	"Small part = trim" does not survive a hand-sized tool, where nearly every
	part is under half a cubic stud and the whole pick came out neon red. Trim
	is what was already neon, or what is named like trim, capped at a quarter
	of the tool's SURFACE (volume let a big flat blade through and painted a
	whole slab red); with none of either, the smallest few parts take it.
]]
local function paintObsidian(parts)
	local total, rows = 0, {}
	for _, p in ipairs(parts) do
		local s3 = p.ExtentsSize
		local area = 2 * (s3.X * s3.Y + s3.Y * s3.Z + s3.X * s3.Z)
		total += area
		local key = string.lower(p.Name)
		local named = false
		for _, k in ipairs(ACCENT_KEYS) do
			if key:find(k, 1, true) then
				named = true
				break
			end
		end
		rows[#rows + 1] = {
			p = p,
			area = area,
			accent = named or p.Material == Enum.Material.Neon or p.Material == Enum.Material.ForceField,
		}
	end
	table.sort(rows, function(a, b)
		return a.area < b.area
	end)
	local budget, used, any = total * 0.25, 0, false
	for _, r in ipairs(rows) do
		if r.accent and used + r.area <= budget then
			used += r.area
			any = true
		else
			r.accent = false
		end
	end
	if not any and #rows > 2 then
		local cap = total * 0.1
		for i = 1, math.min(6, #rows - 1) do
			local r = rows[i]
			if used + r.area > cap and i > 1 then
				break
			end
			r.accent = true
			used += r.area
		end
	end
	for _, r in ipairs(rows) do
		local p = r.p
		if p:IsA("MeshPart") and p.TextureID ~= "" then
			p.TextureID = ""
		end
		if r.accent then
			p.Color = SHADOW_NEON
			p.Material = Enum.Material.Neon
		else
			p.Color = SHADOW_BODY
			p.Material = Enum.Material.Metal
		end
		p.Reflectance = 0
	end
end

local function attachShadowFinish(root, handle)
	local parts = finishParts(root, handle)
	paintObsidian(parts)
	local aura, span = finishAura(root, handle, parts)
	local host = aura or handle
	local k = math.clamp(span / 4, 0.6, 1.4)

	-- Hellfire licking up off the whole tool.
	local flames = Instance.new("ParticleEmitter")
	flames.Name = "ShadowFlames"
	flames.Texture = FIRE_TEX
	flames.Rate = 34
	flames.Lifetime = NumberRange.new(0.3, 0.65)
	flames.Speed = NumberRange.new(0.4, 1.4)
	flames.SpreadAngle = Vector2.new(180, 180)
	flames.Acceleration = Vector3.new(0, 5, 0)
	flames.Drag = 2
	flames.Rotation = NumberRange.new(0, 360)
	flames.RotSpeed = NumberRange.new(-120, 120)
	flames.Size = seq({ { 0, 0.25 * k }, { 0.35, 0.75 * k }, { 1, 0 } })
	flames.Transparency = seq({ { 0, 0.15 }, { 0.6, 0.45 }, { 1, 1 } })
	flames.Color = ColorSequence.new(SHADOW_GLOW, SHADOW_NEON)
	flames.LightEmission = 1
	flames.LightInfluence = 0
	flames.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	flames.Parent = host

	-- Embers that drift up and wink out.
	local embers = Instance.new("ParticleEmitter")
	embers.Name = "ShadowEmbers"
	embers.Texture = SPARKLE_TEX
	embers.Rate = 30
	embers.Lifetime = NumberRange.new(0.8, 1.6)
	embers.Speed = NumberRange.new(0.4, 1.6)
	embers.SpreadAngle = Vector2.new(180, 180)
	embers.Acceleration = Vector3.new(0, 2.2, 0)
	embers.Drag = 1.5
	embers.Size = seq({ { 0, 0.1 * k }, { 0.3, 0.28 * k }, { 1, 0 } })
	embers.Transparency = seq({ { 0, 0.05 }, { 0.6, 0.3 }, { 1, 1 } })
	embers.Color = ColorSequence.new(SHADOW_GLOW)
	embers.LightEmission = 1
	embers.LightInfluence = 0
	embers.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	embers.Parent = host

	-- Black smoke rolling off it; no light emission, so it darkens.
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "ShadowSmoke"
	smoke.Texture = SMOKE_TEX
	smoke.Rate = 7
	smoke.Lifetime = NumberRange.new(1.1, 2.0)
	smoke.Speed = NumberRange.new(0.2, 0.6)
	smoke.SpreadAngle = Vector2.new(180, 180)
	smoke.Acceleration = Vector3.new(0, 1.1, 0)
	smoke.Rotation = NumberRange.new(0, 360)
	smoke.RotSpeed = NumberRange.new(-30, 30)
	smoke.Size = seq({ { 0, 0.5 * k }, { 1, 1.5 * k } })
	smoke.Transparency = seq({ { 0, 0.55 }, { 0.5, 0.7 }, { 1, 1 } })
	smoke.Color = ColorSequence.new(Color3.new(0, 0, 0), SHADOW_NEON)
	smoke.LightEmission = 0
	smoke.LightInfluence = 0
	smoke.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	smoke.Parent = host

	attachGlow(host, SHADOW_GLOW, 2.2, 10)
	finishRim(root, SHADOW_GLOW, 0.1)
	attachShadowTrail(handle)
	placeDemonEyes(root, handle, parts, k)
end

function ToolModelFactory.applyFinish(root, finish)
	finish = tostring(finish or "Normal")
	if not FINISH[finish] then
		finish = "Normal"
	end
	clearFinishDecor(root)
	if finish == "Normal" or finish == "Golden" or finish == "Prism" or finish == "Rainbow" then
		if root:IsA("Model") or root:IsA("Tool") then
			root:SetAttribute("Finish", finish)
		end
		return root
	end

	local handle = root:IsA("BasePart") and root or root:FindFirstChild("Handle", true)
	if handle and handle:IsA("Model") then
		handle = handle.PrimaryPart or handle:FindFirstChildWhichIsA("BasePart", true)
	end
	if not handle or not handle:IsA("BasePart") then
		handle = root:IsA("BasePart") and root or root:FindFirstChildWhichIsA("BasePart", true)
	end

	if finish == "Shiny" then
		-- Original skin, polished; sparkles over the whole tool and a white rim.
		if handle then attachShinyFinish(root, handle) end
	elseif finish == "Shadow" then
		-- Obsidian body, #6E0814 trim, #C41E3A fire; see attachShadowFinish.
		if handle then
			attachShadowFinish(root, handle)
		else
			for _, d in ipairs(root:GetDescendants()) do
				paintShadowPart(d)
			end
		end
	elseif finish == "Nightmare" then
		for _, d in ipairs(root:GetDescendants()) do
			paintShadowPart(d)
		end
		if root:IsA("BasePart") then paintShadowPart(root) end
		ensureShadowAccents(root)
		local function paintNight(d)
			if not d:IsA("BasePart") then return end
			if d.Material == Enum.Material.Neon then
				d.Color = NIGHTMARE_NEON
			else
				d.Color = NIGHTMARE_BODY
			end
		end
		for _, d in ipairs(root:GetDescendants()) do paintNight(d) end
		if root:IsA("BasePart") then paintNight(root) end
		if handle then attachShadowFx(handle, root) end
	end

	if root:IsA("Model") or root:IsA("Tool") then
		root:SetAttribute("Finish", finish)
	end
	return root
end

--[[
	Rebuild the stored Shiny / Shadow variants of every named tool from its
	Normal model: fitted, posed as held, with the finish and its FX baked in,
	so the folder shows what the game shows. Edit-time only; the game itself
	always builds from Normal and applies the finish live, so nothing depends
	on this having been run. Note the generated tools are packages: this swaps
	their Shiny / Shadow package copies for plain models. `families` maps a
	tool name to its family (the ladder's); unknown names fall back to a guess.
]]
function ToolModelFactory.bakeFinishVariants(families, finishes)
	local root = ToolModelFactory.toolModelsRoot()
	if not root then
		return 0
	end
	local n = 0
	for _, folder in ipairs(root:GetChildren()) do
		for _, fin in ipairs(finishes or { "Shiny", "Shadow" }) do
			local old = folder:FindFirstChild(fin)
			local fam = families and families[folder.Name] or nil
			local model, handle, grip = ToolModelFactory.fromNamed(folder.Name, "Normal", fam)
			if model and handle then
				local famUsed = fam or model:GetAttribute("NamedFamily")
				local tool = Instance.new("Tool")
				tool.Grip = grip
				handle.Parent = tool
				for _, c in ipairs(model:GetChildren()) do
					if c ~= handle then
						c.Parent = tool
					end
				end
				model:Destroy()
				ToolModelFactory.applyFinish(tool, fin)
				local baked = Instance.new("Model")
				baked.Name = fin
				for _, c in ipairs(tool:GetChildren()) do
					c.Parent = baked
				end
				tool:Destroy()
				baked.PrimaryPart = handle
				if old then
					for k, v in pairs(old:GetAttributes()) do
						-- RBX_ attributes belong to the engine (AI generation
						-- tags); a script may not write them.
						if not string.find(k, "^RBX_") then
							baked:SetAttribute(k, v)
						end
					end
				end
				baked:SetAttribute("Finish", fin)
				baked:SetAttribute("Posed", true)
				baked:SetAttribute("Grip", grip)
				baked:SetAttribute("NamedFamily", famUsed)
				-- Stand it where the old one stood, as a raised hand would hold it.
				local at = old and old:GetPivot().Position or Vector3.new(0, -500, 0)
				baked:PivotTo(CFrame.new(at) * grip:Inverse())
				for _, d in ipairs(baked:GetDescendants()) do
					if d:IsA("BasePart") then
						d.Anchored = true
					end
				end
				baked.Parent = folder
				if old then
					old:Destroy()
				end
				n += 1
			end
		end
	end
	return n
end

function ToolModelFactory.cloneWithFinish(source, finish, parent)
	local clone = source:Clone()
	clone.Name = tostring(finish or "Normal")
	if parent then clone.Parent = parent end
	return ToolModelFactory.applyFinish(clone, finish)
end


return ToolModelFactory
