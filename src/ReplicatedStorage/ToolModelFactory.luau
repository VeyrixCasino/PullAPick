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
-- THE ORE LOOK
--
-- A forged tool used to look like nothing in particular. The procedural
-- builders colour themselves from an eight-step ramp indexed by `lookTier` -- a
-- COSMETIC shop-ladder rung -- so all 82 ore tools shared eight palettes, two
-- ores at the same rung came out identical, and the ore a tool was made of was
-- visible nowhere on it. One flat colour off a ramp, 82 times.
--
-- Every ore row already carries what is needed to fix that: a colour, a real
-- Enum.Material, metalness and roughness. This turns a row into an override the
-- builders use in place of their ramps.
--
-- What each piece is, and why:
--
--   metal   the ore's own colour, on the head where it reads.
--   haft    mostly charcoal with a QUARTER of the ore in it. A haft in the same
--           colour as the head makes the whole tool one silhouette-less block;
--           a pure neutral haft on every tool throws the ore away again.
--   mat     the ore's own material, so obsidian is glassy and pumice is not.
--   refl    met * (1 - rough): a polished metal gleams, a rough rock does not.
--           Scaled to 0.65 because a mirror finish is reserved for Shiny.
--   lit     a glowing rune, and ONLY for ores that have any business glowing --
--           Neon or Glass materials, or a smooth non-metal (a cut gem). A
--           glowing vein on a lump of limestone is the kind of detail that
--           makes everything look cheap.
--   shapeT  silhouette across the WHOLE roster rather than eight rungs, so a
--           tier-1 tool is stubby and a tier-82 one is long and shallow. This
--           is what stops two different-coloured tools being the same tool.
--------------------------------------------------------------------------------
function ToolModelFactory.oreLook(ore, oreCount)
	if type(ore) ~= "table" or typeof(ore.color) ~= "Color3" then
		return nil
	end
	local met = math.clamp(tonumber(ore.met) or 0, 0, 1)
	local rough = math.clamp(tonumber(ore.rough) or 0.9, 0, 1)
	local mat = (typeof(ore.material) == "EnumItem") and ore.material or Enum.Material.Rock
	--[[
		THE AUTHORED GLOW WINS.

		29 of the 82 rows carry `glow` (a Color3) and `glowBright`, hand-picked
		per ore -- Ember glows orange out of a near-black rock, Phosphorus glows
		GREEN out of a pale yellow one. Deriving a glow from the ore's own colour
		instead, as this first did, throws that away and gets Phosphorus wrong in
		the one way a player would notice.

		So: use what is authored, and only guess for the rows that author
		nothing. The guess stays conservative -- Neon and Glass materials, or a
		smooth non-metal (a cut gem) -- because a glowing vein on limestone is
		the detail that makes a whole set look cheap.

		`rainbow` (Bismuth) is iridescent, which a flat Color3 cannot be. It gets
		a bright accent so it is not dull, and real iridescence is left for a
		texture or a shader rather than faked here.
	]]
	local lit
	if typeof(ore.glow) == "Color3" then
		local bright = math.clamp(tonumber(ore.glowBright) or 0.5, 0, 1)
		lit = ore.glow:Lerp(C3(255, 255, 255), bright * 0.35)
	elseif ore.rainbow then
		lit = ore.color:Lerp(C3(255, 255, 255), 0.5)
	elseif mat == Enum.Material.Neon or mat == Enum.Material.Glass
		or (met <= 0.05 and rough <= 0.3) then
		lit = ore.color:Lerp(C3(255, 255, 255), 0.45)
	end
	local n = math.max(2, math.floor(tonumber(oreCount) or 82))
	local tier = math.clamp(math.floor(tonumber(ore.tier) or 1), 1, n)
	--[[
		THE HAFT IS WOOD, THEN METAL. IT IS NOT THE ORE'S COLOUR.

		Owner, 2026-10-10: "all the coloring is off aswell / use the icons as
		reference."

		This returned `ore.color:Lerp(DARK, 0.75)` -- a dark version of the ORE
		colour -- so a green ore gave a green-black haft and a blue ore a
		blue-black one. No icon does that: icon-01 is a bronze head on a
		WOOD-BROWN haft, icon-30 a bone head on the same wood, icon-55 a blue
		head on near-BLACK, icon-73 a crystal head on near-black.

		The haft tracks TIER, not ore -- wood early, dark metal late -- which
		leaves the head as the only part carrying the ore's identity.
		Crossfaded, so no rung visibly swaps handle.
	]]
	local t = (tier - 1) / (n - 1)
	local look = {
		shapeT = t,
		metal = ore.color,
		haft = C3(120, 82, 48):Lerp(C3(42, 44, 52), math.clamp(t * 1.25, 0, 1)),
		mat = mat,
		refl = met * (1 - rough) * 0.65,
		lit = lit,
	}
	--[[
		FROSTFIRE IS A FIGHT. Owner, 2026-10-11: "should feel like more of a
		fight between fire and ice ... MAKE SURE FROSTFIRE IS GOOD". One ice-blue
		colour with an orange glow read as an ice tool with a nightlight, so the
		tool is split down the middle instead: one side glacier ice, the other
		molten fire (applySplit, after every builder).
	]]
	if ore.id == "frostfire" then
		look.split = {
			ice = C3(170, 226, 255), iceMat = Enum.Material.Ice,
			-- Bright plastic, not CrackedLava: lava renders near-black with
			-- orange cracks, which reads as burnt rather than burning.
			fire = C3(255, 112, 30), fireMat = Enum.Material.SmoothPlastic,
			ember = C3(255, 196, 70),
			seam = C3(255, 236, 200),
		}
	end
	return look
end

-- Split a built tool down its own X axis (see oreLook's Frostfire note):
-- parts left of centre turn to ice, right of centre to fire -- small fire-side
-- parts glow as embers -- and thin parts on the line become the bright seam
-- where the two meet. Neon parts (runes, vents, gems) burn either way.
local function applySplit(model, split)
	if type(split) ~= "table" then
		return
	end
	--[[
		A part that runs ACROSS the line (its own X along the model's X: a
		hammer head, a band, a crossbar) is cut in two at x = 0, so the head
		really is half ice and half fire. Only blocks and cylinders, and never
		the Handle, which the grip is measured from.
	]]
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("Part") and p.Name ~= "Handle"
			and (p.Shape == Enum.PartType.Block or p.Shape == Enum.PartType.Cylinder)
			and math.abs(p.CFrame.RightVector.X) > 0.98 then
			local x0, half = p.Position.X, p.Size.X * 0.5
			local lo, hi = x0 - half, x0 + half
			if lo < -0.04 and hi > 0.04 then
				local rot = p.CFrame - p.CFrame.Position
				for _, span in ipairs({ { lo, 0 }, { 0, hi } }) do
					local q = p:Clone()
					q.Size = Vector3.new(span[2] - span[1], p.Size.Y, p.Size.Z)
					q.CFrame = CFrame.new((span[1] + span[2]) * 0.5, p.Position.Y, p.Position.Z) * rot
					q.Parent = p.Parent
				end
				-- The seam where they meet: a thin bright slice, steam-white.
				if p.Size.Y > 0.2 or p.Size.Z > 0.2 then
					local s = p:Clone()
					s.Name = "FrostSeam"
					for _, c in ipairs(s:GetChildren()) do
						c:Destroy()
					end
					s.Size = Vector3.new(0.05, p.Size.Y * 1.04, p.Size.Z * 1.04)
					s.CFrame = CFrame.new(0, p.Position.Y, p.Position.Z) * rot
					s.Color = split.seam
					s.Material = Enum.Material.Neon
					s.Parent = p.Parent
				end
				p:Destroy()
			end
		end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "FrostSeam" then
			local x = p.Position.X
			-- What could not be cut and sits on the line goes by height: the
			-- fire climbs, the ice holds the bottom.
			if math.abs(x) < 0.04 then
				x = (p.Position.Y < 0) and -1 or 1
			end
			if p.Material == Enum.Material.Neon then
				p.Color = split.ember
			elseif x < 0 then
				p.Color = split.ice
				p.Material = split.iceMat
				p.Reflectance = 0.15
			elseif p.Size.Magnitude < 0.45 then
				p.Color = split.ember
				p.Material = Enum.Material.Neon
			else
				p.Color = split.fire
				p.Material = split.fireMat
				p.Reflectance = 0
			end
		end
	end
	local hot
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Material == split.fireMat and (not hot or p.Size.Magnitude > hot.Size.Magnitude) then
			hot = p
		end
	end
	if hot then
		local f = Instance.new("ParticleEmitter")
		f.Name = "Frostfire"
		f.Color = ColorSequence.new(split.fire, C3(255, 214, 120))
		f.LightEmission = 1
		f.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(1, 0) })
		f.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		f.Lifetime = NumberRange.new(0.35, 0.6)
		f.Rate = 14
		f.Speed = NumberRange.new(0.6, 1.2)
		f.Acceleration = Vector3.new(0, 2.5, 0)
		f.Parent = hot
	end
end

--------------------------------------------------------------------------------
-- PICKAXE
--
-- A swept double-pick. Each arm is a chain of tapering plates that turns a few
-- degrees per link, so the head curves down into a point instead of sticking out
-- flat. Low tiers are stubby with a hard hook; high tiers are long and shallow.
--------------------------------------------------------------------------------

--[[
	THE TOOL SILHOUETTES ARE FIXED PER FAMILY, and that is a correction.

	Owner, 2026-10-10: "You cant just cut them in half and call them different
	tools... use the icons as reference."

	I had split each family into five head types on the theory that variety
	meant different tools. The art in Downloads/icons/out says otherwise: a
	pickaxe is ONE double-horned silhouette at every tier, a drill is ONE
	spiral auger, and every explosive past the wood tier is ONE faceted
	sphere. What climbs the roster is MATERIAL, plus growth at the deep end --
	shards budding off a pick head, as in icon-73 -- not the shape.

	So styleFor and the fourteen invented shapes are gone. What carries the
	ore identity is colour, material and reflectance from oreLook, and the
	haft deliberately does NOT take the ore colour: every icon puts a wood or
	near-black handle under a coloured head.

	Everything here is Parts. That is not a style choice -- it is the only
	thing in this game that renders. Every MeshPart archive in the place is
	empty, because CreateMeshPartAsync geometry does not survive a save.
]]

local function pickArm(model, root, t, col, mat, lit, refl)
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

	--[[
		THE HORNS DROP. Owner: "use the icons as reference."

		This started at +9 degrees and curved further positive, sweeping the
		horn back and UP, which reads as a hooked climbing axe. Every pick
		icon has the horns starting level and falling BELOW the collar line so
		the head makes a shallow V.
	]]
	local cur = CFrame.new(0.24, 0, 0) * CFrame.Angles(0, 0, math.rad(-6))
	for j = 1, segs do
		local f = (j - 1) / segs
		box({
			Name = "Arm",
			Size = Vector3.new(len + 0.02, thick * (1 - f * 0.40), depth * (1 - f * 0.28)),
			CFrame = root * cur * CFrame.new(len * 0.5, 0, 0),
			Color = col:Lerp(C3(255, 255, 255), f * 0.14),
			Material = mat, Reflectance = refl or (0.04 + t * 0.22),
		}, model)
		cur = cur * CFrame.new(len, 0, 0) * CFrame.Angles(0, 0, -turn)
	end
	edge({
		Name = "Tip", Length = 0.36 + t * 0.12, Width = depth * 0.62, Height = thick * 0.6,
		CFrame = root * cur,
		Color = col:Lerp(C3(255, 255, 255), 0.34), Material = mat,
		Reflectance = refl and (refl + 0.08) or (0.1 + t * 0.3),
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

local function pickHead(model, root, t, col, mat, lit, refl)
	--[[
		ONE PICKAXE, RE-SKINNED -- NOT FIVE DIFFERENT TOOLS.

		Owner, 2026-10-10: "You cant just cut them in half and call them
		different tools... use the icons as reference."

		I had built five head TYPES here -- adze, warpick, crescent, spire --
		on the theory that variety meant different tools. The art says
		otherwise. Downloads/icons/out/picks:

		  icon-01  bronze head, wood haft   \
		  icon-30  bone head, wood haft      |  the SAME double-horned pick
		  icon-55  blue head, dark haft      |  every single time
		  icon-73  crystal head, dark haft  /   + purple shards budding off it

		One silhouette throughout: two horns sweeping down and out from a
		central collar on a straight haft. What changes with tier is MATERIAL,
		and at the deep end GROWTH -- shards budding around the collar -- not
		the shape of the tool. A Spectrite pick is still a pickaxe.

		The four invented heads are deleted rather than parked: they were
		wrong about what the roster is, and a dead builder is an invitation to
		switch it back on.
	]]
	pickArm(model, root, t, col, mat, lit, refl)
	pickArm(model, root * CFrame.Angles(0, math.pi, 0), t, col, mat, lit, refl)

	-- Growth, not a new head. icon-73 is this same pick with shards around the
	-- collar, so they bud at the root of the horns rather than replacing them.
	if t > 0.62 then
		local n = 3 + math.floor((t - 0.62) * 10)
		for i = 1, n do
			local a = math.rad((i / n) * 360 + t * 90)
			local up = 0.12 + ((i % 3) * 0.16)
			local len = 0.22 + ((i % 2) * 0.16) + (t - 0.62) * 0.5
			box({
				Name = "Shard",
				Size = Vector3.new(0.13, len, 0.13),
				CFrame = root * CFrame.Angles(0, a, 0) * CFrame.new(0.2, up, 0)
					* CFrame.Angles(math.rad(18), 0, math.rad((i % 2 == 0) and 24 or -24)),
				Color = col:Lerp(C3(255, 255, 255), 0.3 + (i % 3) * 0.12),
				Material = mat,
				Reflectance = (refl or 0.1) + 0.12,
			}, model)
		end
	end
	return 0
end

local function buildPickaxe(t, model, look)
	local metal = (look and look.metal) or ramp(PICK_METAL, t)
	local haft = (look and look.haft) or ramp(PICK_HAFT, t)
	local mat = (look and look.mat) or metalFor(t)
	local lit = look and look.lit or (not look and t > 0.66 and ramp(CELL, t)) or nil

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
	-- The one pickaxe silhouette the icons show, plus deep-end shard growth.
	local headStyle = pickHead(model, head, t, metal, mat, lit, look and look.refl)
	model:SetAttribute("HeadStyle", headStyle)

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

local function buildDrill(t, model, look)
	local body = (look and look.haft) or ramp(DRILL_BODY, t)
	local bit = (look and look.metal) or ramp(DRILL_BIT, t)
	local mat = (look and look.mat) or metalFor(t)
	--[[
		AN ORE THAT DOES NOT GLOW GETS A DARK CELL, NOT A BRIGHT ONE.

		The old line read `(look and look.lit) or ((not look) and ramp(...)) or
		ramp(...)`, where the trailing `or ramp(...)` made the middle clause
		dead and handed a Neon cell to EVERY ore -- including the ones oreLook
		deliberately leaves unlit, which is the case the rule at the top of this
		file calls out by name: "a glowing vein on a lump of limestone is the
		kind of detail that makes everything look cheap".

		The cell, gauge and fins are structural, so they stay; they just stop
		being light sources. Unlit ores get their own colour darkened and the
		ore's own material instead of Neon.
	]]
	local glow = (look and look.lit) or ((not look) and ramp(CELL, t)) or nil
	local lit = glow or bit:Lerp(DARK, 0.45)
	local litMat = glow and Enum.Material.Neon or mat

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

	--[[
		FIVE BITS, same reasoning as the five pickaxe heads. The body, motor
		and grip stay shared -- a drill should still read as a drill -- and
		the BUSINESS END is what changes, because that is the part a player
		is looking at while it is pointed into a wall.

		  0 AUGER    the original spiral cone
		  1 TRIBIT   three straight cutters around a stubby core
		  2 CORER    an open ring saw, hollow in the middle
		  3 HAMMER   a blunt percussive piston, no spiral at all
		  4 LANCE    a long thin spike ringed with floating emitters
	]]
	local blen = 1.75 + t * 1.15
	local bz = -1.02
	-- ONE BIT. The drill icons are the same spiral auger at every tier
	-- (icon-01 and icon-55 are identical in shape), so the five bit types
	-- that were here are gone with the five pickaxe heads. Material changes;
	-- the tool does not.
		cone({
			Name = "Bit", Length = blen, Dia = 0.76, Tip = 0.08, Segs = 8,
			CFrame = CFrame.new(0, 0, bz) * CFrame.Angles(math.rad(-90), 0, 0),
			Color = bit, Material = mat, Reflectance = 0.15 + t * 0.3,
		}, model)
		-- Helical flight: plates spiralling down the cone, riding just proud of
		-- its surface so the bit reads as cut, not as a stack of discs.
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
		Color = lit, Material = litMat,
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
			CFrame = CFrame.new(0, 0.76, 0.95), Color = lit, Material = litMat,
		}, model)
	end
	if t > 0.80 then
		for _, s in ipairs({ -1, 1 }) do
			box({
				Name = "Fin", Size = Vector3.new(0.1, 0.78, 0.78),
				CFrame = CFrame.new(s * 0.66, 0.34, 0.55) * CFrame.Angles(0, 0, s * math.rad(24)),
				Color = lit, Material = litMat,
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

local function buildRanged(t, model, look)
	local body = (look and look.metal) or ramp(GUN_BODY, t)
	local lit = (look and look.lit) or ramp(CELL, t)
	local mat = (look and look.mat) or metalFor(t)

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

local function buildExplosive(t, model, look)
	local body = (look and look.metal) or ramp(BOMB_BODY, t)
	local trim = (look and look.haft) or ramp(BOMB_TRIM, t)
	local mat = (look and look.mat)
		or (t < 0.5 and Enum.Material.Metal or Enum.Material.DiamondPlate)
	--[[
		Same unlit-ore case as buildDrill: `(look and look.lit) or ramp(...)`
		gave a Neon core to every ore, because an ore oreLook decided should
		NOT glow returns look.lit = nil and fell straight through to the ramp.
		Unlit ores keep the part and lose the light.
	]]
	local glow = (look and look.lit) or ((not look) and ramp(CELL, t)) or nil
	local lit = glow or body:Lerp(DARK, 0.45)
	local litMat = glow and Enum.Material.Neon or mat

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

	--[[
		FIVE SHELLS, same reasoning again. The haft, collar and fuse stay
		shared; the body is what changes.

		  0 ORB      the original banded sphere
		  1 KEG      a squat cylinder with hoops, read as a powder keg
		  2 CANISTER a tall ribbed drum with a shoulder taper
		  3 CLUSTER  four small spheres strapped to a core
		  4 PRISM    a faceted crystal charge with no metal at all
	]]
	-- ONE SHELL. Every explosive icon past the wood tier is the same faceted
	-- sphere with a collar and a lit fuse (icon-30, 55 and 73 differ only in
	-- material), so the five shell types are gone with the five pickaxe heads.
	-- The casing is FACETED rather than smooth, which is what the art shows.
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
	-- Rivets belong on a MANUFACTURED shell. The cluster straps its bomblets
	-- instead, and the prism is grown rather than built -- a riveted crystal
	-- is the kind of detail that undoes the whole shape.
	-- Rivets round the belt, always: there is one shell now and it is a
	-- manufactured one. (This used to be gated on shellStyle, which no longer
	-- exists -- and a `nil ~= 3` comparison would have quietly been true
	-- forever rather than erroring.)
	do
		for i = 0, 7 do
			ball({
				Name = "Rivet", Dia = 0.13,
				CFrame = CFrame.new(0, cy, 0) * CFrame.Angles(0, math.rad(i * 45), 0)
					* CFrame.new(0, 0, r * 0.51),
				Color = trim:Lerp(C3(255, 255, 255), 0.35), Material = Enum.Material.Metal,
			}, model)
		end
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
			CFrame = CFrame.new(0.23, cy + r * 0.5 + 0.8, 0), Color = lit, Material = litMat,
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
				Color = lit, Material = litMat,
			}, model)
		end
		ball({
			Name = "Core", Dia = r * 0.34, CFrame = CFrame.new(0, cy, 0),
			Color = lit, Material = litMat,
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

--[[
	HAMMERS AND JACKHAMMERS, BUILT TO THE ICONS.

	Owner, 2026-10-11: "i need the hammers and jackhammers fully built in..
	every tool, every ore, all color ways.. extremely hq". The icons for both
	families were painted in Canva to match the pick, drill and grenade sheets
	(art/tool-icons/), so these builders follow them: the same silhouette at
	every ore, made OF the ore -- its colour, Enum.Material, shine and glow
	(oreLook) -- with the deep end growing bands, langets, crystal shards and
	fins rather than changing shape.

	The Handle part, its size and position, and the grips are exactly what the
	first builders used, so a hammer still sits in the hand where it did.
	Everything is plain Parts: the MeshPart archives in this place are empty
	(wiki: tools), so geometry is the detail.

	Neon is accents only (runes, vents, gems). A Neon body lights every face at
	once and reads as a blob, which is why metalFor never returns it.
]]

-- A rod from a to b (both Vector3), for hoses and lashings.
local function rod(a, b, dia, o, parent)
	local mid = (a + b) * 0.5
	-- lookAt points -Z at b; a -90 degree turn about X brings +Y onto it, and
	-- cyl() authors along +Y.
	return cyl({
		Name = o.Name or "Rod", Length = (b - a).Magnitude, Dia = dia,
		CFrame = CFrame.lookAt(mid, b) * CFrame.Angles(math.rad(-90), 0, 0),
		Color = o.Color, Material = o.Material, Reflectance = o.Reflectance,
	}, parent)
end

-- A small deterministic wobble, so shards and chips are irregular but every
-- copy of a tool is identical.
local function wob(i, k)
	return math.sin(i * 12.9898 + k * 78.233) * 0.5
end

-- A crystal shard: a long thin box with a pointed cap, leaning out of `at`.
local function shard(at, len, w, tilt, o, parent)
	local cf = at * tilt
	box({
		Name = "Shard", Size = Vector3.new(w, len, w),
		CFrame = cf * CFrame.new(0, len * 0.5, 0) * CFrame.Angles(0, math.rad(45), 0),
		Color = o.Color, Material = o.Material, Reflectance = o.Reflectance,
	}, parent)
	box({
		Name = "ShardTip", Size = Vector3.new(w * 0.62, w * 0.9, w * 0.62),
		CFrame = cf * CFrame.new(0, len + w * 0.3, 0) * CFrame.Angles(0, math.rad(45), 0),
		Color = o.Tip or o.Color, Material = o.Material, Reflectance = o.Reflectance,
	}, parent)
end

--[[
	THE SLEDGEHAMMER. Owner, 2026-10-10: "make another class (Hammers most
	damage; looks like sledge hammers)".

	One solid block square across the top of a long two-handed haft -- the
	pick's opposite in silhouette, so you never mistake which one you hold.
]]
local function buildHammer(t, model, look)
	local metal = (look and look.metal) or ramp(PICK_METAL, t)
	local haft = (look and look.haft) or ramp(PICK_HAFT, t)
	local mat = (look and look.mat) or metalFor(t)
	local lit = look and look.lit or nil
	local refl = (look and look.refl) or (0.06 + t * 0.24)
	local light = metal:Lerp(C3(255, 255, 255), 0.24)
	local shade = metal:Lerp(DARK, 0.3)
	-- The stone-age rungs are lashed with rope, as a stone tool is; metal
	-- bands start once the ore is something you could forge a band from --
	-- Copper and Tin are low tiers but metals, so they get bands.
	local metallic = mat == Enum.Material.Metal or mat == Enum.Material.CorrodedMetal
		or mat == Enum.Material.Foil or mat == Enum.Material.DiamondPlate
	local primitive = t < 0.16 and not metallic
	local bandCol = primitive and C3(156, 120, 76) or metal:Lerp(DARK, 0.52)
	local bandMat = primitive and Enum.Material.Fabric or Enum.Material.Metal
	local woodHaft = t < 0.5
	local haftMat = woodHaft and Enum.Material.Wood or Enum.Material.Metal

	------------------------------------------------------------------ haft --
	-- Longer and fatter than the pick's: a sledge is swung with two hands.
	-- Same size and place as the first build, so the grip is unchanged.
	local handle = cyl({
		Name = "Handle", Length = 3.4, Dia = 0.38,
		CFrame = CFrame.new(0, -0.35, 0),
		Color = haft, Material = haftMat, Reflectance = woodHaft and 0 or refl * 0.5,
	}, model)
	-- The throat swells where the haft meets the head.
	cyl({
		Name = "Throat", Length = 0.46, Dia = 0.46,
		CFrame = CFrame.new(0, 0.95, 0),
		Color = haft:Lerp(DARK, 0.12), Material = haftMat,
	}, model)
	for _, y in ipairs({ 1.14, -1.38 }) do
		cyl({
			Name = "Ferrule", Length = 0.1, Dia = 0.5, CFrame = CFrame.new(0, y, 0),
			Color = bandCol, Material = bandMat, Reflectance = primitive and 0 or 0.18,
		}, model)
	end
	-- A wound grip: eight turns, each canted the other way, so it reads as
	-- wrapped leather rather than a stack of rings.
	local wrapCol = woodHaft and C3(72, 50, 34) or metal:Lerp(DARK, 0.66)
	for i = 0, 7 do
		cyl({
			Name = "Wrap", Length = 0.14, Dia = 0.45,
			CFrame = CFrame.new(0, -1.94 + i * 0.16, 0) * CFrame.Angles(math.rad((i % 2 == 0) and 7 or -7), 0, 0),
			Color = wrapCol:Lerp(DARK, (i % 2) * 0.12), Material = Enum.Material.Fabric,
		}, model)
	end
	cyl({
		Name = "PommelRing", Length = 0.08, Dia = 0.6, CFrame = CFrame.new(0, -2.06, 0),
		Color = shade, Material = mat, Reflectance = refl,
	}, model)
	cyl({
		Name = "Pommel", Length = 0.2, Dia = 0.54, CFrame = CFrame.new(0, -2.18, 0),
		Color = metal, Material = mat, Reflectance = refl,
	}, model)
	ball({
		Name = "PommelKnob", Dia = 0.34, CFrame = CFrame.new(0, -2.3, 0),
		Color = light, Material = mat, Reflectance = refl,
	}, model)

	------------------------------------------------------------------ head --
	local hy = 1.42
	local hw = 1.25 + t * 0.45 -- across the haft (X)
	local hh = 0.66 + t * 0.14 -- up (Y)
	local hd = 0.66 + t * 0.12 -- front to back (Z)
	box({
		Name = "Head", Size = Vector3.new(hw, hh, hd), CFrame = CFrame.new(0, hy, 0),
		Color = metal, Material = mat, Reflectance = refl,
	}, model)
	-- Bevelled long edges: a diamond rod laid along each, in the lit colour,
	-- so the block catches light on its corners like the icon.
	for _, sy in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			box({
				Name = "Bevel", Size = Vector3.new(hw * 0.97, 0.13, 0.13),
				CFrame = CFrame.new(0, hy + sy * hh * 0.5, sz * hd * 0.5) * CFrame.Angles(math.rad(45), 0, 0),
				Color = (sy > 0) and light or shade, Material = mat, Reflectance = refl + 0.06,
			}, model)
		end
	end
	-- Striking faces: a plate proud of each end, a raised boss on it, and a
	-- band just behind -- rope on the stone rungs.
	for _, s in ipairs({ -1, 1 }) do
		local fx = s * (hw * 0.5 + 0.05)
		box({
			Name = "Face", Size = Vector3.new(0.12, hh * 1.06, hd * 1.06),
			CFrame = CFrame.new(fx, hy, 0),
			Color = light, Material = mat, Reflectance = refl + 0.1,
		}, model)
		box({
			Name = "Boss", Size = Vector3.new(0.06, hh * 0.62, hd * 0.62),
			CFrame = CFrame.new(fx + s * 0.08, hy, 0),
			Color = light:Lerp(C3(255, 255, 255), 0.12), Material = mat, Reflectance = refl + 0.14,
		}, model)
		box({
			Name = "Band", Size = Vector3.new(0.13, hh + 0.06, hd + 0.06),
			CFrame = CFrame.new(s * (hw * 0.5 - 0.2), hy, 0),
			Color = bandCol, Material = bandMat, Reflectance = primitive and 0 or 0.16,
		}, model)
	end
	-- Cheek panels front and back, with a rune slot and four rivets.
	for _, sz in ipairs({ -1, 1 }) do
		local z = sz * (hd * 0.5 + 0.025)
		box({
			Name = "Cheek", Size = Vector3.new(hw * 0.5, hh * 0.62, 0.05),
			CFrame = CFrame.new(0, hy, z),
			Color = shade, Material = mat, Reflectance = refl,
		}, model)
		box({
			Name = "Rune", Size = Vector3.new(hw * 0.36, 0.08, 0.04),
			CFrame = CFrame.new(0, hy, z + sz * 0.03),
			Color = lit or metal:Lerp(DARK, 0.6),
			Material = lit and Enum.Material.Neon or mat,
		}, model)
		if not primitive then
			for _, rx in ipairs({ -1, 1 }) do
				for _, ry in ipairs({ -1, 1 }) do
					ball({
						Name = "Rivet", Dia = 0.08,
						CFrame = CFrame.new(rx * hw * 0.21, hy + ry * hh * 0.22, z + sz * 0.03),
						Color = light, Material = Enum.Material.Metal, Reflectance = 0.2,
					}, model)
				end
			end
		end
	end
	-- Collar where the haft passes through, and the wedge that pins it.
	box({
		Name = "Collar", Size = Vector3.new(0.5, 0.18, 0.56),
		CFrame = CFrame.new(0, hy - hh * 0.5 - 0.07, 0),
		Color = shade, Material = mat, Reflectance = refl,
	}, model)
	box({
		Name = "Wedge", Size = Vector3.new(0.3, 0.08, 0.4),
		CFrame = CFrame.new(0, hy + hh * 0.5 + 0.03, 0),
		Color = haft:Lerp(C3(255, 255, 255), 0.08), Material = haftMat,
	}, model)

	if primitive then
		-- A stone head is lashed on and chipped, not banded and riveted.
		for _, sz in ipairs({ -1, 1 }) do
			for _, sx in ipairs({ -1, 1 }) do
				rod(
					Vector3.new(sx * 0.3, hy - hh * 0.5 - 0.02, sz * (hd * 0.5 + 0.02)),
					Vector3.new(-sx * 0.12, hy - hh * 0.5 - 0.32, sz * 0.2),
					0.06, { Name = "Lashing", Color = bandCol, Material = Enum.Material.Fabric }, model
				)
			end
		end
		for i = 1, 3 do
			box({
				Name = "Chip", Size = Vector3.new(0.16, 0.12, 0.05),
				CFrame = CFrame.new(wob(i, 1) * hw * 0.8, hy + wob(i, 2) * hh * 0.7, (i % 2 == 0 and 1 or -1) * (hd * 0.5 + 0.02))
					* CFrame.Angles(0, 0, wob(i, 3) * 1.2),
				Color = metal:Lerp((i % 2 == 0) and C3(255, 255, 255) or DARK, 0.2), Material = mat,
			}, model)
		end
	end

	-- Langets: straps running down the haft from the head, once the ore is a
	-- real metal.
	if t >= 0.35 then
		for _, sz in ipairs({ -1, 1 }) do
			box({
				Name = "Langet", Size = Vector3.new(0.12, 0.8, 0.04),
				CFrame = CFrame.new(0, hy - hh * 0.5 - 0.42, sz * 0.21),
				Color = bandCol, Material = bandMat, Reflectance = 0.16,
			}, model)
			ball({
				Name = "Rivet", Dia = 0.07, CFrame = CFrame.new(0, hy - hh * 0.5 - 0.66, sz * 0.24),
				Color = light, Material = Enum.Material.Metal, Reflectance = 0.2,
			}, model)
		end
	end

	-- The deep end grows shards of its own ore off the head, as the pick does.
	if t > 0.62 then
		local n = 3 + math.floor((t - 0.62) * 10)
		local shardMat = (lit and Enum.Material.Glass) or mat
		for i = 1, n do
			local x = (i / (n + 1) - 0.5) * hw * 0.9
			shard(
				CFrame.new(x, hy + hh * 0.5, wob(i, 4) * hd * 0.6),
				0.28 + (i % 3) * 0.12 + t * 0.12, 0.12,
				CFrame.Angles(wob(i, 5) * 0.7, 0, wob(i, 6) * 0.9),
				{ Color = light, Tip = lit or light:Lerp(C3(255, 255, 255), 0.3), Material = shardMat, Reflectance = refl + 0.12 },
				model
			)
		end
	end
	-- The very top: crown fins over each face and a gem in the pommel.
	if t > 0.85 then
		for _, s in ipairs({ -1, 1 }) do
			box({
				Name = "Fin", Size = Vector3.new(0.34, 0.08, hd * 0.7),
				CFrame = CFrame.new(s * (hw * 0.5 - 0.12), hy + hh * 0.5 + 0.12, 0) * CFrame.Angles(0, 0, math.rad(s * -32)),
				Color = light, Material = mat, Reflectance = refl + 0.1,
			}, model)
		end
		ball({
			Name = "Gem", Dia = 0.2, CFrame = CFrame.new(0, -2.46, 0),
			Color = lit or light, Material = lit and Enum.Material.Neon or Enum.Material.Glass,
		}, model)
	end
	return handle
end

--[[
	THE JACKHAMMER. A pneumatic breaker: body up, chisel straight down.

	Built on its own axis rather than reusing the drill. A drill is authored
	pointing FORWARD (-Z) because you aim it; a jackhammer only ever points at
	the floor, and that is the whole read of the family -- so the silhouette is
	vertical and the working end is at the bottom where the eye expects it.

	A T-bar with two grips across the top separates it from a drill at a
	glance even when both are the same colour.
]]
local function buildJackhammer(t, model, look)
	local metal = (look and look.metal) or ramp(PICK_METAL, t)
	local haft = (look and look.haft) or ramp(PICK_HAFT, t)
	local mat = (look and look.mat) or metalFor(t)
	local lit = look and look.lit or nil
	local refl = (look and look.refl) or (0.06 + t * 0.24)
	local light = metal:Lerp(C3(255, 255, 255), 0.24)
	local shade = metal:Lerp(DARK, 0.32)
	local steel = C3(150, 154, 162):Lerp(metal, 0.25)
	local gripCol = t < 0.55 and C3(58, 42, 30) or haft:Lerp(DARK, 0.3)

	-- The body IS the handle, stood upright. Same size and place as before.
	local body = cyl({
		Name = "Handle", Length = 2.6, Dia = 0.62,
		CFrame = CFrame.new(0, 0.5, 0),
		Color = metal, Material = mat, Reflectance = refl,
	}, model)

	------------------------------------------------------------- the top --
	cyl({
		Name = "TopCap", Length = 0.18, Dia = 0.72, CFrame = CFrame.new(0, 1.8, 0),
		Color = shade, Material = mat, Reflectance = refl,
	}, model)
	ball({
		Name = "Dome", Dia = 0.6, CFrame = CFrame.new(0, 1.9, 0),
		Color = metal, Material = mat, Reflectance = refl,
	}, model)
	cyl({
		Name = "Crossbar", Length = 1.7, Dia = 0.2,
		CFrame = CFrame.new(0, 2.06, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = shade, Material = Enum.Material.Metal, Reflectance = 0.15,
	}, model)
	for _, s in ipairs({ -1, 1 }) do
		-- A rubber grip on each end of the T, ridged, with a cap.
		cyl({
			Name = "Grip", Length = 0.56, Dia = 0.3,
			CFrame = CFrame.new(s * 0.62, 2.06, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = gripCol, Material = Enum.Material.Fabric,
		}, model)
		for r = -1, 1 do
			cyl({
				Name = "GripRidge", Length = 0.05, Dia = 0.34,
				CFrame = CFrame.new(s * (0.62 + r * 0.16), 2.06, 0) * CFrame.Angles(0, 0, math.rad(90)),
				Color = gripCol:Lerp(DARK, 0.3), Material = Enum.Material.Fabric,
			}, model)
		end
		ball({
			Name = "GripCap", Dia = 0.3, CFrame = CFrame.new(s * 0.92, 2.06, 0),
			Color = metal, Material = mat, Reflectance = refl,
		}, model)
		-- Braces from the bar down to the cap.
		rod(
			Vector3.new(s * 0.44, 2.04, 0), Vector3.new(s * 0.22, 1.74, 0),
			0.07, { Name = "Brace", Color = shade, Material = Enum.Material.Metal }, model
		)
	end
	-- The throttle lever, under the right grip.
	box({
		Name = "Throttle", Size = Vector3.new(0.4, 0.06, 0.12),
		CFrame = CFrame.new(0.6, 1.9, 0.12) * CFrame.Angles(0, 0, math.rad(-12)),
		Color = C3(196, 60, 40):Lerp(metal, 0.3), Material = Enum.Material.Metal, Reflectance = 0.1,
	}, model)

	------------------------------------------------- the ribbed cylinder --
	cyl({
		Name = "Cylinder", Length = 1.2, Dia = 0.86, CFrame = CFrame.new(0, 1.1, 0),
		Color = shade, Material = mat, Reflectance = refl,
	}, model)
	for i = 0, 6 do
		cyl({
			Name = "Fin", Length = 0.06, Dia = 1.02,
			CFrame = CFrame.new(0, 0.6 + i * 0.165, 0),
			Color = (i % 2 == 0) and metal or light, Material = mat, Reflectance = refl + 0.05,
		}, model)
	end
	-- Exhaust muffler on the left, slotted; the slots glow on a lit ore.
	box({
		Name = "Muffler", Size = Vector3.new(0.18, 0.56, 0.36), CFrame = CFrame.new(-0.56, 1.02, 0),
		Color = shade:Lerp(DARK, 0.2), Material = Enum.Material.Metal, Reflectance = 0.1,
	}, model)
	for i = -1, 1 do
		box({
			Name = "Vent", Size = Vector3.new(0.04, 0.06, 0.28), CFrame = CFrame.new(-0.66, 1.02 + i * 0.15, 0),
			Color = lit or DARK, Material = lit and Enum.Material.Neon or Enum.Material.Metal,
		}, model)
	end
	-- Air coupling on the right and a hose curling down and back.
	cyl({
		Name = "Coupling", Length = 0.2, Dia = 0.22,
		CFrame = CFrame.new(0.56, 1.32, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C3(196, 160, 72):Lerp(metal, 0.2), Material = Enum.Material.Metal, Reflectance = 0.2,
	}, model)
	local hose = {}
	for i = 0, 4 do
		local a = (i / 4) * math.pi * 0.5
		table.insert(hose, Vector3.new(0.66 + math.sin(a) * 0.42, 1.32 - (1 - math.cos(a)) * 0.9 - i * 0.05, -math.sin(a) * 0.32))
	end
	for i = 1, #hose - 1 do
		rod(hose[i], hose[i + 1], 0.16, { Name = "Hose", Color = C3(40, 38, 44), Material = Enum.Material.Fabric }, model)
	end

	------------------------------------------------------- the business end --
	cyl({
		Name = "Striker", Length = 0.5, Dia = 0.72, CFrame = CFrame.new(0, -0.74, 0),
		Color = metal, Material = mat, Reflectance = refl,
	}, model)
	for i = 0, 3 do
		local a = i * math.pi * 0.5 + math.pi * 0.25
		ball({
			Name = "Bolt", Dia = 0.12,
			CFrame = CFrame.new(math.cos(a) * 0.37, -0.6, math.sin(a) * 0.37),
			Color = light, Material = Enum.Material.Metal, Reflectance = 0.2,
		}, model)
	end
	-- The retainer latch that holds the chisel in.
	box({
		Name = "Latch", Size = Vector3.new(0.14, 0.42, 0.1),
		CFrame = CFrame.new(0, -0.98, 0.34) * CFrame.Angles(math.rad(-10), 0, 0),
		Color = steel, Material = Enum.Material.Metal, Reflectance = 0.15,
	}, model)
	cyl({
		Name = "Collar", Length = 0.16, Dia = 0.5, CFrame = CFrame.new(0, -1.06, 0),
		Color = shade, Material = mat, Reflectance = refl,
	}, model)
	-- An octagonal shank: two square bars, one turned 45 degrees.
	for _, a in ipairs({ 0, 45 }) do
		box({
			Name = "Shank", Size = Vector3.new(0.24, 1.0, 0.24),
			CFrame = CFrame.new(0, -1.62, 0) * CFrame.Angles(0, math.rad(a), 0),
			Color = metal, Material = mat, Reflectance = refl,
		}, model)
	end
	-- The flat chisel: a blade narrowing to its edge.
	box({
		Name = "Blade", Size = Vector3.new(0.34, 0.36, 0.14), CFrame = CFrame.new(0, -2.28, 0),
		Color = light, Material = mat, Reflectance = refl + 0.1,
	}, model)
	box({
		Name = "Edge", Size = Vector3.new(0.3, 0.2, 0.06), CFrame = CFrame.new(0, -2.52, 0),
		Color = light:Lerp(C3(255, 255, 255), 0.25), Material = mat, Reflectance = refl + 0.15,
	}, model)

	-- Reinforcing plates once it is a proper machine.
	if t >= 0.35 then
		for _, sz in ipairs({ -1, 1 }) do
			box({
				Name = "Plate", Size = Vector3.new(0.4, 0.9, 0.06), CFrame = CFrame.new(0, 0.05, sz * 0.32),
				Color = shade, Material = mat, Reflectance = refl,
			}, model)
			for _, ry in ipairs({ -1, 1 }) do
				ball({
					Name = "Rivet", Dia = 0.07, CFrame = CFrame.new(0, 0.05 + ry * 0.34, sz * 0.36),
					Color = light, Material = Enum.Material.Metal, Reflectance = 0.2,
				}, model)
			end
		end
	end
	-- The deep end grows its ore off the fins and carries an energy ring.
	if t > 0.62 then
		local n = 3 + math.floor((t - 0.62) * 8)
		local shardMat = (lit and Enum.Material.Glass) or mat
		for i = 1, n do
			local a = (i / n) * math.pi * 2
			shard(
				CFrame.new(math.cos(a) * 0.48, 1.0 + wob(i, 7) * 0.4, math.sin(a) * 0.48),
				0.22 + (i % 3) * 0.1, 0.1,
				CFrame.Angles(math.sin(a) * 0.9, 0, -math.cos(a) * 0.9),
				{ Color = light, Tip = lit or light:Lerp(C3(255, 255, 255), 0.3), Material = shardMat, Reflectance = refl + 0.12 },
				model
			)
		end
		cyl({
			Name = "EnergyRing", Length = 0.06, Dia = 0.7, CFrame = CFrame.new(0, 0.42, 0),
			Color = lit or light, Material = lit and Enum.Material.Neon or Enum.Material.Glass,
		}, model)
	end
	if t > 0.85 then
		for i = 0, 2 do
			cyl({
				Name = "Coil", Length = 0.04, Dia = 0.34, CFrame = CFrame.new(0, -1.3 - i * 0.2, 0),
				Color = lit or light, Material = lit and Enum.Material.Neon or Enum.Material.Glass,
			}, model)
		end
		ball({
			Name = "Gem", Dia = 0.22, CFrame = CFrame.new(0, 2.2, 0),
			Color = lit or light, Material = lit and Enum.Material.Neon or Enum.Material.Glass,
		}, model)
	end
	return body
end

--[[
	SKINS ON HAMMERS AND JACKHAMMERS.

	Owner, 2026-10-11, picked "Ore look + skins" for the hammer build: a skin
	should actually show on the tool. docs/SKINS.md gives every set one form per
	class (Toybox's hammer is a mallet, its jackhammer a pogo stick) and says
	the palette, material and trim are what make a set recognisable "at twenty
	studs" -- so those are fixed per set here, and the grade (F..SSS) only
	escalates detail: trim from B, glow and a light from S, a flourish from SS,
	sparkles at SSS.

	The ore is not thrown away: every form carries an inlay in the ore's own
	colour, so a Gold tool in a Toybox skin still says Gold.

	Each form keeps its family's Handle exactly where the plain build puts it
	(a 3.4-stud haft at y -0.35 for the hammer, a 2.6-stud body at y 0.5 for
	the jackhammer), so GRIPS and SCALE apply unchanged.
]]
local SKIN_PALETTES = {
	toybox = { main = C3(222, 52, 52), second = C3(44, 112, 232), trim = C3(255, 206, 44), glow = C3(255, 250, 220), mat = Enum.Material.SmoothPlastic, trimMat = Enum.Material.SmoothPlastic },
	cursed = { main = C3(40, 38, 44), second = C3(226, 214, 186), trim = C3(150, 18, 24), glow = C3(196, 255, 222), mat = Enum.Material.Metal, trimMat = Enum.Material.Fabric },
	pharaohs_tomb = { main = C3(240, 192, 72), second = C3(228, 214, 176), trim = C3(32, 64, 176), glow = C3(64, 228, 210), mat = Enum.Material.Foil, trimMat = Enum.Material.Marble },
	wasteland = { main = C3(142, 74, 40), second = C3(72, 98, 54), trim = C3(240, 200, 44), glow = C3(255, 150, 50), mat = Enum.Material.CorrodedMetal, trimMat = Enum.Material.Fabric },
	clockwork = { main = C3(208, 162, 74), second = C3(178, 98, 58), trim = C3(98, 60, 36), glow = C3(255, 184, 64), mat = Enum.Material.Metal, trimMat = Enum.Material.Wood },
	carnival = { main = C3(226, 42, 62), second = C3(250, 244, 236), trim = C3(240, 190, 62), glow = C3(255, 240, 180), mat = Enum.Material.SmoothPlastic, trimMat = Enum.Material.Foil },
	atomic_age = { main = C3(212, 216, 226), second = C3(236, 226, 206), trim = C3(122, 62, 42), glow = C3(92, 255, 124), mat = Enum.Material.Metal, trimMat = Enum.Material.SmoothPlastic },
	arcade = { main = C3(26, 26, 32), second = C3(232, 32, 44), trim = C3(204, 208, 218), glow = C3(44, 240, 255), mat = Enum.Material.SmoothPlastic, trimMat = Enum.Material.Metal },
	halloween = { main = C3(242, 122, 24), second = C3(112, 112, 120), trim = C3(240, 230, 202), glow = C3(124, 255, 84), mat = Enum.Material.SmoothPlastic, trimMat = Enum.Material.Slate },
}

-- A stable 0..1 from a skin id, so a skin always gets the same accent.
local function idHash(s)
	local h = 0
	for i = 1, #s do
		h = (h * 31 + string.byte(s, i)) % 100003
	end
	return h / 100003
end

-- The things every form shares: the grip wrap, the ore inlay, and the grade's
-- glow, light and sparkle.
local function skinExtras(model, at, P, rank, ore, glowAt)
	-- The ore inlay: a small gem in the ore's colour.
	ball({
		Name = "OreInlay", Dia = 0.2, CFrame = at,
		Color = ore or P.trim, Material = Enum.Material.Glass, Reflectance = 0.2,
	}, model)
	if rank >= 6 and glowAt then
		local l = Instance.new("PointLight")
		l.Color = P.glow
		l.Brightness = rank >= 8 and 2.2 or 1.4
		l.Range = rank >= 8 and 9 or 6
		l.Parent = glowAt
	end
	if rank >= 8 and glowAt then
		local e = Instance.new("ParticleEmitter")
		e.Name = "SkinSparkle"
		e.Color = ColorSequence.new(P.glow)
		e.LightEmission = 1
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(0.5, 0.9)
		e.Rate = 10
		e.Speed = NumberRange.new(0.3, 0.8)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Parent = glowAt
	end
end

-- The 3.4-stud haft every hammer form stands on (same place as buildHammer).
local function skinHaft(model, P, color, mat, dia)
	return cyl({
		Name = "Handle", Length = 3.4, Dia = dia or 0.36, CFrame = CFrame.new(0, -0.35, 0),
		Color = color, Material = mat,
	}, model)
end

-- The 2.6-stud body every jackhammer form stands on (same place as buildJackhammer).
local function skinBody(model, P, color, mat, dia)
	return cyl({
		Name = "Handle", Length = 2.6, Dia = dia or 0.62, CFrame = CFrame.new(0, 0.5, 0),
		Color = color, Material = mat,
	}, model)
end

local function glowMat(rank)
	return rank >= 6 and Enum.Material.Neon or Enum.Material.Glass
end

local SKIN_FORMS = { hammer = {}, jackhammer = {} }

---------------------------------------------------------------- Toybox --
SKIN_FORMS.hammer.toybox = function(model, P, rank, ore)
	local h = skinHaft(model, P, P.trim, P.trimMat, 0.34)
	-- Peg studs up the handle.
	for i = 0, 4 do
		ball({ Name = "Peg", Dia = 0.16, CFrame = CFrame.new(0, -1.6 + i * 0.5, 0.17), Color = (i % 2 == 0) and P.main or P.second, Material = P.mat }, model)
	end
	-- The mallet: a fat cylinder across the top, capped in the second colour.
	cyl({ Name = "Head", Length = 1.5, Dia = 0.86, CFrame = CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.main, Material = P.mat }, model)
	for _, s in ipairs({ -1, 1 }) do
		cyl({ Name = "Cap", Length = 0.16, Dia = 0.94, CFrame = CFrame.new(s * 0.78, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.second, Material = P.mat }, model)
		cyl({ Name = "Button", Length = 0.08, Dia = 0.46, CFrame = CFrame.new(s * 0.88, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.trim, Material = P.mat }, model)
	end
	-- The wind-up key on top.
	cyl({ Name = "KeyStem", Length = 0.3, Dia = 0.1, CFrame = CFrame.new(0, 2.05, 0), Color = P.trim, Material = P.trimMat }, model)
	for _, s in ipairs({ -1, 1 }) do
		box({ Name = "KeyWing", Size = Vector3.new(0.34, 0.24, 0.06), CFrame = CFrame.new(s * 0.2, 2.26, 0), Color = P.trim, Material = P.trimMat }, model)
	end
	if rank >= 4 then
		for _, s in ipairs({ -1, 1 }) do
			cyl({ Name = "Stripe", Length = 0.1, Dia = 0.9, CFrame = CFrame.new(s * 0.36, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.trim, Material = P.mat }, model)
		end
	end
	local glow = ball({ Name = "Star", Dia = 0.26, CFrame = CFrame.new(0, 1.5, 0.44), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, -2.15, 0), P, rank, ore, glow)
	return h
end

SKIN_FORMS.jackhammer.toybox = function(model, P, rank, ore)
	-- A pogo stick: pole, handlebar, foot pegs, the spring and a rubber tip.
	local h = skinBody(model, P, P.main, P.mat, 0.3)
	cyl({ Name = "Bar", Length = 1.5, Dia = 0.16, CFrame = CFrame.new(0, 1.84, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.second, Material = P.mat }, model)
	for _, s in ipairs({ -1, 1 }) do
		cyl({ Name = "Grip", Length = 0.42, Dia = 0.26, CFrame = CFrame.new(s * 0.62, 1.84, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.trim, Material = P.mat }, model)
		box({ Name = "FootPeg", Size = Vector3.new(0.5, 0.1, 0.3), CFrame = CFrame.new(s * 0.36, -0.55, 0), Color = P.second, Material = P.mat }, model)
	end
	cyl({ Name = "Housing", Length = 0.9, Dia = 0.46, CFrame = CFrame.new(0, -0.15, 0), Color = P.second, Material = P.mat }, model)
	for i = 0, 6 do
		cyl({ Name = "Spring", Length = 0.05, Dia = 0.4, CFrame = CFrame.new(0, -0.9 - i * 0.13, 0) * CFrame.Angles(math.rad(8), 0, 0), Color = P.trim, Material = Enum.Material.Metal, Reflectance = 0.2 }, model)
	end
	cyl({ Name = "Plunger", Length = 0.9, Dia = 0.16, CFrame = CFrame.new(0, -1.3, 0), Color = C3(200, 200, 206), Material = Enum.Material.Metal }, model)
	ball({ Name = "Tip", Dia = 0.34, CFrame = CFrame.new(0, -1.8, 0), Color = C3(40, 40, 44), Material = P.mat }, model)
	if rank >= 4 then
		for i = 0, 2 do
			cyl({ Name = "Band", Length = 0.06, Dia = 0.34, CFrame = CFrame.new(0, 0.8 + i * 0.3, 0), Color = P.trim, Material = P.mat }, model)
		end
	end
	local glow = ball({ Name = "Star", Dia = 0.24, CFrame = CFrame.new(0, 1.84, 0.12), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, 0.2, 0.24), P, rank, ore, glow)
	return h
end

---------------------------------------------------------------- Cursed --
SKIN_FORMS.hammer.cursed = function(model, P, rank, ore)
	local h = skinHaft(model, P, C3(52, 40, 34), Enum.Material.Wood, 0.38)
	-- Red thread wound round the grip.
	for i = 0, 6 do
		cyl({ Name = "Thread", Length = 0.06, Dia = 0.42, CFrame = CFrame.new(0, -1.9 + i * 0.18, 0) * CFrame.Angles(math.rad(12), 0, 0), Color = P.trim, Material = P.trimMat }, model)
	end
	-- The gravedigger's maul: a heavy blackened block, bone-inlaid, studded.
	box({ Name = "Head", Size = Vector3.new(1.6, 0.8, 0.78), CFrame = CFrame.new(0, 1.45, 0), Color = P.main, Material = P.mat, Reflectance = 0.05 }, model)
	for _, s in ipairs({ -1, 1 }) do
		box({ Name = "Face", Size = Vector3.new(0.12, 0.9, 0.88), CFrame = CFrame.new(s * 0.84, 1.45, 0), Color = P.main:Lerp(C3(90, 90, 96), 0.3), Material = P.mat }, model)
		box({ Name = "Bone", Size = Vector3.new(1.0, 0.1, 0.04), CFrame = CFrame.new(0, 1.45, s * 0.41), Color = P.second, Material = Enum.Material.SmoothPlastic }, model)
		for _, x in ipairs({ -0.5, 0, 0.5 }) do
			box({ Name = "Stud", Size = Vector3.new(0.12, 0.12, 0.12), CFrame = CFrame.new(x, 1.9, s * 0.24) * CFrame.Angles(0, math.rad(45), 0), Color = P.main:Lerp(C3(120, 120, 126), 0.35), Material = P.mat }, model)
		end
	end
	-- A finger-bone wedge and a wax seal.
	box({ Name = "Wedge", Size = Vector3.new(0.2, 0.1, 0.5), CFrame = CFrame.new(0, 1.9, 0), Color = P.second, Material = Enum.Material.SmoothPlastic }, model)
	cyl({ Name = "Wax", Length = 0.06, Dia = 0.3, CFrame = CFrame.new(0, 1.2, 0.42) * CFrame.Angles(math.rad(90), 0, 0), Color = P.trim, Material = Enum.Material.SmoothPlastic }, model)
	if rank >= 4 then
		for _, s in ipairs({ -1, 1 }) do
			box({ Name = "Spike", Size = Vector3.new(0.14, 0.36, 0.14), CFrame = CFrame.new(s * 0.6, 1.0, 0) * CFrame.Angles(0, 0, math.rad(s * 150)), Color = P.second, Material = Enum.Material.SmoothPlastic }, model)
		end
	end
	local glow = box({ Name = "Sigil", Size = Vector3.new(0.5, 0.06, 0.04), CFrame = CFrame.new(0, 1.62, 0.41), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, -2.15, 0), P, rank, ore, glow)
	return h
end

SKIN_FORMS.jackhammer.cursed = function(model, P, rank, ore)
	-- A great iron stake with a bone T-handle, bound in red thread.
	local h = skinBody(model, P, P.main, P.mat, 0.46)
	cyl({ Name = "Bar", Length = 1.6, Dia = 0.22, CFrame = CFrame.new(0, 1.86, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.second, Material = Enum.Material.SmoothPlastic }, model)
	for _, s in ipairs({ -1, 1 }) do
		ball({ Name = "Knuckle", Dia = 0.3, CFrame = CFrame.new(s * 0.82, 1.86, 0), Color = P.second, Material = Enum.Material.SmoothPlastic }, model)
	end
	for i = 0, 5 do
		cyl({ Name = "Thread", Length = 0.05, Dia = 0.5, CFrame = CFrame.new(0, 1.4 - i * 0.12, 0) * CFrame.Angles(math.rad(14), 0, 0), Color = P.trim, Material = P.trimMat }, model)
	end
	-- The square stake, tapering to a point.
	for i = 0, 3 do
		local w = 0.42 - i * 0.08
		box({ Name = "Stake", Size = Vector3.new(w, 0.36, w), CFrame = CFrame.new(0, -0.95 - i * 0.34, 0) * CFrame.Angles(0, math.rad(45), 0), Color = P.main:Lerp(C3(80, 76, 84), i * 0.08), Material = P.mat }, model)
	end
	box({ Name = "Point", Size = Vector3.new(0.12, 0.3, 0.12), CFrame = CFrame.new(0, -2.32, 0) * CFrame.Angles(0, math.rad(45), 0), Color = P.main, Material = P.mat }, model)
	if rank >= 4 then
		for i = 0, 1 do
			cyl({ Name = "Band", Length = 0.08, Dia = 0.52, CFrame = CFrame.new(0, 0.2 - i * 0.6, 0), Color = P.second, Material = Enum.Material.SmoothPlastic }, model)
		end
	end
	local glow = box({ Name = "Rune", Size = Vector3.new(0.06, 0.6, 0.04), CFrame = CFrame.new(0, 0.4, 0.24), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, 1.86, 0.14), P, rank, ore, glow)
	return h
end

-------------------------------------------------------- Pharaoh's Tomb --
SKIN_FORMS.hammer.pharaohs_tomb = function(model, P, rank, ore)
	-- A ceremonial flail: a gold rod banded in lapis, three beaded strands.
	local h = skinHaft(model, P, P.main, P.mat, 0.3)
	h.Reflectance = 0.25
	for i = 0, 5 do
		cyl({ Name = "Lapis", Length = 0.1, Dia = 0.36, CFrame = CFrame.new(0, -1.7 + i * 0.5, 0), Color = P.trim, Material = P.trimMat }, model)
	end
	cyl({ Name = "Crown", Length = 0.3, Dia = 0.46, CFrame = CFrame.new(0, 1.42, 0), Color = P.main, Material = P.mat, Reflectance = 0.25 }, model)
	for i = -1, 1 do
		local a = math.rad(i * 26)
		for b = 1, 6 do
			local d = 0.16 + b * 0.17
			ball({
				Name = "Bead", Dia = (b == 6) and 0.24 or 0.16,
				CFrame = CFrame.new(math.sin(a) * d, 1.55 + math.cos(a) * d * 0.25 + b * 0.04, -d * 0.3),
				Color = (b % 2 == 0) and P.trim or P.main, Material = (b % 2 == 0) and P.trimMat or P.mat, Reflectance = 0.2,
			}, model)
		end
	end
	box({ Name = "Glyphs", Size = Vector3.new(0.05, 0.5, 0.32), CFrame = CFrame.new(0, -0.6, 0), Color = P.second, Material = Enum.Material.Limestone }, model)
	if rank >= 4 then
		box({ Name = "Ankh", Size = Vector3.new(0.08, 0.36, 0.08), CFrame = CFrame.new(0, 1.82, 0), Color = P.main, Material = P.mat, Reflectance = 0.25 }, model)
		cyl({ Name = "AnkhLoop", Length = 0.06, Dia = 0.22, CFrame = CFrame.new(0, 2.06, 0) * CFrame.Angles(math.rad(90), 0, 0), Color = P.main, Material = P.mat }, model)
	end
	local glow = ball({ Name = "Scarab", Dia = 0.22, CFrame = CFrame.new(0, 1.42, 0.24), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, -2.15, 0), P, rank, ore, glow)
	return h
end

SKIN_FORMS.jackhammer.pharaohs_tomb = function(model, P, rank, ore)
	-- An obelisk driver: a limestone obelisk point-down, gold-capped and glyphed.
	local h = skinBody(model, P, P.second, Enum.Material.Limestone, 0.5)
	cyl({ Name = "Bar", Length = 1.6, Dia = 0.2, CFrame = CFrame.new(0, 1.86, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.main, Material = P.mat, Reflectance = 0.25 }, model)
	for _, s in ipairs({ -1, 1 }) do
		box({ Name = "Grip", Size = Vector3.new(0.4, 0.26, 0.26), CFrame = CFrame.new(s * 0.66, 1.86, 0), Color = P.trim, Material = P.trimMat }, model)
	end
	for i = 0, 4 do
		local w = 0.62 - i * 0.1
		box({ Name = "Obelisk", Size = Vector3.new(w, 0.42, w), CFrame = CFrame.new(0, -0.8 - i * 0.36, 0), Color = P.second, Material = Enum.Material.Limestone }, model)
		box({ Name = "Glyph", Size = Vector3.new(w * 0.5, 0.06, 0.02), CFrame = CFrame.new(0, -0.8 - i * 0.36, w * 0.5 + 0.01), Color = P.trim, Material = P.trimMat }, model)
	end
	box({ Name = "Pyramidion", Size = Vector3.new(0.14, 0.24, 0.14), CFrame = CFrame.new(0, -2.68, 0) * CFrame.Angles(0, math.rad(45), 0), Color = P.main, Material = P.mat, Reflectance = 0.3 }, model)
	cyl({ Name = "Collar", Length = 0.14, Dia = 0.7, CFrame = CFrame.new(0, -0.5, 0), Color = P.main, Material = P.mat, Reflectance = 0.25 }, model)
	if rank >= 4 then
		for i = 0, 2 do
			cyl({ Name = "Band", Length = 0.06, Dia = 0.56, CFrame = CFrame.new(0, 0.3 + i * 0.45, 0), Color = P.trim, Material = P.trimMat }, model)
		end
	end
	local glow = ball({ Name = "Eye", Dia = 0.2, CFrame = CFrame.new(0, 1.1, 0.26), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, 1.86, 0.12), P, rank, ore, glow)
	return h
end

------------------------------------------------------------- Wasteland --
SKIN_FORMS.hammer.wasteland = function(model, P, rank, ore)
	-- A sledge of welded rebar and scrap.
	local h = skinHaft(model, P, C3(110, 84, 64), Enum.Material.CorrodedMetal, 0.3)
	for i = 0, 3 do
		box({ Name = "Tarp", Size = Vector3.new(0.4, 0.3, 0.4), CFrame = CFrame.new(0, -1.8 + i * 0.26, 0) * CFrame.Angles(0, math.rad(i * 25), math.rad(8)), Color = C3(92, 112, 132), Material = Enum.Material.Fabric }, model)
	end
	box({ Name = "Head", Size = Vector3.new(1.5, 0.74, 0.74), CFrame = CFrame.new(0, 1.45, 0), Color = P.main, Material = P.mat }, model)
	box({ Name = "Plate", Size = Vector3.new(0.7, 0.5, 0.8), CFrame = CFrame.new(0.3, 1.5, 0) * CFrame.Angles(0, 0, math.rad(6)), Color = P.second, Material = Enum.Material.Metal }, model)
	box({ Name = "Paint", Size = Vector3.new(1.52, 0.1, 0.76), CFrame = CFrame.new(0, 1.3, 0), Color = P.trim, Material = Enum.Material.SmoothPlastic }, model)
	for i = 1, 4 do
		rod(Vector3.new(-0.7 + i * 0.28, 1.2, -0.3 + (i % 2) * 0.6), Vector3.new(-0.9 + i * 0.36, 1.95 + (i % 2) * 0.12, -0.2 + (i % 2) * 0.4), 0.07, { Name = "Rebar", Color = C3(96, 60, 42), Material = Enum.Material.CorrodedMetal }, model)
	end
	for _, s in ipairs({ -1, 1 }) do
		box({ Name = "Weld", Size = Vector3.new(0.06, 0.78, 0.78), CFrame = CFrame.new(s * 0.45, 1.45, 0), Color = C3(70, 66, 62), Material = Enum.Material.Metal }, model)
	end
	if rank >= 4 then
		box({ Name = "Spike", Size = Vector3.new(0.36, 0.1, 0.1), CFrame = CFrame.new(0.95, 1.45, 0), Color = C3(150, 150, 156), Material = Enum.Material.Metal }, model)
	end
	local glow = box({ Name = "Hazard", Size = Vector3.new(0.3, 0.16, 0.04), CFrame = CFrame.new(-0.3, 1.55, 0.38), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, -2.15, 0), P, rank, ore, glow)
	return h
end

SKIN_FORMS.jackhammer.wasteland = function(model, P, rank, ore)
	-- An engine piston: finned block, crank handle, jerrycan-green housing.
	local h = skinBody(model, P, P.second, Enum.Material.Metal, 0.66)
	box({ Name = "Block", Size = Vector3.new(0.86, 1.0, 0.7), CFrame = CFrame.new(0, 1.0, 0), Color = P.main, Material = P.mat }, model)
	for i = 0, 5 do
		box({ Name = "Fin", Size = Vector3.new(1.02, 0.06, 0.84), CFrame = CFrame.new(0, 0.6 + i * 0.16, 0), Color = P.main:Lerp(DARK, 0.2), Material = P.mat }, model)
	end
	cyl({ Name = "Bar", Length = 1.5, Dia = 0.18, CFrame = CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C3(120, 120, 126), Material = Enum.Material.CorrodedMetal }, model)
	for _, s in ipairs({ -1, 1 }) do
		box({ Name = "Grip", Size = Vector3.new(0.42, 0.26, 0.26), CFrame = CFrame.new(s * 0.62, 1.8, 0), Color = C3(92, 112, 132), Material = Enum.Material.Fabric }, model)
	end
	box({ Name = "Stripe", Size = Vector3.new(0.68, 0.12, 0.02), CFrame = CFrame.new(0, 0.1, 0.34), Color = P.trim, Material = Enum.Material.SmoothPlastic }, model)
	cyl({ Name = "Rod", Length = 1.0, Dia = 0.22, CFrame = CFrame.new(0, -1.2, 0), Color = C3(150, 150, 156), Material = Enum.Material.Metal, Reflectance = 0.15 }, model)
	cyl({ Name = "Piston", Length = 0.4, Dia = 0.46, CFrame = CFrame.new(0, -1.85, 0), Color = C3(170, 170, 176), Material = Enum.Material.Metal, Reflectance = 0.2 }, model)
	for i = 0, 1 do
		cyl({ Name = "Ring", Length = 0.04, Dia = 0.48, CFrame = CFrame.new(0, -1.75 - i * 0.12, 0), Color = DARK, Material = Enum.Material.Metal }, model)
	end
	if rank >= 4 then
		rod(Vector3.new(0.42, 1.2, 0), Vector3.new(0.5, -0.4, 0.2), 0.08, { Name = "Pipe", Color = C3(150, 90, 50), Material = Enum.Material.CorrodedMetal }, model)
	end
	local glow = box({ Name = "Gauge", Size = Vector3.new(0.22, 0.22, 0.04), CFrame = CFrame.new(0, 1.2, 0.37), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, 0.5, 0.34), P, rank, ore, glow)
	return h
end

------------------------------------------------------------- Clockwork --
SKIN_FORMS.hammer.clockwork = function(model, P, rank, ore)
	-- A counterweight maul: brass drum head ringed with gear teeth.
	local h = skinHaft(model, P, P.trim, P.trimMat, 0.34)
	cyl({ Name = "Ferrule", Length = 0.12, Dia = 0.42, CFrame = CFrame.new(0, 1.0, 0), Color = P.main, Material = P.mat, Reflectance = 0.2 }, model)
	cyl({ Name = "Head", Length = 1.4, Dia = 0.8, CFrame = CFrame.new(0, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.main, Material = P.mat, Reflectance = 0.25 }, model)
	for _, s in ipairs({ -1, 1 }) do
		cyl({ Name = "Face", Length = 0.12, Dia = 0.9, CFrame = CFrame.new(s * 0.72, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.second, Material = Enum.Material.Metal, Reflectance = 0.15 }, model)
	end
	-- Gear teeth round the middle.
	for i = 0, 11 do
		local a = i * math.pi / 6
		box({ Name = "Tooth", Size = Vector3.new(0.16, 0.12, 0.12), CFrame = CFrame.new(0, 1.45, 0) * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0.46, 0), Color = P.main:Lerp(C3(255, 255, 255), 0.15), Material = P.mat, Reflectance = 0.25 }, model)
	end
	-- The counterweight: a brass ball hung below the head.
	ball({ Name = "Weight", Dia = 0.34, CFrame = CFrame.new(0.5, 0.9, 0), Color = P.second, Material = Enum.Material.Metal, Reflectance = 0.15 }, model)
	rod(Vector3.new(0.5, 1.08, 0), Vector3.new(0.5, 1.4, 0), 0.04, { Name = "Chain", Color = P.main, Material = Enum.Material.Metal }, model)
	if rank >= 4 then
		cyl({ Name = "Gear", Length = 0.06, Dia = 0.5, CFrame = CFrame.new(0, 1.45, 0.44) * CFrame.Angles(math.rad(90), 0, 0), Color = P.second, Material = Enum.Material.Metal, Reflectance = 0.2 }, model)
	end
	local glow = cyl({ Name = "Gauge", Length = 0.04, Dia = 0.3, CFrame = CFrame.new(0, 1.45, -0.42) * CFrame.Angles(math.rad(90), 0, 0), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, -2.15, 0), P, rank, ore, glow)
	return h
end

SKIN_FORMS.jackhammer.clockwork = function(model, P, rank, ore)
	-- A piston hammer: brass cylinder, exposed gears, walnut grips, a gauge.
	local h = skinBody(model, P, P.main, P.mat, 0.6)
	h.Reflectance = 0.2
	cyl({ Name = "Bar", Length = 1.6, Dia = 0.18, CFrame = CFrame.new(0, 1.86, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.second, Material = Enum.Material.Metal, Reflectance = 0.15 }, model)
	for _, s in ipairs({ -1, 1 }) do
		cyl({ Name = "Grip", Length = 0.48, Dia = 0.28, CFrame = CFrame.new(s * 0.64, 1.86, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.trim, Material = P.trimMat }, model)
	end
	cyl({ Name = "Cylinder", Length = 1.1, Dia = 0.84, CFrame = CFrame.new(0, 1.1, 0), Color = P.second, Material = Enum.Material.Metal, Reflectance = 0.15 }, model)
	for i = 0, 2 do
		cyl({ Name = "Band", Length = 0.08, Dia = 0.9, CFrame = CFrame.new(0, 0.7 + i * 0.4, 0), Color = P.main, Material = P.mat, Reflectance = 0.25 }, model)
	end
	-- Two gears on the side.
	for _, g in ipairs({ { 0.48, 0.9, 0.42 }, { 0.48, 1.36, 0.28 } }) do
		cyl({ Name = "Gear", Length = 0.06, Dia = g[3], CFrame = CFrame.new(g[1], g[2], 0) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(90), 0, 0), Color = P.main, Material = P.mat, Reflectance = 0.25 }, model)
		for i = 0, 7 do
			local a = i * math.pi / 4
			box({ Name = "Tooth", Size = Vector3.new(0.06, 0.08, 0.08), CFrame = CFrame.new(g[1] + 0.02, g[2] + math.cos(a) * g[3] * 0.55, math.sin(a) * g[3] * 0.55), Color = P.main, Material = P.mat }, model)
		end
	end
	cyl({ Name = "Collar", Length = 0.16, Dia = 0.5, CFrame = CFrame.new(0, -0.9, 0), Color = P.second, Material = Enum.Material.Metal }, model)
	cyl({ Name = "Shank", Length = 1.0, Dia = 0.26, CFrame = CFrame.new(0, -1.5, 0), Color = C3(170, 170, 176), Material = Enum.Material.Metal, Reflectance = 0.2 }, model)
	box({ Name = "Blade", Size = Vector3.new(0.32, 0.4, 0.12), CFrame = CFrame.new(0, -2.2, 0), Color = C3(190, 190, 196), Material = Enum.Material.Metal, Reflectance = 0.25 }, model)
	if rank >= 4 then
		rod(Vector3.new(-0.42, 1.5, 0), Vector3.new(-0.38, 0.2, 0.2), 0.07, { Name = "Pipe", Color = P.second, Material = Enum.Material.Metal }, model)
	end
	local glow = cyl({ Name = "Gauge", Length = 0.04, Dia = 0.32, CFrame = CFrame.new(0, 1.1, 0.43) * CFrame.Angles(math.rad(90), 0, 0), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, 1.86, 0.12), P, rank, ore, glow)
	return h
end

-------------------------------------------------------------- Carnival --
SKIN_FORMS.hammer.carnival = function(model, P, rank, ore)
	-- The strongman mallet: a huge striped barrel head on a gold-banded haft.
	local h = skinHaft(model, P, C3(196, 150, 96), Enum.Material.Wood, 0.36)
	for i = 0, 3 do
		cyl({ Name = "Band", Length = 0.08, Dia = 0.4, CFrame = CFrame.new(0, -1.5 + i * 0.7, 0), Color = P.trim, Material = P.trimMat, Reflectance = 0.2 }, model)
	end
	for i = 0, 6 do
		cyl({
			Name = "Stripe", Length = 0.25, Dia = 1.06,
			CFrame = CFrame.new(-0.75 + i * 0.25, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = (i % 2 == 0) and P.main or P.second, Material = P.mat,
		}, model)
	end
	for _, s in ipairs({ -1, 1 }) do
		cyl({ Name = "Rim", Length = 0.08, Dia = 1.12, CFrame = CFrame.new(s * 0.9, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.trim, Material = P.trimMat, Reflectance = 0.2 }, model)
	end
	if rank >= 4 then
		for i = 0, 5 do
			local a = i * math.pi / 3
			ball({ Name = "Bulb", Dia = 0.12, CFrame = CFrame.new(0, 1.5 + math.cos(a) * 0.55, math.sin(a) * 0.55), Color = P.glow, Material = glowMat(rank) }, model)
		end
	end
	local glow = ball({ Name = "Star", Dia = 0.24, CFrame = CFrame.new(0.95, 1.5, 0), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, -2.15, 0), P, rank, ore, glow)
	return h
end

SKIN_FORMS.jackhammer.carnival = function(model, P, rank, ore)
	-- A carousel pole: candy-striped and gold-crowned, finial down.
	local h = skinBody(model, P, P.trim, P.trimMat, 0.3)
	for i = 0, 13 do
		cyl({
			Name = "Stripe", Length = 0.2, Dia = 0.34,
			CFrame = CFrame.new(0, -0.8 + i * 0.19, 0) * CFrame.Angles(math.rad(18), 0, 0),
			Color = (i % 2 == 0) and P.main or P.second, Material = P.mat,
		}, model)
	end
	cyl({ Name = "Crown", Length = 0.3, Dia = 0.6, CFrame = CFrame.new(0, 1.86, 0), Color = P.trim, Material = P.trimMat, Reflectance = 0.25 }, model)
	for i = 0, 5 do
		local a = i * math.pi / 3
		box({ Name = "Point", Size = Vector3.new(0.1, 0.24, 0.1), CFrame = CFrame.new(math.cos(a) * 0.26, 2.1, math.sin(a) * 0.26), Color = P.trim, Material = P.trimMat }, model)
	end
	cyl({ Name = "Bar", Length = 1.4, Dia = 0.16, CFrame = CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.trim, Material = P.trimMat }, model)
	for _, s in ipairs({ -1, 1 }) do
		ball({ Name = "Knob", Dia = 0.26, CFrame = CFrame.new(s * 0.72, 1.6, 0), Color = P.main, Material = P.mat }, model)
	end
	cyl({ Name = "Collar", Length = 0.14, Dia = 0.46, CFrame = CFrame.new(0, -0.95, 0), Color = P.trim, Material = P.trimMat }, model)
	ball({ Name = "Finial", Dia = 0.36, CFrame = CFrame.new(0, -1.25, 0), Color = P.trim, Material = P.trimMat, Reflectance = 0.25 }, model)
	box({ Name = "Spike", Size = Vector3.new(0.14, 0.7, 0.14), CFrame = CFrame.new(0, -1.75, 0) * CFrame.Angles(0, math.rad(45), 0), Color = P.trim, Material = P.trimMat }, model)
	if rank >= 4 then
		for i = 0, 7 do
			local a = i * math.pi / 4
			ball({ Name = "Bulb", Dia = 0.1, CFrame = CFrame.new(math.cos(a) * 0.32, 1.7, math.sin(a) * 0.32), Color = P.glow, Material = glowMat(rank) }, model)
		end
	end
	local glow = ball({ Name = "Jewel", Dia = 0.2, CFrame = CFrame.new(0, 1.86, 0.3), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, -1.25, 0.18), P, rank, ore, glow)
	return h
end

------------------------------------------------------------ Atomic Age --
SKIN_FORMS.hammer.atomic_age = function(model, P, rank, ore)
	-- The impact mallet: a chrome rocket head with tailfins, bakelite grip.
	local h = skinHaft(model, P, P.main, P.mat, 0.32)
	h.Reflectance = 0.35
	for i = 0, 4 do
		cyl({ Name = "Bakelite", Length = 0.18, Dia = 0.4, CFrame = CFrame.new(0, -1.85 + i * 0.2, 0), Color = P.trim, Material = P.trimMat }, model)
	end
	cyl({ Name = "Head", Length = 1.2, Dia = 0.66, CFrame = CFrame.new(0, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.main, Material = P.mat, Reflectance = 0.4 }, model)
	ball({ Name = "Nose", Dia = 0.66, CFrame = CFrame.new(0.6, 1.45, 0), Color = P.main, Material = P.mat, Reflectance = 0.4 }, model)
	cyl({ Name = "Face", Length = 0.14, Dia = 0.74, CFrame = CFrame.new(-0.64, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.second, Material = P.trimMat }, model)
	for i = 0, 2 do
		local a = i * math.pi * 2 / 3
		box({ Name = "Tailfin", Size = Vector3.new(0.4, 0.06, 0.3), CFrame = CFrame.new(-0.5, 1.45, 0) * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0, 0.42), Color = P.trim, Material = P.trimMat }, model)
	end
	if rank >= 4 then
		for i = 0, 1 do
			cyl({ Name = "Ring", Length = 0.06, Dia = 0.72, CFrame = CFrame.new(-0.1 + i * 0.3, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.glow, Material = glowMat(rank) }, model)
		end
	end
	local glow = ball({ Name = "Isotope", Dia = 0.24, CFrame = CFrame.new(0.1, 1.45, 0.32), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, -2.15, 0), P, rank, ore, glow)
	return h
end

SKIN_FORMS.jackhammer.atomic_age = function(model, P, rank, ore)
	-- A reactor driver: chrome body, glowing isotope window, bakelite handles.
	local h = skinBody(model, P, P.main, P.mat, 0.6)
	h.Reflectance = 0.35
	cyl({ Name = "Bar", Length = 1.6, Dia = 0.18, CFrame = CFrame.new(0, 1.86, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.main, Material = P.mat, Reflectance = 0.35 }, model)
	for _, s in ipairs({ -1, 1 }) do
		cyl({ Name = "Grip", Length = 0.46, Dia = 0.3, CFrame = CFrame.new(s * 0.64, 1.86, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.trim, Material = P.trimMat }, model)
		box({ Name = "Tailfin", Size = Vector3.new(0.06, 0.7, 0.4), CFrame = CFrame.new(s * 0.36, 1.3, -0.1) * CFrame.Angles(0, 0, math.rad(s * -14)), Color = P.second, Material = P.trimMat }, model)
	end
	cyl({ Name = "Core", Length = 0.9, Dia = 0.84, CFrame = CFrame.new(0, 1.0, 0), Color = P.main, Material = P.mat, Reflectance = 0.4 }, model)
	local glow = box({ Name = "Window", Size = Vector3.new(0.34, 0.6, 0.06), CFrame = CFrame.new(0, 1.0, 0.42), Color = P.glow, Material = glowMat(math.max(rank, 6)) }, model)
	for i = 0, 2 do
		cyl({ Name = "RayRing", Length = 0.06, Dia = 0.7, CFrame = CFrame.new(0, 0.1 - i * 0.25, 0), Color = P.second, Material = P.trimMat }, model)
	end
	cyl({ Name = "Emitter", Length = 0.8, Dia = 0.3, CFrame = CFrame.new(0, -1.4, 0), Color = P.main, Material = P.mat, Reflectance = 0.4 }, model)
	ball({ Name = "Tip", Dia = 0.34, CFrame = CFrame.new(0, -1.85, 0), Color = P.glow, Material = glowMat(rank) }, model)
	if rank >= 4 then
		for i = 0, 2 do
			cyl({ Name = "Coil", Length = 0.04, Dia = 0.4, CFrame = CFrame.new(0, -1.2 - i * 0.2, 0), Color = P.glow, Material = glowMat(rank) }, model)
		end
	end
	skinExtras(model, CFrame.new(0, 1.86, 0.12), P, rank, ore, glow)
	return h
end

---------------------------------------------------------------- Arcade --
SKIN_FORMS.hammer.arcade = function(model, P, rank, ore)
	-- The mallet off a whack-a-mole: foam head, neon trim, a chrome coin plate.
	local h = skinHaft(model, P, P.second, P.mat, 0.32)
	for i = 0, 3 do
		cyl({ Name = "Grip", Length = 0.12, Dia = 0.38, CFrame = CFrame.new(0, -1.85 + i * 0.16, 0), Color = P.main, Material = P.mat }, model)
	end
	cyl({ Name = "Head", Length = 1.3, Dia = 0.9, CFrame = CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.main, Material = P.mat }, model)
	for _, s in ipairs({ -1, 1 }) do
		cyl({ Name = "Face", Length = 0.1, Dia = 0.94, CFrame = CFrame.new(s * 0.68, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.second, Material = P.mat }, model)
		cyl({ Name = "Neon", Length = 0.05, Dia = 0.98, CFrame = CFrame.new(s * 0.56, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = (s > 0) and P.glow or C3(255, 54, 200), Material = Enum.Material.Neon }, model)
	end
	box({ Name = "CoinPlate", Size = Vector3.new(0.5, 0.3, 0.04), CFrame = CFrame.new(0, 1.5, 0.46), Color = P.trim, Material = P.trimMat, Reflectance = 0.3 }, model)
	box({ Name = "Slot", Size = Vector3.new(0.04, 0.18, 0.02), CFrame = CFrame.new(0, 1.5, 0.49), Color = DARK, Material = P.mat }, model)
	if rank >= 4 then
		for i = 0, 3 do
			box({ Name = "Pixel", Size = Vector3.new(0.14, 0.14, 0.14), CFrame = CFrame.new(-0.3 + i * 0.2, 2.0 + (i % 2) * 0.14, 0), Color = (i % 2 == 0) and P.glow or P.second, Material = Enum.Material.Neon }, model)
		end
	end
	local glow = ball({ Name = "Light", Dia = 0.2, CFrame = CFrame.new(0, 1.95, 0), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, -2.15, 0), P, rank, ore, glow)
	return h
end

SKIN_FORMS.jackhammer.arcade = function(model, P, rank, ore)
	-- A joystick on a pole: red ball top, neon base, chrome coin plate.
	local h = skinBody(model, P, P.main, P.mat, 0.4)
	box({ Name = "Base", Size = Vector3.new(0.8, 0.3, 0.8), CFrame = CFrame.new(0, 1.55, 0), Color = P.main, Material = P.mat }, model)
	box({ Name = "NeonEdge", Size = Vector3.new(0.84, 0.05, 0.84), CFrame = CFrame.new(0, 1.42, 0), Color = P.glow, Material = Enum.Material.Neon }, model)
	cyl({ Name = "Stick", Length = 0.5, Dia = 0.12, CFrame = CFrame.new(0, 1.92, 0), Color = P.trim, Material = P.trimMat, Reflectance = 0.3 }, model)
	ball({ Name = "Knob", Dia = 0.52, CFrame = CFrame.new(0, 2.24, 0), Color = P.second, Material = P.mat }, model)
	for _, s in ipairs({ -1, 1 }) do
		cyl({ Name = "Button", Length = 0.06, Dia = 0.18, CFrame = CFrame.new(s * 0.24, 1.72, 0.2), Color = (s > 0) and P.glow or C3(255, 54, 200), Material = Enum.Material.Neon }, model)
	end
	box({ Name = "CoinPlate", Size = Vector3.new(0.4, 0.5, 0.04), CFrame = CFrame.new(0, 0.6, 0.22), Color = P.trim, Material = P.trimMat, Reflectance = 0.3 }, model)
	box({ Name = "Slot", Size = Vector3.new(0.04, 0.24, 0.02), CFrame = CFrame.new(0, 0.6, 0.25), Color = DARK, Material = P.mat }, model)
	-- A stepped, pixel-edged tip.
	for i = 0, 3 do
		local w = 0.36 - i * 0.08
		box({ Name = "PixelTip", Size = Vector3.new(w, 0.18, w), CFrame = CFrame.new(0, -0.9 - i * 0.18, 0), Color = (i % 2 == 0) and P.main or P.glow, Material = (i % 2 == 0) and P.mat or Enum.Material.Neon }, model)
	end
	if rank >= 4 then
		for i = 0, 2 do
			box({ Name = "Scanline", Size = Vector3.new(0.42, 0.03, 0.42), CFrame = CFrame.new(0, 0.1 + i * 0.25, 0), Color = P.glow, Material = Enum.Material.Neon }, model)
		end
	end
	local glow = ball({ Name = "Light", Dia = 0.16, CFrame = CFrame.new(0, 2.5, 0), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, 1.55, 0.42), P, rank, ore, glow)
	return h
end

------------------------------------------------------------- Halloween --
SKIN_FORMS.hammer.halloween = function(model, P, rank, ore)
	-- A gravedigger's spade: D-grip, grave-grey blade, a pumpkin on the collar.
	local h = skinHaft(model, P, C3(84, 62, 44), Enum.Material.Wood, 0.32)
	box({ Name = "DGrip", Size = Vector3.new(0.6, 0.1, 0.14), CFrame = CFrame.new(0, -2.25, 0), Color = C3(84, 62, 44), Material = Enum.Material.Wood }, model)
	for _, s in ipairs({ -1, 1 }) do
		box({ Name = "DSide", Size = Vector3.new(0.1, 0.34, 0.14), CFrame = CFrame.new(s * 0.26, -2.1, 0), Color = C3(84, 62, 44), Material = Enum.Material.Wood }, model)
	end
	box({ Name = "Blade", Size = Vector3.new(0.9, 1.0, 0.08), CFrame = CFrame.new(0, 1.85, 0), Color = P.second, Material = P.trimMat }, model)
	box({ Name = "BladeTip", Size = Vector3.new(0.62, 0.26, 0.08), CFrame = CFrame.new(0, 2.45, 0), Color = P.second, Material = P.trimMat }, model)
	box({ Name = "Socket", Size = Vector3.new(0.3, 0.36, 0.2), CFrame = CFrame.new(0, 1.28, 0), Color = P.second:Lerp(DARK, 0.3), Material = P.trimMat }, model)
	ball({ Name = "Pumpkin", Dia = 0.42, CFrame = CFrame.new(0, 1.1, 0.16), Color = P.main, Material = P.mat }, model)
	box({ Name = "Stem", Size = Vector3.new(0.06, 0.12, 0.06), CFrame = CFrame.new(0, 1.34, 0.16), Color = C3(60, 110, 40), Material = P.mat }, model)
	-- Candle wax dripping off the blade's shoulder, and a cobweb strand.
	for i = 0, 2 do
		box({ Name = "Wax", Size = Vector3.new(0.08, 0.2 + i * 0.08, 0.04), CFrame = CFrame.new(-0.35 + i * 0.12, 1.4 - i * 0.04, 0.05), Color = P.trim, Material = Enum.Material.SmoothPlastic }, model)
	end
	if rank >= 4 then
		rod(Vector3.new(-0.44, 2.3, 0.05), Vector3.new(0.44, 1.5, 0.05), 0.02, { Name = "Cobweb", Color = C3(236, 236, 240), Material = Enum.Material.SmoothPlastic }, model)
	end
	local glow = box({ Name = "Face", Size = Vector3.new(0.2, 0.06, 0.04), CFrame = CFrame.new(0, 1.08, 0.37), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, -1.9, 0.18), P, rank, ore, glow)
	return h
end

SKIN_FORMS.jackhammer.halloween = function(model, P, rank, ore)
	-- A coffin nail: a huge square nail, wax-dripped, glowing at the point.
	local h = skinBody(model, P, P.second, P.trimMat, 0.44)
	box({ Name = "NailHead", Size = Vector3.new(0.9, 0.2, 0.9), CFrame = CFrame.new(0, 1.86, 0), Color = P.second:Lerp(DARK, 0.2), Material = P.trimMat }, model)
	cyl({ Name = "Bar", Length = 1.5, Dia = 0.18, CFrame = CFrame.new(0, 2.06, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C3(84, 62, 44), Material = Enum.Material.Wood }, model)
	for _, s in ipairs({ -1, 1 }) do
		ball({ Name = "Pumpkin", Dia = 0.34, CFrame = CFrame.new(s * 0.78, 2.06, 0), Color = P.main, Material = P.mat }, model)
	end
	for i = 0, 3 do
		local w = 0.4 - i * 0.07
		box({ Name = "Shank", Size = Vector3.new(w, 0.4, w), CFrame = CFrame.new(0, -0.95 - i * 0.38, 0), Color = P.second, Material = P.trimMat }, model)
	end
	box({ Name = "Point", Size = Vector3.new(0.1, 0.34, 0.1), CFrame = CFrame.new(0, -2.42, 0) * CFrame.Angles(0, math.rad(45), 0), Color = P.glow, Material = glowMat(rank) }, model)
	for i = 0, 3 do
		box({ Name = "Wax", Size = Vector3.new(0.08, 0.18 + (i % 2) * 0.14, 0.06), CFrame = CFrame.new(-0.3 + i * 0.2, 1.62 - (i % 2) * 0.07, 0.42), Color = P.trim, Material = Enum.Material.SmoothPlastic }, model)
	end
	cyl({ Name = "Band", Length = 0.12, Dia = 0.5, CFrame = CFrame.new(0, 0.6, 0), Color = P.main, Material = P.mat }, model)
	if rank >= 4 then
		rod(Vector3.new(-0.22, 1.2, 0.24), Vector3.new(0.22, -0.2, 0.24), 0.02, { Name = "Cobweb", Color = C3(236, 236, 240), Material = Enum.Material.SmoothPlastic }, model)
	end
	local glow = box({ Name = "Rune", Size = Vector3.new(0.06, 0.5, 0.04), CFrame = CFrame.new(0, 0.1, 0.23), Color = P.glow, Material = glowMat(rank) }, model)
	skinExtras(model, CFrame.new(0, 1.86, 0.46), P, rank, ore, glow)
	return h
end

local BUILDERS = {
	pickaxe = buildPickaxe, drill = buildDrill, explosive = buildExplosive,
	hammer = buildHammer, jackhammer = buildJackhammer,
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
	-- Hammer: hafted like the pickaxe, gripped a little lower because the haft
	-- is longer and it is swung with two hands.
	hammer = (HAFT_UP * CFrame.Angles(0, 0, math.rad(12)) * CFrame.new(0.95, 0, 0)):Inverse(),
	-- Machines are authored with the grip up +Y and the working end down -Z,
	-- which is already how an identity grip lands them: up is up, forward is
	-- forward. They only need settling into the palm.
	drill = CFrame.new(0, -0.25, 0.2),
	-- The jackhammer is authored UPRIGHT with the chisel at the bottom, so it
	-- is held like a haft rather than aimed like a machine: stood up, leaned
	-- back a touch, hand on the crossbar.
	jackhammer = (HAFT_UP * CFrame.Angles(0, 0, math.rad(-8)) * CFrame.new(-0.9, 0, 0)):Inverse(),
}

-- Each family is authored at whatever proportions read best on its own, then
-- brought to a common held size here. A drill drawn to look like a drill comes
-- out over five studs long, which on a character is a lance; one knob per
-- family beats re-tuning thirty literals every time the shape changes.
--
-- Target: a held tool reads at roughly 3.5 studs against a 5-stud character,
-- with the pickaxe deliberately larger because it is the two-handed one.
local SCALE = { pickaxe = 1.28, drill = 0.68, explosive = 0.74, hammer = 1.2, jackhammer = 0.86 }

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

	--[[
		A FOLDER IS NOT A MODEL. REFUSE ONE THAT HOLDS NO GEOMETRY.

		Every tool here is a MeshPart whose geometry came from
		AssetService:CreateMeshPartAsync, and that geometry is SESSION-ONLY: it
		does not survive the place being saved and reopened. What comes back is
		the full folder -- right names, right sizes, right finish variants, the
		HeadTris attribute still sitting there reading 20000 -- and MeshContent
		set to Content{SourceType=None}. A mesh with nothing in it.

		That is the state the archive in this place is in: measured, 2,058 of
		2,088 folders are entirely hollow, INCLUDING all 82 named after an ore.

		It matters here more than anywhere else because of the ORDER givePickaxe
		tries things. fromNamed runs FIRST, on the ore's own name, and only falls
		through to build() when it returns nil. A hollow folder made it return a
		perfectly well-formed model instead, so the fallback never ran and the
		player equipped a tool they could not see -- the exact symptom, and the
		reason the ore tinting below never reached anyone's hands.

		Checking the mesh rather than the folder, because the folder looks fine.
	]]
	do
		local renderable = false
		for _, d in ipairs(srcModel:GetDescendants()) do
			if d:IsA("MeshPart") then
				if not string.find(tostring(d.MeshContent), "SourceType=None", 1, true) then
					renderable = true
					break
				end
			elseif d:IsA("BasePart") then
				-- A part-built model has real geometry by definition.
				renderable = true
				break
			end
		end
		if not renderable then
			return nil
		end
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
	if family ~= "drill" and family ~= "explosive" and family ~= "hammer" then
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

--[[
	`look` is applied to the CLONE, never to the source MeshPart.

	ToolKitMeshes is a shared folder under ReplicatedStorage and every tool in
	the game clones out of it, so tinting `body` instead of `handle` would
	repaint that shape for every player holding it -- and persist, because the
	folder is replicated once and never restored.
]]
local function tryToolKitMesh(family, tier, count, look)
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
	--[[
		SPREAD THE SHAPES OVER THE LADDER, NOT OVER ALL BUT THE LAST RUNG.

		This read `floor(t * (#shapes - 1)) + 1`, which divides the ladder into
		#shapes - 1 bands and reaches the final shape only when t is EXACTLY 1 --
		tier 82 and nothing else. Measured across the 82 ores: the last silhouette
		in every family went to a single ore (Frack 1, Cluster 1, TrenchShovel 1)
		while the five below it carried about sixteen each.

		That is backwards for the rung players care most about. The endgame tools
		are meant to look like endgame tools, and instead eighty-one of eighty-two
		ores stopped one shape short of the best one in the set.

		Dividing by #shapes gives every shape an equal slice of the ladder, with
		the top slice running from t = (#shapes-1)/#shapes to 1 like all the rest.
		min() rather than clamp() on the upper end because t = 1 would otherwise
		index one past the last shape.
	]]
	local si = math.min(math.floor(t * #shapes) + 1, #shapes)
	-- body rarity advances inside each shape band
	local band = 1 / #shapes
	local localT = math.clamp((t - (si - 1) * band) / band, 0, 1)
	local bi = math.clamp(math.floor(localT * (#KIT_BODY_NAMES - 1) + 0.5) + 1, 1, #KIT_BODY_NAMES)
	local toolFolder = famFolder:FindFirstChild(shapes[si])
	if not toolFolder then return nil end
	local body = toolFolder:FindFirstChild(KIT_BODY_NAMES[bi]) or toolFolder:FindFirstChild("FieldScrap")
	if not (body and body:IsA("MeshPart")) then return nil end

	--[[
		A MeshPart WITH NO MESH IN IT IS NOT A TOOL.

		Every one of these 102 kit meshes was produced by
		AssetService:CreateMeshPartAsync in ToolKitProceduralBake and then saved
		to .rbxm. That round trip does not keep the geometry: CreateMeshPartAsync
		builds the mesh in the running session only, there is no uploaded asset
		behind it, so what the .rbxm stores is a MeshPart with the right Size and
		MeshId = "". Measured in the live place: 102 of 102 hollow.

		This branch returns before the procedural builders below ever run, so a
		hollow kit mesh is not a degraded tool -- it is an INVISIBLE one. The
		player equips a Tool, the Handle is there, the swing works, the damage
		lands, and there is nothing in their hand. Every mesh archive in this
		place is in the same state (ToolModels_50 2,058 of 2,088, the
		_Unreferenced copy 2,060 of 2,060), so there is currently no mesh
		anywhere that can draw a tool.

		Refusing it falls through to buildPickaxe/buildDrill/buildExplosive,
		which assemble real Parts -- geometry that lives in the instance and
		cannot be stripped by a save -- and which take `look`, so the tool is
		ore-coloured on the way out.

		Checked per call rather than once: the folder is replicated and a later
		bake can fill these in, and when it does this check simply stops firing.
	]]
	if string.find(tostring(body.MeshContent), "SourceType=None", 1, true) then
		return nil
	end
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

	--[[
		THE ORE, NOT THE KIT BODY.

		Without this the kit mesh keeps the colour ToolKitProceduralBake baked
		into it -- FieldScrap brown through Composite near-black, six shades
		chosen by TIER -- so every one of the 82 ores in a family came out the
		same handful of browns and greys. A Gold pickaxe and a Lead one were
		pixel-identical, and the ore the player spent the grind on was visible
		nowhere on the tool.

		`look` already carries the answer and already reaches this function's
		caller: oreLook pulls colour, material, metalness and roughness straight
		off the MineConfig.ORES row, which is the same row that colours the ore
		BLOCK -- so a Copper pick now matches the copper the player mined.

		Material carries the glow on its own. Ores that should shine resolve to
		Neon, Glass or CrackedLava in their own row, and those materials
		self-illuminate, so none of this needs a PointLight per held tool.
	]]
	if look then
		if typeof(look.metal) == "Color3" then
			handle.Color = look.metal
		end
		if typeof(look.mat) == "EnumItem" then
			handle.Material = look.mat
		end
		handle.Reflectance = math.clamp(tonumber(look.refl) or 0, 0, 1)
	end

	handle.Parent = model
	model.PrimaryPart = handle
	model:SetAttribute("KitMesh", famName .. "/" .. shapes[si] .. "/" .. (body.Name))
	model:SetAttribute("KitShape", shapes[si])
	model:SetAttribute("KitBody", body.Name)
	model:SetAttribute("OreTinted", look ~= nil)
	return model, handle, GRIPS[family] or GRIPS.pickaxe
end

--[[
	`look` is optional and comes from ToolModelFactory.oreLook: a forged tool's
	colours, material and silhouette taken from the ore it was made of rather
	than from the eight-step ramp a cosmetic lookTier indexes.

	A baked kit mesh still wins when one exists -- but it is now TINTED by the
	look rather than ignoring it.

	This comment used to end "look only overrides the PROCEDURAL build, which is
	the path every ore tool actually takes today because no mesh is named after
	an ore", and that stopped being true when ToolKitMeshes was checked in. The
	folder is complete -- three families, every shape, all six bodies -- so
	tryToolKitMesh hits on EVERY call, the procedural branch below is now
	effectively unreachable for the families that have kit meshes, and `look`
	was being dropped on the floor for every forged tool in the game.

	Nothing reported it because both paths return a perfectly good model. The
	only symptom was that all 82 ores in a family looked the same.
]]
function ToolModelFactory.build(family, tier, count, look)
	family = BUILDERS[family] and family or "pickaxe"
	count = math.max(2, count or 15)
	do
		local km, kh, kg = tryToolKitMesh(family, tier, count, look)
		if kh then return km, kh, kg end
	end
	-- The ore's own position in the roster shapes it, so a tier-1 tool is stubby
	-- and a tier-82 one is long. Without this two ore tools of different colours
	-- are the same tool.
	local t = (look and look.shapeT)
		or ((math.clamp(tier or 1, 1, count) - 1) / (count - 1))

	local model = Instance.new("Model")
	model.Name = string.format("%s_%d", family, tier or 1)
	local handle = BUILDERS[family](t, model, look)
	handle.Name = "Handle"
	-- Frostfire's fire-against-ice split (oreLook), on every family.
	applySplit(model, look and look.split)

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

--[[
	A forged tool wearing a skin (MineSkins def: id, set, tier). Only hammers
	and jackhammers have skin forms so far (SKIN_FORMS); for anything else this
	returns nil and the caller builds the plain ore tool. `look` is the ore's
	look, used for the inlay that keeps the ore visible under the skin.
]]
local SKIN_RANK = { F = 1, D = 2, C = 3, B = 4, A = 5, S = 6, SS = 7, SSS = 8 }

function ToolModelFactory.hasSkinForm(family, setKey)
	return SKIN_FORMS[family] ~= nil and SKIN_FORMS[family][setKey] ~= nil
end

function ToolModelFactory.buildSkinned(family, skin, look)
	local forms = SKIN_FORMS[family]
	local form = forms and type(skin) == "table" and forms[skin.set]
	local base = type(skin) == "table" and SKIN_PALETTES[skin.set]
	if not (form and base) then
		return nil
	end
	-- Each skin gets its own accent inside its set's palette: the set stays
	-- recognisable, and two skins of one set are not the same tool.
	local P = table.clone(base)
	P.second = base.second:Lerp(base.trim, idHash(tostring(skin.id or "")) * 0.35)
	local rank = SKIN_RANK[skin.tier] or 1

	local model = Instance.new("Model")
	model.Name = string.format("%s_skin_%s", family, tostring(skin.id))
	local handle = form(model, P, rank, look and look.metal)
	handle.Name = "Handle"

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
	model:SetAttribute("Skin", tostring(skin.id))
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
