-- PetModelFactory: one hand-built model per card. Every card in CardData gets its
-- own silhouette instead of sharing a rarity-wide template.
--
-- Conventions every model follows, because PetService and PetFollower rely on them:
--   * origin is the pet's centre, +Z is forward, models span about 2.4 studs
--   * every part is Anchored / CanCollide false / Massless, like setupPetPhysics wants
--   * PrimaryPart is an invisible "Root" at the origin, so PivotTo lands cleanly
--   * lights and particles live under an "FX" folder, because neither renders inside
--     a ViewportFrame -- the icon builder strips that folder and keeps the geometry
local PetModelFactory = {}

local C3 = Color3.fromRGB
local SMOOTH = Enum.SurfaceType.Smooth
local PLASTIC = Enum.Material.SmoothPlastic
local METAL = Enum.Material.Metal
local NEON = Enum.Material.Neon
local GLASS = Enum.Material.Glass
local SLATE = Enum.Material.Slate
local WOOD = Enum.Material.Wood

--------------------------------------------------------------------------------
-- build context
--------------------------------------------------------------------------------

local Ctx = {}
Ctx.__index = Ctx

local function lookAtSafe(from, to)
	local dir = to - from
	if dir.Magnitude < 1e-4 then
		return CFrame.new(from)
	end
	local up = Vector3.yAxis
	if math.abs(dir.Unit.Y) > 0.999 then
		up = Vector3.zAxis
	end
	return CFrame.lookAt(from, to, up)
end

function Ctx.new(model)
	return setmetatable({ model = model, count = 0 }, Ctx)
end

function Ctx:raw(class, size, cf, color, mat)
	local p = Instance.new(class)
	p.Size = size
	p.CFrame = cf or CFrame.new()
	p.Color = color or C3(255, 255, 255)
	p.Material = mat or PLASTIC
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.TopSurface = SMOOTH
	p.BottomSurface = SMOOTH
	self.count += 1
	p.Name = "P" .. self.count
	p.Parent = self.model
	self.lastPart = p
	return p
end

-- The most recently created part, for one-off tweaks at the call site.
function Ctx:last()
	return self.lastPart
end

function Ctx:box(size, cf, color, mat)
	local p = self:raw("Part", size, cf, color, mat)
	p.Shape = Enum.PartType.Block
	return p
end

function Ctx:ball(size, cf, color, mat)
	local p = self:raw("Part", size, cf, color, mat)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Part cylinders run along their local X axis.
function Ctx:cyl(size, cf, color, mat)
	local p = self:raw("Part", size, cf, color, mat)
	p.Shape = Enum.PartType.Cylinder
	return p
end

function Ctx:wedge(size, cf, color, mat)
	return self:raw("WedgePart", size, cf, color, mat)
end

local function meshed(part, meshType)
	local m = Instance.new("SpecialMesh")
	m.MeshType = meshType
	m.Parent = part
	return part
end

-- THE house shape: a hard-edged block. Pet Simulator 99 pets are cubes with
-- flat faces and crisp corners, so this is a plain Block. Every body, ear, nub
-- and tail in the roster goes through here -- swap the body of this one
-- function and the whole set restyles.
function Ctx:ovoid(size, cf, color, mat)
	return self:box(size, cf, color, mat)
end

Ctx.egg = Ctx.ovoid

-- Softened shape. Used only for eyes, so a face does not read as two rectangles
-- stuck on a crate.
function Ctx:round(size, cf, color, mat)
	return meshed(self:box(size, cf, color, mat), Enum.MeshType.Head)
end

-- Square pyramid: base at -Y, apex at +Y.
function Ctx:cone(size, cf, color, mat)
	return meshed(self:box(size, cf, color, mat), Enum.MeshType.Pyramid)
end

function Ctx:prism(size, cf, color, mat)
	return meshed(self:box(size, cf, color, mat), Enum.MeshType.Prism)
end

-- A capsule spanning two points: legs, arms, antennae, tails. `caps` rounds both
-- ends at a cost of two extra parts, so dense loops (ribs, insect legs) pass false.
function Ctx:rod(from, to, radius, color, mat, caps)
	local len = (to - from).Magnitude
	local cf = lookAtSafe((from + to) * 0.5, to) * CFrame.Angles(0, -math.pi / 2, 0)
	local p = self:cyl(Vector3.new(len, radius * 2, radius * 2), cf, color, mat)
	if caps ~= false then
		local d = radius * 2
		self:ball(Vector3.new(d, d, d), CFrame.new(from), color, mat)
		self:ball(Vector3.new(d, d, d), CFrame.new(to), color, mat)
	end
	return p
end

function Ctx:neon(size, cf, color)
	return self:ball(size, cf, color, NEON)
end

-- Cartoon eye: dark bead with an offset white glint. Sold separately per side so
-- each design can splay them however it likes.
function Ctx:eye(pos, radius, iris)
	local d = radius * 2
	local ball = self:ball(Vector3.new(d, d * 1.15, d * 0.8), CFrame.new(pos), iris or C3(18, 16, 24), PLASTIC)
	local glint = self:ball(
		Vector3.new(d * 0.36, d * 0.36, d * 0.36),
		CFrame.new(pos + Vector3.new(radius * 0.34, radius * 0.36, radius * 0.5)),
		C3(255, 255, 255),
		PLASTIC
	)
	-- Tagged so variant recolouring only lightly tints a face, keeping it readable.
	ball:SetAttribute("Eye", true)
	glint:SetAttribute("Eye", true)
end

function Ctx:eyes(y, z, spread, radius, iris)
	self:eye(Vector3.new(-spread, y, z), radius, iris)
	self:eye(Vector3.new(spread, y, z), radius, iris)
end

-- Four-point sparkle built from two crossed slivers.
function Ctx:star(pos, scale, color)
	local s = scale
	self:box(Vector3.new(s * 0.16, s, s * 0.16), CFrame.new(pos), color, NEON)
	self:box(Vector3.new(s, s * 0.16, s * 0.16), CFrame.new(pos), color, NEON)
end

-- FX host. This has to be a BasePart, not a Folder: a ParticleEmitter or
-- PointLight parented to a Folder simply never emits. Invisible, sits at the
-- model origin, and is what stripFX removes for ViewportFrame rendering.
function Ctx:fx()
	local f = self.model:FindFirstChild("FX")
	if not f then
		f = Instance.new("Part")
		f.Name = "FX"
		f.Size = Vector3.new(0.6, 0.6, 0.6)
		f.CFrame = CFrame.new()
		f.Transparency = 1
		f.Anchored = true
		f.CanCollide = false
		f.CanQuery = false
		f.CanTouch = false
		f.CastShadow = false
		f.Massless = true
		f.Parent = self.model
	end
	return f
end

function Ctx:light(color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 2
	l.Range = range or 9
	l.Shadows = false
	l.Parent = self:fx()
	return l
end

PetModelFactory.TEX = {
	sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
}

function Ctx:sparkle(color, rate, speed, size, texture)
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture or PetModelFactory.TEX.sparkle
	e.Color = typeof(color) == "ColorSequence" and color or ColorSequence.new(color)
	e.LightEmission = 0.85
	e.LightInfluence = 0
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.35, size or 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Rate = rate or 8
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(speed or 1.2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-90, 90)
	e.Parent = self:fx()
	return e
end

--------------------------------------------------------------------------------
-- PALETTES
--
-- Every species is built from one base colour. Edit TYPE_TINT to reskin a whole
-- element at once, or give a species a fixed `tint` to lock its colour.
--------------------------------------------------------------------------------

PetModelFactory.TYPE_TINT = {
	Fire = C3(255, 110, 70),
	Water = C3(70, 170, 255),
	Earth = C3(90, 190, 90),
	Rock = C3(170, 140, 100),
	Metal = C3(180, 190, 210),
	Electric = C3(255, 220, 70),
	Crystal = C3(190, 120, 255),
	Mystic = C3(255, 140, 220),
	Shadow = C3(120, 95, 175),
}

local function palette(base)
	return {
		base = base,
		dark = base:Lerp(C3(26, 22, 30), 0.42),
		deep = base:Lerp(C3(26, 22, 30), 0.68),
		light = base:Lerp(C3(255, 255, 255), 0.34),
		pale = base:Lerp(C3(255, 255, 255), 0.68),
		glow = base:Lerp(C3(255, 255, 255), 0.5),
		iris = C3(18, 16, 24),
	}
end

--------------------------------------------------------------------------------
-- VARIANTS
--
-- A variant is a post-pass over finished geometry, so it works on every species
-- for free. Add a row here and every pet in the game can roll it.
--   recolor       pull all colours toward this one, by `blend`
--   material      override the material of ordinary body parts
--   reflect       reflectance for ordinary body parts
--   transparency  body transparency
--   accentGlow    force neon parts to this colour
--   sparkle       emit this colour of particles
--   chroma        tag parts so the client can cycle their hue
--   prefixes      name ideas, see PetModelFactory.suggestName
--------------------------------------------------------------------------------

PetModelFactory.VARIANTS = {
	Normal = {
		order = 1,
		prefixes = { "Ember", "Storm", "Grove", "Iron", "Tide", "Moss", "Quartz", "Dawn", "Dusk", "Nova" },
	},
	-- Shiny is an OVERLAY, not a base. It layers on top of any other variant --
	-- Shiny Golden, Shiny Rainbow, Shiny Void -- adding polish and sparkle
	-- without overwriting the base colour. See PetModelFactory.resolveVariant.
	Shiny = {
		order = 2,
		overlay = true,
		-- Deliberately gentle. High reflectance mirrors the skybox and turns a
		-- Shiny Void into pale lavender; the sparkle and rim carry the read.
		blend = 0.05,
		recolor = C3(240, 250, 255),
		reflect = 0.16,
		sparkle = C3(226, 246, 255),
		prefixes = { "Glimmer", "Sheen", "Lustre", "Polished", "Gleam", "Brightscale" },
	},
	Golden = {
		order = 3,
		blend = 0.78,
		recolor = C3(255, 196, 64),
		material = METAL,
		reflect = 0.45,
		sparkle = C3(255, 214, 110),
		prefixes = { "Gilded", "Midas", "Bullion", "Sovereign", "Auric", "Goldcrest" },
	},
	Prism = {
		order = 4,
		blend = 0.30,
		recolor = C3(190, 225, 255),
		material = GLASS,
		reflect = 0.32,
		transparency = 0.28,
		sparkle = C3(190, 225, 255),
		prefixes = { "Prism", "Refract", "Facet", "Kaleido", "Crystalline", "Shardlight" },
	},
	Rainbow = {
		order = 5,
		blend = 0.20,
		recolor = C3(255, 240, 255),
		reflect = 0.24,
		chroma = true,
		sparkle = C3(255, 190, 255),
		prefixes = { "Chroma", "Spectra", "Aurora", "Iris", "Opaline", "Hypercolour" },
	},

	-- Halloween finishes
	Spooky = {
		order = 6,
		blend = 0.62,
		recolor = C3(96, 60, 145),
		reflect = 0.06,
		accentGlow = C3(255, 140, 40),
		sparkle = C3(150, 90, 210),
		season = "Halloween",
		prefixes = { "Haunted", "Cursed", "Wraith", "Hollow", "Grave", "Witching" },
	},
	Ember = {
		order = 7,
		blend = 0.55,
		recolor = C3(70, 34, 30),
		accentGlow = C3(255, 130, 40),
		sparkle = C3(255, 150, 60),
		season = "Halloween",
		prefixes = { "Scorched", "Cinder", "Molten", "Ashen", "Forge", "Wildfire" },
	},
	Void = {
		order = 8,
		blend = 0.82,
		recolor = C3(24, 20, 34),
		accentGlow = C3(180, 90, 255),
		sparkle = C3(170, 90, 255),
		season = "Halloween",
		prefixes = { "Void", "Umbral", "Eclipse", "Nullborn", "Abyss", "Starless" },
	},

	-- Christmas finishes
	Frostbit = {
		order = 9,
		blend = 0.66,
		recolor = C3(190, 235, 255),
		material = GLASS,
		reflect = 0.35,
		transparency = 0.12,
		accentGlow = C3(150, 220, 255),
		sparkle = C3(210, 245, 255),
		season = "Christmas",
		prefixes = { "Frosted", "Glacial", "Rime", "Hoarfrost", "Icebound", "Snowveil" },
	},
	Peppermint = {
		order = 10,
		blend = 0.70,
		recolor = C3(240, 60, 70),
		reflect = 0.16,
		accentGlow = C3(255, 250, 245),
		sparkle = C3(255, 235, 235),
		season = "Christmas",
		prefixes = { "Peppermint", "Candy", "Sugarplum", "Tinsel", "Jolly", "Cocoa" },
	},
	Tinselgold = {
		order = 11,
		blend = 0.62,
		recolor = C3(255, 226, 150),
		material = METAL,
		reflect = 0.5,
		accentGlow = C3(255, 240, 190),
		sparkle = C3(255, 240, 190),
		season = "Christmas",
		prefixes = { "Tinsel", "Starlight", "Bauble", "Yule", "Garland", "Noel" },
	},
}

--------------------------------------------------------------------------------
-- ACCESSORIES
--
-- Composable hats and trinkets. Any accessory sits on any species, which is what
-- makes the seasonal line-up cheap: Fox plus santa_hat is a new pet.
-- Each takes the anchor CFrame the species reports (head, neck or back).
--------------------------------------------------------------------------------

PetModelFactory.ACCESSORIES = {}
local ACC = PetModelFactory.ACCESSORIES

ACC.santa_hat = { slot = "head", season = "Christmas", build = function(c, head)
	local red, white = C3(210, 40, 46), C3(248, 248, 250)
	c:cone(Vector3.new(0.62, 0.80, 0.62), head * CFrame.new(0, 0.36, -0.04) * CFrame.Angles(-0.22, 0, 0.14), red)
	c:cyl(Vector3.new(0.20, 0.72, 0.72), head * CFrame.new(0, 0.07, 0.02) * CFrame.Angles(0, 0, math.pi / 2), white)
	c:ball(Vector3.new(0.26, 0.26, 0.26), head * CFrame.new(0.17, 0.70, -0.20), white)
end }

ACC.elf_hat = { slot = "head", season = "Christmas", build = function(c, head)
	local green, gold = C3(46, 150, 78), C3(240, 205, 90)
	c:cone(Vector3.new(0.60, 0.74, 0.60), head * CFrame.new(0, 0.34, -0.02) * CFrame.Angles(-0.30, 0, -0.18), green)
	c:cyl(Vector3.new(0.16, 0.68, 0.68), head * CFrame.new(0, 0.07, 0.02) * CFrame.Angles(0, 0, math.pi / 2), gold)
	c:ball(Vector3.new(0.20, 0.20, 0.20), head * CFrame.new(-0.21, 0.62, -0.18), gold, NEON)
end }

ACC.antlers = { slot = "head", season = "Christmas", build = function(c, head)
	local horn = C3(122, 88, 56)
	for _, side in ipairs({ -1, 1 }) do
		local root = (head * CFrame.new(0.24 * side, 0.10, -0.02)).Position
		local mid = root + Vector3.new(0.20 * side, 0.42, -0.06)
		local tip = mid + Vector3.new(0.24 * side, 0.34, 0.04)
		c:rod(root, mid, 0.058, horn)
		c:rod(mid, tip, 0.050, horn)
		c:rod(mid, mid + Vector3.new(0.30 * side, 0.10, -0.22), 0.044, horn)
		c:rod(root + Vector3.new(0.10 * side, 0.20, 0), root + Vector3.new(0.36 * side, 0.30, 0.20), 0.042, horn)
	end
end }

ACC.scarf = { slot = "neck", season = "Christmas", build = function(c, neck)
	local wool = C3(214, 62, 68)
	c:cyl(Vector3.new(0.24, 0.74, 0.74), neck * CFrame.Angles(0, 0, math.pi / 2), wool)
	c:box(Vector3.new(0.20, 0.48, 0.14), neck * CFrame.new(0.17, -0.32, 0.20) * CFrame.Angles(0.2, 0, 0.1), wool)
end }

ACC.candy_cane = { slot = "back", season = "Christmas", build = function(c, back)
	local red, white = C3(228, 52, 60), C3(250, 250, 250)
	local base = back * CFrame.new(0.34, 0, -0.12)
	c:rod((base * CFrame.new(0, -0.38, 0)).Position, (base * CFrame.new(0, 0.42, 0)).Position, 0.062, white)
	for i = 0, 3 do
		c:cyl(Vector3.new(0.10, 0.135, 0.135), base * CFrame.new(0, -0.30 + i * 0.20, 0) * CFrame.Angles(0, 0, math.pi / 2), red)
	end
	c:rod((base * CFrame.new(0, 0.42, 0)).Position, (base * CFrame.new(0.17, 0.56, 0)).Position, 0.062, white)
end }

ACC.witch_hat = { slot = "head", season = "Halloween", build = function(c, head)
	local cloth, band = C3(48, 34, 72), C3(150, 90, 210)
	c:cone(Vector3.new(0.56, 1.02, 0.56), head * CFrame.new(0, 0.52, -0.02) * CFrame.Angles(-0.12, 0, 0.10), cloth)
	c:cyl(Vector3.new(0.08, 1.20, 1.20), head * CFrame.new(0, 0.09, 0.02) * CFrame.Angles(0, 0, math.pi / 2), cloth)
	c:cyl(Vector3.new(0.10, 0.62, 0.62), head * CFrame.new(0, 0.21, 0.02) * CFrame.Angles(0, 0, math.pi / 2), band)
	c:star((head * CFrame.new(0.02, 0.25, 0.31)).Position, 0.24, C3(255, 210, 90))
end }

ACC.pumpkin_head = { slot = "head", season = "Halloween", build = function(c, head)
	local skin, stem, glow = C3(238, 128, 32), C3(88, 128, 54), C3(255, 170, 50)
	c:ball(Vector3.new(0.90, 0.80, 0.90), head * CFrame.new(0, 0.22, 0), skin)
	c:rod((head * CFrame.new(0, 0.54, 0)).Position, (head * CFrame.new(0.04, 0.74, -0.04)).Position, 0.06, stem)
	c:cone(Vector3.new(0.17, 0.17, 0.10), head * CFrame.new(-0.17, 0.28, 0.40) * CFrame.Angles(math.pi, 0, 0), glow, NEON)
	c:cone(Vector3.new(0.17, 0.17, 0.10), head * CFrame.new(0.17, 0.28, 0.40) * CFrame.Angles(math.pi, 0, 0), glow, NEON)
	c:box(Vector3.new(0.36, 0.10, 0.08), head * CFrame.new(0, 0.07, 0.42), glow, NEON)
	c:light(glow, 2.4, 8)
end }

ACC.bat_wings = { slot = "back", season = "Halloween", build = function(c, back)
	local skin = C3(58, 40, 78)
	for _, side in ipairs({ -1, 1 }) do
		local root = (back * CFrame.new(0.16 * side, 0.10, 0)).Position
		c:wedge(
			Vector3.new(0.08, 0.52, 0.80),
			back * CFrame.new(0.62 * side, 0.26, -0.10) * CFrame.Angles(0, side > 0 and -0.5 or 0.5, side * -0.5),
			skin
		)
		c:rod(root, root + Vector3.new(0.80 * side, 0.44, -0.16), 0.05, skin)
		c:rod(root, root + Vector3.new(0.72 * side, -0.14, -0.30), 0.045, skin)
	end
end }

ACC.halo = { slot = "head", build = function(c, head)
	local gold = C3(255, 224, 120)
	local centre = head * CFrame.new(0, 0.54, 0)
	for i = 0, 11 do
		local a = (i / 12) * math.pi * 2
		c:ball(Vector3.new(0.11, 0.07, 0.11), centre * CFrame.new(math.cos(a) * 0.42, 0, math.sin(a) * 0.42), gold, NEON)
	end
	c:light(gold, 1.6, 7)
end }

ACC.mini_crown = { slot = "head", build = function(c, head)
	local gold = C3(255, 205, 80)
	c:cyl(Vector3.new(0.16, 0.62, 0.62), head * CFrame.new(0, 0.23, 0) * CFrame.Angles(0, 0, math.pi / 2), gold, METAL)
	for i = 0, 4 do
		local a = (i / 5) * math.pi * 2
		c:cone(Vector3.new(0.13, 0.25, 0.13), head * CFrame.new(math.cos(a) * 0.26, 0.41, math.sin(a) * 0.26), gold, METAL)
	end
end }

ACC.headlamp = { slot = "head", build = function(c, head)
	local band, lens = C3(212, 176, 60), C3(255, 244, 180)
	c:cyl(Vector3.new(0.14, 0.74, 0.74), head * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.pi / 2), band)
	c:cyl(Vector3.new(0.16, 0.30, 0.30), head * CFrame.new(0, 0.21, 0.31) * CFrame.Angles(0, math.pi / 2, 0), lens, NEON)
	c:light(lens, 2.2, 10)
end }

--------------------------------------------------------------------------------
-- SPECIES
--
-- Every pet is one blocky body with a face, then the details that actually tell
-- players WHAT it is: snout shape, ear shape, tail shape, and markings. Those
-- four do almost all the identifying work -- a fox and a hound are the same cube
-- until one gets a pointed white-tipped brush and the other gets floppy ears and
-- a collar.
--
-- Each entry:
--   label   display name of the shape
--   names   name ideas, crossed with a variant prefix by suggestNames()
--   head / neck / back   anchor CFrames accessories mount onto
--   build(c, p)   c is the build context, p is the palette
--
-- Model space: origin is the pet centre, +Z is forward, about 2.4 studs tall.
--------------------------------------------------------------------------------

PetModelFactory.SPECIES = {}
local S = PetModelFactory.SPECIES

local INK = C3(22, 20, 28)
local WHITE = C3(255, 255, 255)
local NOSE = C3(32, 28, 38)
local BONE = C3(244, 240, 230)

-- The block, the face, four nubs, a tail.
--   bodySize / bodyColor / square / bodyMat
--   eyeY / eyeSpread / eyeSize / eyeColor
--   snout = { w, h, d, color, nose, y }   protruding muzzle, the big species tell
--   bib   = { w, h, color, y }            chest patch
--   brow  = color                          ridge over the eyes
--   mouth = false / mouthSize / mouthY / mouthColor
--   legs  = false / legSize / legColor / legX / legY / legZ
--   tail  = false / tailSize / tailColor
local function block(c, p, o)
	o = o or {}
	local size = o.bodySize or Vector3.new(2.02, 1.88, 1.80)
	local body = (o.square and c.box or c.ovoid)(c, size, CFrame.new(0, 0.06, 0), o.bodyColor or p.base)
	if o.bodyMat then
		body.Material = o.bodyMat
	end

	-- `fz` is the FRONT SURFACE. Face pieces push outward from it, because on a
	-- flat cube face anything centred inside the depth just disappears.
	local fz = size.Z * 0.5
	local ey, es = o.eyeY or 0.16, o.eyeSpread or 0.44
	local esz = o.eyeSize or Vector3.new(0.56, 0.68, 0.22)
	local eyeZ = fz + esz.Z * 0.5 - 0.07

	-- Chest patch first so the face sits over it.
	if o.bib then
		c:ovoid(
			Vector3.new(o.bib.w or 0.90, o.bib.h or 0.80, 0.20),
			CFrame.new(0, o.bib.y or -0.40, fz + 0.02),
			o.bib.color or p.pale
		)
	end

	for _, s in ipairs({ -1, 1 }) do
		c:round(esz, CFrame.new(es * s, ey, eyeZ), o.eyeColor or INK):SetAttribute("Eye", true)
		c:round(
			Vector3.new(esz.X * 0.34, esz.Y * 0.30, 0.12),
			CFrame.new((es - esz.X * 0.17) * s, ey + esz.Y * 0.22, eyeZ + esz.Z * 0.5 - 0.02),
			WHITE
		):SetAttribute("Eye", true)
		if o.brow then
			c:ovoid(Vector3.new(esz.X * 1.1, 0.16, 0.18), CFrame.new(es * s, ey + esz.Y * 0.62, fz + 0.03), o.brow)
		end
	end

	-- The snout: the single strongest "what animal is this" cue.
	if o.snout then
		local sn = o.snout
		local sd = sn.d or 0.46
		local sy = sn.y or -0.28
		c:ovoid(
			Vector3.new(sn.w or 0.72, sn.h or 0.52, sd),
			CFrame.new(0, sy, fz + sd * 0.5 - 0.10),
			sn.color or p.pale
		)
		c:ovoid(
			Vector3.new(0.24, 0.18, 0.16),
			CFrame.new(0, sy + (sn.h or 0.52) * 0.28, fz + sd - 0.12),
			sn.nose or NOSE
		)
	elseif o.mouth ~= false then
		local msz = o.mouthSize or Vector3.new(0.30, 0.17, 0.14)
		c:ovoid(msz, CFrame.new(0, o.mouthY or -0.36, fz + msz.Z * 0.5 - 0.05), o.mouthColor or C3(28, 25, 33))
	end

	if o.legs ~= false then
		local ls = o.legSize or Vector3.new(0.46, 0.36, 0.52)
		local lc = o.legColor or p.deep
		local zs = o.legZ or { 0.42, -0.42 }
		for _, s in ipairs({ -1, 1 }) do
			for _, z in ipairs(zs) do
				c:ovoid(ls, CFrame.new((o.legX or 0.56) * s, o.legY or -0.86, z), lc)
			end
		end
	end
	if o.tail ~= false then
		c:ovoid(o.tailSize or Vector3.new(0.36, 0.36, 0.56), CFrame.new(0, -0.26, -0.98), o.tailColor or p.deep)
	end
	return size, fz, body
end

local function ears(c, colour, kind, inner)
	for _, s in ipairs({ -1, 1 }) do
		if kind == "up" then
			c:ovoid(Vector3.new(0.44, 0.62, 0.26), CFrame.new(0.54 * s, 1.14, 0.04) * CFrame.Angles(0, 0, -0.16 * s), colour)
			if inner then
				c:ovoid(Vector3.new(0.22, 0.34, 0.16), CFrame.new(0.54 * s, 1.10, 0.14) * CFrame.Angles(0, 0, -0.16 * s), inner)
			end
		elseif kind == "down" then
			c:ovoid(Vector3.new(0.38, 0.86, 0.44), CFrame.new(1.16 * s, 0.30, 0.06) * CFrame.Angles(0, 0, -0.14 * s), colour)
			if inner then
				c:ovoid(Vector3.new(0.20, 0.52, 0.26), CFrame.new(1.28 * s, 0.30, 0.12) * CFrame.Angles(0, 0, -0.14 * s), inner)
			end
		elseif kind == "round" then
			c:ovoid(Vector3.new(0.50, 0.48, 0.28), CFrame.new(0.62 * s, 1.04, 0), colour)
			if inner then
				c:ovoid(Vector3.new(0.26, 0.26, 0.18), CFrame.new(0.62 * s, 1.04, 0.10), inner)
			end
		elseif kind == "tuft" then
			c:ovoid(Vector3.new(0.32, 0.50, 0.24), CFrame.new(0.64 * s, 1.10, 0) * CFrame.Angles(0, 0, -0.32 * s), colour)
		end
	end
end

local function wings(c, colour, span, y, z, tilt)
	for _, s in ipairs({ -1, 1 }) do
		c:ovoid(
			Vector3.new(span or 0.26, 0.72, 0.94),
			CFrame.new((1.06 * s), y or 0.10, z or -0.20) * CFrame.Angles(0, 0, -(tilt or 0.30) * s),
			colour
		)
	end
end

-- Markings. Cheap, and they do more for recognition than another limb would.
local function spots(c, colour, list, size)
	for _, v in ipairs(list) do
		c:ovoid(size or Vector3.new(0.20, 0.20, 0.16), CFrame.new(v[1], v[2], v[3]), colour)
	end
end

-- Row of plates down the spine.
local function ridge(c, colour, count, y, z, dz, w)
	for i = 1, count do
		local t = (i - 1) / math.max(1, count - 1)
		c:cone(
			Vector3.new(w or 0.30, 0.34 - t * 0.12, w or 0.30),
			CFrame.new(0, y - t * 0.34, z - (i - 1) * dz),
			colour
		)
	end
end

S.fox = {
	label = "Fox",
	names = { "Kit", "Vixen", "Reynard", "Brush", "Tod", "Emberkit", "Duskpaw", "Sly" },
	head = CFrame.new(0, 1.14, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			snout = { w = 0.62, h = 0.46, d = 0.56, color = p.pale },
			bib = { w = 0.86, h = 0.60, y = -0.62, color = p.pale },
			legColor = p.deep,
			tailSize = Vector3.new(0.62, 0.62, 0.86), tailColor = p.base,
		})
		ears(c, p.base, "up", C3(232, 168, 178))
		-- White cheek ruffs and a white-tipped brush: the fox tells.
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.26, 0.52, 0.42), CFrame.new(1.02 * s, -0.16, 0.42) * CFrame.Angles(0, 0, -0.3 * s), p.pale)
		end
		c:ovoid(Vector3.new(0.52, 0.52, 0.44), CFrame.new(0, -0.14, -1.44), p.pale)
	end,
}

S.hound = {
	label = "Hound",
	names = { "Rex", "Digger", "Bruno", "Scout", "Fang", "Rubble", "Barker", "Chomp" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			snout = { w = 0.84, h = 0.58, d = 0.50, color = p.pale },
			brow = p.dark,
			legColor = p.pale,
			tailSize = Vector3.new(0.32, 0.32, 0.52),
		})
		ears(c, p.dark, "down")
		-- Patch over one eye, collar and tag: unmistakably a dog.
		c:ovoid(Vector3.new(0.72, 0.72, 0.22), CFrame.new(-0.46, 0.22, 0.92), p.dark)
		c:cyl(Vector3.new(0.22, 1.34, 1.34), CFrame.new(0, -0.62, 0.06) * CFrame.Angles(0, 0, math.pi / 2), C3(190, 52, 58))
		c:ovoid(Vector3.new(0.28, 0.28, 0.20), CFrame.new(0, -0.84, 0.76), C3(246, 206, 84), METAL)
	end,
}

S.otter = {
	label = "Otter",
	names = { "Ripple", "Sleek", "Pebble", "Marsh", "Skipper", "Current", "Puddle", "Wader" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			snout = { w = 0.68, h = 0.44, d = 0.42, color = p.pale },
			bib = { w = 0.94, h = 0.72, y = -0.56, color = p.pale },
			legSize = Vector3.new(0.56, 0.30, 0.60), legColor = p.dark,
			tail = false,
		})
		ears(c, p.dark, "round", p.pale)
		-- Flat paddle tail and whisker dots.
		c:ovoid(Vector3.new(0.72, 0.26, 1.16), CFrame.new(0, -0.66, -1.12) * CFrame.Angles(0.18, 0, 0), p.dark)
		for _, s in ipairs({ -1, 1 }) do
			spots(c, NOSE, {
				{ 0.30 * s, -0.30, 1.06 }, { 0.34 * s, -0.44, 1.02 },
			}, Vector3.new(0.09, 0.09, 0.09))
		end
	end,
}

S.stag = {
	label = "Stag",
	names = { "Antler", "Thicket", "Monarch", "Bramble", "Fernstep", "Crownfall", "Elder", "Sable" },
	head = CFrame.new(0, 1.16, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			snout = { w = 0.62, h = 0.54, d = 0.50, color = p.dark },
			bib = { w = 0.70, h = 0.54, y = -0.58, color = p.pale },
			legSize = Vector3.new(0.34, 0.42, 0.38), legColor = C3(58, 44, 38),
			tailSize = Vector3.new(0.30, 0.34, 0.36), tailColor = p.pale,
		})
		ears(c, p.dark, "tuft")
		for _, s in ipairs({ -1, 1 }) do
			local r = Vector3.new(0.30 * s, 1.00, -0.02)
			local m = r + Vector3.new(0.22 * s, 0.54, -0.04)
			c:rod(r, m, 0.085, C3(126, 92, 58))
			c:rod(m, m + Vector3.new(0.30 * s, 0.38, 0.08), 0.072, C3(126, 92, 58))
			c:rod(m, m + Vector3.new(0.36 * s, 0.02, -0.32), 0.066, C3(126, 92, 58))
		end
		-- Dappled flank spots.
		spots(c, p.pale, {
			{ -0.72, 0.36, -0.94 }, { 0.10, 0.52, -0.96 }, { 0.72, 0.30, -0.94 },
		})
	end,
}

S.drake = {
	label = "Drake",
	scale = 1.06,
	names = { "Scale", "Cinderwing", "Ridge", "Warden", "Basalt", "Slag", "Hoard", "Grimclaw" },
	head = CFrame.new(0, 1.14, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.66),
	build = function(c, p)
		block(c, p, {
			snout = { w = 0.80, h = 0.50, d = 0.60, color = p.light, nose = p.deep },
			brow = p.deep,
			legColor = p.deep,
			tailSize = Vector3.new(0.46, 0.46, 0.76),
		})
		for _, s in ipairs({ -1, 1 }) do
			c:cone(Vector3.new(0.28, 0.56, 0.28), CFrame.new(0.46 * s, 1.16, -0.10) * CFrame.Angles(-0.28, 0, -0.22 * s), p.pale)
			-- Claws, so the feet read as a lizard's not a puppy's.
			c:cone(Vector3.new(0.12, 0.22, 0.12), CFrame.new(0.56 * s, -1.02, 0.68) * CFrame.Angles(-1.4, 0, 0), p.pale)
		end
		wings(c, p.dark, 0.26, 0.24, -0.30, 0.34)
		ridge(c, p.deep, 4, 0.98, -0.36, 0.34, 0.26)
		-- Belly scutes.
		for i = 0, 2 do
			c:ovoid(Vector3.new(0.66, 0.20, 0.16), CFrame.new(0, -0.48 - i * 0.26, 0.92), p.light)
		end
	end,
}

S.wyrm = {
	label = "Wyrm",
	names = { "Coil", "Deepdelve", "Burrow", "Gnaw", "Longtooth", "Sinker", "Corebore", "Tunnelmaw" },
	head = CFrame.new(0, 1.10, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.10, -0.70),
	build = function(c, p)
		block(c, p, {
			legs = false, tail = false, mouthSize = Vector3.new(0.86, 0.22, 0.16),
			brow = p.deep,
		})
		-- Body segments trailing back, banded light/dark.
		c:ovoid(Vector3.new(1.54, 1.42, 1.34), CFrame.new(0.18, -0.66, -1.12), p.light)
		c:ovoid(Vector3.new(1.14, 1.04, 1.00), CFrame.new(-0.16, -1.16, -1.98), p.base)
		c:ovoid(Vector3.new(0.74, 0.68, 0.66), CFrame.new(0.10, -1.46, -2.62), p.light)
		for _, s in ipairs({ -1, 1 }) do
			c:cone(Vector3.new(0.24, 0.52, 0.24), CFrame.new(0.44 * s, 1.12, -0.06) * CFrame.Angles(-0.3, 0, -0.24 * s), p.deep)
			c:cone(Vector3.new(0.14, 0.26, 0.14), CFrame.new(0.22 * s, -0.52, 0.94) * CFrame.Angles(math.pi, 0, 0), BONE)
		end
		ridge(c, p.deep, 3, 1.00, -0.44, 0.44, 0.26)
	end,
}

S.serpent = {
	label = "Serpent",
	names = { "Hiss", "Coilfang", "Venom", "Slither", "Naga", "Rattle", "Sidewind", "Basilisk" },
	head = CFrame.new(0, 1.10, 0.06),
	neck = CFrame.new(0, 0.10, 0.30),
	back = CFrame.new(0, 0.10, -0.66),
	build = function(c, p)
		block(c, p, { legs = false, tail = false, mouth = false })
		c:cyl(Vector3.new(0.62, 2.10, 2.10), CFrame.new(0, -1.24, -0.06) * CFrame.Angles(0, 0, math.pi / 2), p.light)
		c:cyl(Vector3.new(0.50, 1.48, 1.48), CFrame.new(0, -0.78, -0.10) * CFrame.Angles(0, 0, math.pi / 2), p.base)
		-- Cobra hood, fangs and a forked tongue.
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.24, 0.96, 0.94), CFrame.new(1.00 * s, 0.30, -0.06) * CFrame.Angles(0, 0, -0.34 * s), p.deep)
			c:cone(Vector3.new(0.12, 0.26, 0.12), CFrame.new(0.20 * s, -0.44, 0.92) * CFrame.Angles(math.pi, 0, 0), BONE)
		end
		c:box(Vector3.new(0.10, 0.07, 0.42), CFrame.new(0, -0.56, 1.10), C3(224, 62, 92))
		for _, s in ipairs({ -1, 1 }) do
			c:box(Vector3.new(0.08, 0.06, 0.18), CFrame.new(0.09 * s, -0.56, 1.36) * CFrame.Angles(0, 0.4 * s, 0), C3(224, 62, 92))
		end
		spots(c, p.deep, { { 0, -1.08, 0.98 }, { 0, -1.40, 0.86 } }, Vector3.new(0.44, 0.14, 0.14))
	end,
}

S.toad = {
	label = "Toad",
	names = { "Croak", "Bogwart", "Puddlejump", "Warty", "Gulp", "Marshking", "Ribbit", "Slick" },
	head = CFrame.new(0, 0.98, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.10, -0.62),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(2.16, 1.62, 1.86),
			eyeY = 0.62, eyeSpread = 0.46, mouthY = -0.30, mouthSize = Vector3.new(1.06, 0.16, 0.16),
			tail = false, legSize = Vector3.new(0.62, 0.34, 0.62), legY = -0.76, legX = 0.70,
		})
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.56, 0.50, 0.56), CFrame.new(0.46 * s, 0.82, 0.22), p.base)
		end
		-- Throat sac and warty back: amphibian, not lizard.
		c:ovoid(Vector3.new(1.06, 0.46, 0.44), CFrame.new(0, -0.56, 0.82), p.pale)
		spots(c, p.dark, {
			{ -0.62, 0.72, -0.62 }, { 0.10, 0.84, -0.80 }, { 0.66, 0.70, -0.58 }, { -0.16, 0.66, -0.30 },
		}, Vector3.new(0.26, 0.16, 0.26))
	end,
}

S.crab = {
	label = "Crab",
	names = { "Pincer", "Shale", "Clacker", "Tidepool", "Bouldershell", "Nipper", "Reefjaw", "Scuttle" },
	head = CFrame.new(0, 0.92, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(2.30, 1.52, 1.66),
			eyeY = 0.30, eyeSpread = 0.48, mouthY = -0.36, mouthSize = Vector3.new(0.62, 0.14, 0.14),
			tail = false, legSize = Vector3.new(0.30, 0.30, 0.42), legX = 0.98,
			legZ = { 0.46, 0, -0.46 },
		})
		for _, s in ipairs({ -1, 1 }) do
			-- Two-part claw so it reads as a pincer, not a mitten.
			c:ovoid(Vector3.new(0.70, 0.74, 0.84), CFrame.new(1.40 * s, 0.10, 0.54) * CFrame.Angles(0, -0.3 * s, 0), p.base)
			c:ovoid(Vector3.new(0.52, 0.30, 0.66), CFrame.new(1.46 * s, 0.42, 0.66) * CFrame.Angles(-0.35, -0.3 * s, 0), p.light)
			-- Eyestalks.
			c:ovoid(Vector3.new(0.16, 0.40, 0.16), CFrame.new(0.40 * s, 1.00, 0.30), p.dark)
			c:ovoid(Vector3.new(0.26, 0.26, 0.26), CFrame.new(0.40 * s, 1.24, 0.30), INK)
		end
		-- Shell segment lines.
		spots(c, p.deep, { { 0, 0.86, -0.30 }, { 0, 0.80, -0.62 } }, Vector3.new(1.70, 0.10, 0.16))
	end,
}

S.beetle = {
	label = "Beetle",
	names = { "Carapace", "Geode", "Scarab", "Chitin", "Lodestone", "Husk", "Dungroller", "Glimmerback" },
	head = CFrame.new(0, 1.08, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.30, -0.62),
	build = function(c, p)
		block(c, p, {
			bodyColor = p.deep, tail = false, mouthSize = Vector3.new(0.44, 0.12, 0.14),
			legSize = Vector3.new(0.28, 0.30, 0.40), legX = 0.92, legZ = { 0.44, 0, -0.44 },
		})
		-- Split elytra with a visible seam, a head horn, and antennae.
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.88, 0.90, 1.66), CFrame.new(0.48 * s, 0.42, -0.14) * CFrame.Angles(0, 0, 0.16 * s), p.base)
			c:rod(Vector3.new(0.26 * s, 0.96, 0.72), Vector3.new(0.60 * s, 1.34, 0.46), 0.055, p.dark)
			c:ovoid(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.62 * s, 1.36, 0.44), p.glow, NEON)
		end
		c:cone(Vector3.new(0.32, 0.70, 0.32), CFrame.new(0, 0.72, 0.92) * CFrame.Angles(-0.8, 0, 0), p.glow, NEON)
		c:ovoid(Vector3.new(0.14, 0.94, 1.70), CFrame.new(0, 0.62, -0.14), p.deep)
	end,
}

S.moth = {
	label = "Moth",
	names = { "Lantern", "Dustwing", "Flutter", "Lamplight", "Powder", "Silkwing", "Glowmoth", "Nightlace" },
	head = CFrame.new(0, 1.10, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, { bodyColor = p.light, legs = false, tail = false, mouth = false })
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(1.50, 0.22, 1.28), CFrame.new(1.26 * s, 0.38, -0.06) * CFrame.Angles(0, 0, s * 0.30), p.base)
			c:ovoid(Vector3.new(0.98, 0.20, 0.90), CFrame.new(1.00 * s, -0.44, -0.68) * CFrame.Angles(0, 0, s * 0.22), p.pale)
			-- Eye-spots on the forewings: the moth tell.
			c:ovoid(Vector3.new(0.42, 0.12, 0.42), CFrame.new(1.34 * s, 0.46, 0.04), p.glow, NEON)
			c:ovoid(Vector3.new(0.20, 0.12, 0.20), CFrame.new(1.34 * s, 0.48, 0.04), p.deep)
			-- Feathered antennae.
			c:rod(Vector3.new(0.24 * s, 0.98, 0.42), Vector3.new(0.60 * s, 1.38, 0.14), 0.055, p.dark)
			for f = 0, 2 do
				c:ovoid(Vector3.new(0.16, 0.06, 0.06), CFrame.new((0.36 + f * 0.11) * s, 1.10 + f * 0.12, 0.34 - f * 0.08) * CFrame.Angles(0, 0, -0.7 * s), p.dark)
			end
		end
		-- Fuzzy collar ruff.
		c:ovoid(Vector3.new(1.66, 0.44, 1.50), CFrame.new(0, 0.72, 0.02), p.pale)
		c:light(p.glow, 1.6, 9)
	end,
}

S.hawk = {
	label = "Hawk",
	names = { "Talon", "Skyward", "Screech", "Updraft", "Keeneye", "Stoop", "Windshear", "Ridgehunter" },
	head = CFrame.new(0, 1.10, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, {
			mouth = false, brow = p.dark,
			bib = { w = 0.94, h = 0.86, y = -0.44, color = p.pale },
			legColor = C3(246, 190, 64), tailSize = Vector3.new(0.92, 0.26, 0.90),
		})
		-- Hooked beak: two blocks, the lower one tucked and angled down.
		c:cone(Vector3.new(0.36, 0.42, 0.42), CFrame.new(0, -0.24, 1.04) * CFrame.Angles(1.9, 0, 0), C3(246, 190, 64))
		c:ovoid(Vector3.new(0.24, 0.24, 0.22), CFrame.new(0, -0.46, 1.06), C3(214, 156, 44))
		c:ovoid(Vector3.new(1.34, 0.24, 0.42), CFrame.new(0, 0.70, 0.96), p.dark)
		wings(c, p.dark, 0.26, 0.02, -0.16, 0.16)
		-- Breast streaks and talons.
		spots(c, p.dark, { { -0.24, -0.34, 0.98 }, { 0.24, -0.50, 0.98 }, { 0, -0.66, 0.98 } }, Vector3.new(0.14, 0.22, 0.12))
		for _, s in ipairs({ -1, 1 }) do
			for f = -1, 1 do
				c:cone(Vector3.new(0.11, 0.20, 0.11), CFrame.new(0.56 * s + f * 0.14, -1.06, 0.68) * CFrame.Angles(-1.4, f * 0.4, 0), C3(214, 156, 44))
			end
		end
	end,
}

S.owl = {
	label = "Owl",
	names = { "Hoot", "Nightwatch", "Sage", "Tuft", "Moonstare", "Barnlight", "Wisdom", "Silentwing" },
	head = CFrame.new(0, 1.14, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, {
			eyeSize = Vector3.new(0.50, 0.56, 0.20), eyeSpread = 0.44,
			mouth = false, tail = false, legColor = C3(240, 186, 74),
			bib = { w = 1.00, h = 0.90, y = -0.42, color = p.pale },
		})
		for _, s in ipairs({ -1, 1 }) do
			c:cyl(Vector3.new(0.16, 0.78, 0.78), CFrame.new(0.44 * s, 0.16, 0.97) * CFrame.Angles(0, math.pi / 2, 0), C3(250, 206, 74), NEON)
			c:ovoid(Vector3.new(0.30, 0.34, 0.16), CFrame.new(0.44 * s, 0.16, 1.06), INK):SetAttribute("Eye", true)
			c:ovoid(Vector3.new(0.12, 0.12, 0.10), CFrame.new(0.50 * s, 0.28, 1.12), WHITE):SetAttribute("Eye", true)
			for f = -1, 1 do
				c:cone(Vector3.new(0.10, 0.18, 0.10), CFrame.new(0.30 * s + f * 0.13, -1.02, 0.62) * CFrame.Angles(-1.4, f * 0.4, 0), C3(214, 160, 54))
			end
		end
		c:cone(Vector3.new(0.28, 0.34, 0.34), CFrame.new(0, -0.24, 1.00) * CFrame.Angles(2.0, 0, 0), C3(240, 186, 74))
		ears(c, p.dark, "tuft")
		wings(c, p.dark, 0.24, 0.00, -0.10, 0.12)
		-- Chest speckles.
		spots(c, p.dark, { { -0.26, -0.30, 0.98 }, { 0.26, -0.44, 0.98 }, { 0, -0.62, 0.98 } }, Vector3.new(0.14, 0.14, 0.12))
	end,
}

S.ray = {
	label = "Ray",
	names = { "Glide", "Mantle", "Driftwing", "Shoal", "Silt", "Deepglide", "Sailcloth", "Undertow" },
	head = CFrame.new(0, 0.80, 0.06),
	neck = CFrame.new(0, -0.10, 0.60),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(2.06, 1.44, 1.90), eyeY = 0.24, eyeSpread = 0.44,
			mouthY = -0.40, mouthSize = Vector3.new(0.66, 0.14, 0.14),
			legs = false, tail = false,
		})
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(1.26, 0.40, 1.54), CFrame.new(1.26 * s, -0.08, -0.10) * CFrame.Angles(0, 0, s * 0.26), p.base)
			c:ovoid(Vector3.new(0.34, 0.16, 0.34), CFrame.new(1.14 * s, 0.12, 0.16), p.glow, NEON)
			-- Gill slits underneath.
			for f = 0, 2 do
				c:ovoid(Vector3.new(0.10, 0.10, 0.30), CFrame.new((0.50 + f * 0.20) * s, -0.66, 0.36), p.deep)
			end
		end
		-- Whip tail with a barb.
		c:ovoid(Vector3.new(0.30, 0.24, 1.40), CFrame.new(0, -0.06, -1.42) * CFrame.Angles(0.12, 0, 0), p.dark)
		c:cone(Vector3.new(0.22, 0.42, 0.22), CFrame.new(0, 0.06, -2.16) * CFrame.Angles(-1.4, 0, 0), p.deep)
		spots(c, p.deep, { { -0.60, 0.72, -0.24 }, { 0.60, 0.72, -0.24 }, { 0, 0.76, -0.62 } }, Vector3.new(0.26, 0.12, 0.26))
	end,
}

S.golem = {
	label = "Golem",
	scale = 1.10,
	names = { "Bedrock", "Quarry", "Monolith", "Rubble", "Slate", "Corestone", "Bastion", "Cragfist" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, {
			square = true, bodyMat = SLATE, mouth = false, tail = false,
			eyeColor = p.glow, legSize = Vector3.new(0.52, 0.42, 0.58), legColor = p.deep,
		})
		for _, s in ipairs({ -1, 1 }) do
			c:box(Vector3.new(0.58, 1.00, 0.72), CFrame.new(1.22 * s, -0.06, 0), p.base, SLATE)
			c:box(Vector3.new(0.64, 0.40, 0.78), CFrame.new(1.24 * s, -0.72, 0.04), p.light, SLATE)
			c:box(Vector3.new(0.34, 0.56, 0.34), CFrame.new(0.44 * s, 1.16, -0.26) * CFrame.Angles(-0.3, 0, 0.26 * s), p.deep, SLATE)
		end
		c:ovoid(Vector3.new(0.56, 0.56, 0.40), CFrame.new(0, -0.46, 0.86), p.glow, NEON)
		-- Glowing seams so it reads as a cracked rock, not a grey box.
		for _, v in ipairs({ { -0.40, 0.30, 0.93, 0.5 }, { 0.44, 0.02, 0.93, -0.7 }, { 0.10, -0.86, 0.93, 0.3 } }) do
			c:box(Vector3.new(0.08, 0.46, 0.06), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, 0, v[4]), p.glow, NEON)
		end
		c:light(p.glow, 2.0, 9)
	end,
}

S.sprite = {
	label = "Sprite",
	scale = 0.92,
	names = { "Flicker", "Motes", "Halo", "Willowisp", "Gleam", "Emberlight", "Lumen", "Fizz" },
	head = CFrame.new(0, 1.02, 0.06),
	neck = CFrame.new(0, -0.20, 0.60),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, { bodyColor = p.glow, bodyMat = NEON, legs = false, tail = false, mouth = false })
		for i = 0, 3 do
			local a = (i / 4) * math.pi * 2
			c:ovoid(
				Vector3.new(0.34, 0.46, 0.34),
				CFrame.new(math.cos(a) * 1.34, 0.06 + math.sin(a * 2) * 0.34, math.sin(a) * 1.34) * CFrame.Angles(a, a * 1.7, 0),
				p.base,
				NEON
			)
		end
		c:ovoid(Vector3.new(0.70, 1.00, 0.70), CFrame.new(0, -1.12, -0.26) * CFrame.Angles(math.pi, 0, 0.2), p.base, NEON)
		c:light(p.glow, 2.8, 11)
		c:sparkle(p.glow, 12, 1.3, 0.30)
	end,
}

--------------------------------------------------------------------------------
-- SEASONAL SPECIES
--
-- Same rounded block, same face, tagged with `season` so an event can filter to
-- them. They take every variant too, so Frostbit Spider and Golden Snowman both
-- work without another line of code.
--------------------------------------------------------------------------------

S.pumpkin = {
	label = "Pumpkin",
	season = "Halloween",
	tint = C3(238, 128, 32),
	names = { "Jack", "Gourdling", "Hollowlamp", "Squash", "Lanternjaw", "Patchling", "Sugarpie", "Stingyjack" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		local glow, socket = C3(255, 186, 62), C3(52, 26, 10)
		-- Carved, not painted: dark sockets in the flesh, then the light sitting
		-- inside them. Glow straight onto orange reads as nothing at all.
		block(c, p, {
			bodySize = Vector3.new(2.10, 1.94, 1.94),
			eyeColor = socket, mouthColor = socket, mouthSize = Vector3.new(0.94, 0.28, 0.16),
			legSize = Vector3.new(0.34, 0.34, 0.44), legColor = C3(96, 132, 60), tail = false,
		})
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.30, 0.40, 0.12), CFrame.new(0.42 * s, 0.16, 1.06), glow, NEON)
		end
		c:ovoid(Vector3.new(0.74, 0.18, 0.12), CFrame.new(0, -0.36, 1.06), glow, NEON)
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.42, 1.92, 1.90), CFrame.new(0.72 * s, 0.06, 0), p.dark)
		end
		c:rod(Vector3.new(0, 0.92, 0), Vector3.new(0.12, 1.34, -0.08), 0.15, C3(92, 132, 56))
		c:light(glow, 3.0, 11)
	end,
}

S.ghost = {
	label = "Ghost",
	season = "Halloween",
	tint = C3(230, 236, 250),
	names = { "Boo", "Drafty", "Sheetling", "Whisper", "Pallor", "Haunt", "Mistveil", "Chill" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.20, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		local _, _, body = block(c, p, { legs = false, tail = false, eyeSize = Vector3.new(0.46, 0.60, 0.20) })
		body.Transparency = 0.14
		-- Hem: three fat lobes instead of legs.
		for i = -1, 1 do
			c:ovoid(Vector3.new(0.66, 0.86, 0.86), CFrame.new(i * 0.62, -1.06, 0), p.base).Transparency = 0.16
		end
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.36, 0.52, 0.40), CFrame.new(1.02 * s, 0.02, 0.16) * CFrame.Angles(0, 0, -0.4 * s), p.base).Transparency = 0.16
		end
		c:light(C3(180, 155, 255), 2.0, 10)
	end,
}

S.spider = {
	label = "Spider",
	season = "Halloween",
	tint = C3(66, 48, 84),
	names = { "Webber", "Silkfang", "Creeper", "Widow", "Skitter", "Lacework", "Eightclaw", "Dangle" },
	head = CFrame.new(0, 1.02, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, {
			mouth = false, tail = false,
			legSize = Vector3.new(0.26, 0.28, 0.36), legX = 0.94, legZ = { 0.54, 0.18, -0.18, -0.54 },
		})
		-- Four extra eyes make it a spider without adding a single limb.
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.20, 0.24, 0.14), CFrame.new(0.22 * s, 0.60, 0.96), C3(236, 96, 74), NEON)
			c:ovoid(Vector3.new(0.16, 0.18, 0.12), CFrame.new(0.66 * s, 0.50, 0.94), C3(236, 96, 74), NEON)
			c:ovoid(Vector3.new(0.18, 0.26, 0.16), CFrame.new(0.24 * s, -0.42, 0.84) * CFrame.Angles(0.4, 0, 0), p.pale)
		end
		c:ovoid(Vector3.new(0.90, 0.16, 0.36), CFrame.new(0, 0.92, -0.62), C3(236, 96, 74), NEON)
		c:light(C3(236, 96, 74), 1.4, 8)
	end,
}

S.skelehound = {
	label = "Skelehound",
	season = "Halloween",
	tint = C3(236, 232, 218),
	names = { "Marrow", "Rattlebone", "Gravedog", "Ossuary", "Bonesy", "Cryptpaw", "Ribcage", "Lich" },
	head = CFrame.new(0, 1.02, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			eyeColor = C3(126, 255, 156),
			snout = { w = 0.78, h = 0.50, d = 0.54, color = p.pale, nose = C3(40, 38, 44) },
			legColor = p.pale, tailColor = p.pale,
		})
		ears(c, p.pale, "tuft")
		-- Ribs read as three bands across the block.
		for i = -1, 1 do
			c:cyl(Vector3.new(0.15, 1.30, 1.30), CFrame.new(0, -0.36, i * 0.42) * CFrame.Angles(0, 0, math.pi / 2), p.pale)
		end
		for i = -1, 1 do
			c:box(Vector3.new(0.11, 0.22, 0.09), CFrame.new(i * 0.20, -0.36, 0.95), p.pale)
		end
		c:light(C3(126, 255, 156), 1.6, 8)
	end,
}

S.reaper = {
	label = "Reaper",
	season = "Halloween",
	tint = C3(46, 38, 62),
	names = { "Tally", "Shroud", "Lastlight", "Gravekeep", "Scythe", "Vesper", "Nightreap", "Toll" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.20, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, {
			eyeColor = C3(126, 255, 190), mouth = false, legs = false, tail = false,
		})
		-- Hood brim and peak over the block, cloak lobes under it.
		c:ovoid(Vector3.new(2.24, 0.52, 2.12), CFrame.new(0, 0.72, -0.06), p.dark)
		c:ovoid(Vector3.new(0.70, 0.62, 0.70), CFrame.new(0, 1.16, -0.22) * CFrame.Angles(0.4, 0, 0), p.dark)
		for i = -1, 1 do
			c:ovoid(Vector3.new(0.66, 0.90, 0.86), CFrame.new(i * 0.62, -1.10, 0), p.deep)
		end
		c:rod(Vector3.new(1.08, -1.20, 0.20), Vector3.new(0.92, 1.50, 0.10), 0.09, C3(102, 72, 46))
		c:wedge(Vector3.new(0.10, 0.70, 1.16), CFrame.new(0.46, 1.28, 0.12) * CFrame.Angles(0, math.pi / 2, 0.5), C3(218, 226, 236), METAL)
		c:light(C3(126, 255, 190), 1.8, 9)
	end,
}

S.reindeer = {
	label = "Reindeer",
	season = "Christmas",
	tint = C3(154, 112, 76),
	names = { "Jingle", "Comet", "Blitzen", "Sleighbell", "Tinsel", "Frostrack", "Dasher", "Rednose" },
	head = CFrame.new(0, 1.10, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			snout = { w = 0.66, h = 0.52, d = 0.52, color = p.dark, nose = C3(255, 62, 64) },
			bib = { w = 0.72, h = 0.52, y = -0.60, color = p.pale },
			legColor = C3(62, 46, 40),
			tailSize = Vector3.new(0.30, 0.30, 0.40), tailColor = p.pale,
		})
		-- Rudolph nose, glowing, sat on the end of the muzzle.
		c:ovoid(Vector3.new(0.34, 0.32, 0.28), CFrame.new(0, -0.14, 1.20), C3(255, 62, 64), NEON)
		ears(c, p.dark, "tuft")
		for _, s in ipairs({ -1, 1 }) do
			local r = Vector3.new(0.30 * s, 0.96, -0.02)
			local m = r + Vector3.new(0.22 * s, 0.52, -0.04)
			c:rod(r, m, 0.085, C3(126, 92, 58))
			c:rod(m, m + Vector3.new(0.30 * s, 0.36, 0.08), 0.072, C3(126, 92, 58))
			c:rod(m, m + Vector3.new(0.36 * s, 0.02, -0.30), 0.066, C3(126, 92, 58))
		end
		c:cyl(Vector3.new(0.22, 1.30, 1.30), CFrame.new(0, -0.56, 0.06) * CFrame.Angles(0, 0, math.pi / 2), C3(46, 150, 78))
		c:ovoid(Vector3.new(0.28, 0.28, 0.22), CFrame.new(0, -0.76, 0.72), C3(246, 206, 84), METAL)
		c:light(C3(255, 62, 64), 1.4, 6)
	end,
}

S.snowman = {
	label = "Snowman",
	season = "Christmas",
	tint = C3(246, 250, 255),
	names = { "Frosty", "Flurry", "Slushpile", "Powder", "Coalbutton", "Driftwick", "Chilly", "Snowcap" },
	head = CFrame.new(0, 1.10, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, { mouth = false, legs = false, tail = false })
		c:ovoid(Vector3.new(1.60, 1.10, 1.50), CFrame.new(0, -1.28, 0), p.base)
		c:ovoid(Vector3.new(0.32, 0.62, 0.32), CFrame.new(0, -0.30, 0.98) * CFrame.Angles(1.62, 0, 0), C3(242, 138, 44))
		for i = -1, 1 do
			c:ovoid(Vector3.new(0.16, 0.16, 0.12), CFrame.new(i * 0.24, -0.62, 0.96), C3(38, 36, 44))
		end
		c:ovoid(Vector3.new(0.20, 0.20, 0.14), CFrame.new(0, -1.30, 0.76), C3(38, 36, 44))
		c:cyl(Vector3.new(0.14, 1.60, 1.60), CFrame.new(0, 1.02, 0) * CFrame.Angles(0, 0, math.pi / 2), C3(34, 32, 40))
		c:cyl(Vector3.new(0.58, 1.02, 1.02), CFrame.new(0, 1.32, 0) * CFrame.Angles(0, 0, math.pi / 2), C3(34, 32, 40))
		c:cyl(Vector3.new(0.60, 1.06, 1.06), CFrame.new(0, 1.10, 0) * CFrame.Angles(0, 0, math.pi / 2), C3(196, 44, 52))
		for _, s in ipairs({ -1, 1 }) do
			c:rod(Vector3.new(1.00 * s, -0.20, 0), Vector3.new(1.70 * s, 0.32, 0.06), 0.085, C3(104, 74, 50))
			c:rod(Vector3.new(1.44 * s, 0.10, 0.04), Vector3.new(1.84 * s, 0.62, -0.14), 0.062, C3(104, 74, 50))
		end
	end,
}

S.gingerbread = {
	label = "Gingerbread",
	season = "Christmas",
	tint = C3(182, 116, 60),
	names = { "Snap", "Crumb", "Gumdrop", "Icing", "Nutmeg", "Bakewell", "Spiceling", "Cookiecut" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		local icing = C3(252, 250, 244)
		block(c, p, {
			bodySize = Vector3.new(2.00, 1.90, 1.20),
			mouthSize = Vector3.new(0.44, 0.16, 0.12), mouthColor = icing,
			legSize = Vector3.new(0.48, 0.42, 0.46), legZ = { 0 }, legX = 0.58, tail = false,
		})
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.62, 0.48, 0.46), CFrame.new(1.16 * s, 0.10, 0) * CFrame.Angles(0, 0, -0.3 * s), p.base)
			c:box(Vector3.new(0.34, 0.08, 0.06), CFrame.new(1.20 * s, 0.10, 0.34) * CFrame.Angles(0, 0, 0.3 * s), icing)
			c:box(Vector3.new(0.36, 0.08, 0.06), CFrame.new(0.58 * s, -1.02, 0.30), icing)
		end
		c:ovoid(Vector3.new(0.26, 0.26, 0.16), CFrame.new(0, -0.72, 0.62), C3(226, 62, 68))
		c:box(Vector3.new(0.50, 0.08, 0.06), CFrame.new(0, 0.72, 0.62), C3(226, 62, 68))
	end,
}

S.penguin = {
	label = "Penguin",
	season = "Christmas",
	tint = C3(48, 54, 74),
	names = { "Waddle", "Tux", "Iceberg", "Flipper", "Shuffle", "Krill", "Pebblebeak", "Blizzard" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, {
			mouth = false, tail = false,
			legSize = Vector3.new(0.56, 0.24, 0.66), legY = -0.94, legColor = C3(246, 176, 60),
			legZ = { 0.24 },
		})
		c:ovoid(Vector3.new(1.24, 1.34, 0.62), CFrame.new(0, -0.16, 0.72), C3(250, 250, 252))
		c:ovoid(Vector3.new(0.34, 0.44, 0.34), CFrame.new(0, -0.06, 1.02) * CFrame.Angles(1.7, 0, 0), C3(246, 176, 60))
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.28, 1.00, 0.66), CFrame.new(1.06 * s, -0.10, -0.02) * CFrame.Angles(0, 0, s * 0.18), p.dark)
		end
	end,
}

S.giftbox = {
	label = "Giftbox",
	season = "Christmas",
	tint = C3(206, 50, 62),
	names = { "Wrapper", "Surprise", "Bowtie", "Parcel", "Stocking", "Unboxed", "Ribbons", "Secretsanta" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		local ribbon = C3(246, 206, 84)
		-- The other square pet: it is a parcel.
		block(c, p, { square = true, mouth = false, tail = false, legColor = p.deep })
		c:box(Vector3.new(0.34, 1.92, 1.84), CFrame.new(0, 0.06, 0), ribbon)
		c:box(Vector3.new(2.06, 1.92, 0.34), CFrame.new(0, 0.06, 0), ribbon)
		c:box(Vector3.new(2.10, 0.30, 1.88), CFrame.new(0, 0.86, 0), ribbon)
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.60, 0.48, 0.42), CFrame.new(0.36 * s, 1.20, 0) * CFrame.Angles(0, 0, s * 0.5), ribbon)
		end
		c:ovoid(Vector3.new(0.32, 0.32, 0.32), CFrame.new(0, 1.28, 0), ribbon)
	end,
}

--------------------------------------------------------------------------------
-- SEASONS
--
-- What an event should roll from. Add an id to a list and it is live.
--------------------------------------------------------------------------------

PetModelFactory.SEASONS = {
	Core = {
		species = { "fox", "hound", "otter", "stag", "drake", "wyrm", "serpent", "toad",
			"crab", "beetle", "moth", "hawk", "owl", "ray", "golem", "sprite" },
		variants = { "Normal", "Shiny", "Golden", "Prism", "Rainbow" },
		accessories = { "headlamp", "mini_crown", "halo" },
	},
	Halloween = {
		species = { "pumpkin", "ghost", "spider", "skelehound", "reaper" },
		variants = { "Spooky", "Ember", "Void" },
		accessories = { "witch_hat", "pumpkin_head", "bat_wings" },
	},
	Christmas = {
		species = { "reindeer", "snowman", "gingerbread", "penguin", "giftbox" },
		variants = { "Frostbit", "Peppermint", "Tinselgold" },
		accessories = { "santa_hat", "elf_hat", "antlers", "scarf", "candy_cane" },
	},
}

-- Every pet is scaled so its largest dimension lands here, which keeps a Penguin
-- and a Stag reading as the same "size" of pet. Set to nil to use raw geometry.
PetModelFactory.FIT_SIZE = 2.5
PetModelFactory.BUILD_TAG = "000257"

-- Extra rarity polish. Trim or extend freely; every field is optional.
PetModelFactory.RARITY_FX = {
	HoloRare = { light = 1.0, range = 8 },
	UltraRare = { light = 1.5, range = 9, sparkle = 6 },
	HyperRare = { light = 2.1, range = 10, sparkle = 10, accessory = "mini_crown" },
	SecretRare = { light = 2.8, range = 12, sparkle = 16, accessory = "halo" },
	-- Place1 / CardData rarity names map onto the same idea
	Epic = { light = 1.5, range = 9, sparkle = 6 },
	Legendary = { light = 2.1, range = 10, sparkle = 10, accessory = "mini_crown" },
	Mythic = { light = 2.8, range = 12, sparkle = 16, accessory = "halo" },
}

--------------------------------------------------------------------------------
-- VARIANT STACKING
--
-- A pet has ONE base variant (Golden, Rainbow, Void, ...) and any number of
-- overlays on top. Shiny is the overlay, so "Shiny Golden" is a real thing:
-- the gold recolour lands first, then Shiny adds polish, a brighter rim and a
-- second sparkle without washing the gold out.
--
-- Accepts any of:
--   variant = "Golden", shiny = true
--   variant = { "Golden", "Shiny" }
--   variant = "Shiny"                 -- legacy, reads as Normal + Shiny overlay
--------------------------------------------------------------------------------

function PetModelFactory.resolveVariant(variant, shiny)
	local base, overlays = "Normal", {}
	local seen = {}
	local function take(id)
		local v = PetModelFactory.VARIANTS[id]
		if not v or seen[id] then
			return
		end
		seen[id] = true
		if v.overlay then
			table.insert(overlays, id)
		else
			base = id
		end
	end
	if type(variant) == "table" then
		for _, id in ipairs(variant) do
			take(id)
		end
	elseif type(variant) == "string" then
		take(variant)
	end
	if shiny then
		take("Shiny")
	end
	table.sort(overlays, function(a, b)
		return PetModelFactory.VARIANTS[a].order < PetModelFactory.VARIANTS[b].order
	end)
	return base, overlays
end

-- "Golden" + {"Shiny"} -> "Shiny Golden". Normal alone stays "Normal".
function PetModelFactory.variantLabel(base, overlays)
	local parts = {}
	for _, id in ipairs(overlays or {}) do
		table.insert(parts, id)
	end
	if base ~= "Normal" or #parts == 0 then
		table.insert(parts, base)
	end
	return table.concat(parts, " ")
end

--------------------------------------------------------------------------------
-- BUILD
--------------------------------------------------------------------------------

local function isAccent(part)
	return part.Material == NEON or part.Material == Enum.Material.ForceField
end

local function applyVariant(model, variantId)
	local v = PetModelFactory.VARIANTS[variantId]
	if not v then
		return
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			if isAccent(part) then
				if v.accentGlow then
					part.Color = v.accentGlow
				end
			else
				-- Faces stay readable: eyes take a fraction of the tint.
				local blend = v.blend
				if blend and part:GetAttribute("Eye") then
					blend *= 0.35
				end
				if v.recolor and blend then
					part.Color = part.Color:Lerp(v.recolor, blend)
				end
				if v.material and not part:GetAttribute("Eye") then
					part.Material = v.material
				end
				if v.reflect then
					part.Reflectance = v.reflect
				end
				if v.transparency and part.Transparency < 0.05 and not part:GetAttribute("Eye") then
					part.Transparency = v.transparency
				end
			end
			if v.chroma and (isAccent(part) or not part:GetAttribute("Eye")) then
				part:SetAttribute("Chroma", true)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- VARIANT EFFECTS
--
-- What a variant looks like in motion: particles, a light, and a rim highlight.
-- Every field is optional, so trimming a row just makes that variant quieter.
--   texture   "sparkle" | "smoke" | "fire"
--   rainbow   cycle the particle colour through the spectrum
--   rim       Highlight outline colour (world only, never in a ViewportFrame)
--------------------------------------------------------------------------------

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, C3(255, 90, 90)),
	ColorSequenceKeypoint.new(0.25, C3(255, 220, 80)),
	ColorSequenceKeypoint.new(0.50, C3(90, 235, 130)),
	ColorSequenceKeypoint.new(0.75, C3(90, 170, 255)),
	ColorSequenceKeypoint.new(1.00, C3(205, 100, 255)),
})

PetModelFactory.VARIANT_FX = {
	-- keepBaseRim: Shiny Void should still be rimmed violet. Shiny only paints the
	-- rim when the base variant did not (i.e. plain Shiny on a Normal pet).
	Shiny = { texture = "sparkle", color = C3(236, 250, 255), rate = 30, size = 0.46, speed = 1.7,
		light = { C3(222, 244, 255), 1.1, 7 }, rim = C3(240, 252, 255), keepBaseRim = true },
	Golden = { texture = "sparkle", color = C3(255, 214, 110), rate = 18, size = 0.48, speed = 1.3,
		light = { C3(255, 205, 90), 1.9, 9 }, rim = C3(255, 222, 124) },
	Prism = { texture = "sparkle", color = C3(196, 228, 255), rate = 20, size = 0.44, speed = 1.5,
		light = { C3(190, 225, 255), 1.7, 9 }, rim = C3(212, 236, 255) },
	Rainbow = { texture = "sparkle", rainbow = true, rate = 26, size = 0.52, speed = 1.8,
		light = { C3(255, 190, 255), 2.1, 10 }, rim = C3(255, 200, 255) },
	Spooky = { texture = "smoke", color = C3(150, 90, 210), rate = 12, size = 0.78, speed = 0.9,
		light = { C3(255, 140, 40), 1.9, 9 }, rim = C3(184, 112, 244) },
	Ember = { texture = "fire", color = C3(255, 142, 52), rate = 22, size = 0.62, speed = 1.6,
		light = { C3(255, 130, 40), 2.5, 10 }, rim = C3(255, 152, 62) },
	Void = { texture = "smoke", color = C3(152, 72, 240), rate = 14, size = 0.82, speed = 0.8,
		light = { C3(172, 82, 255), 2.3, 10 }, rim = C3(182, 92, 255) },
	Frostbit = { texture = "sparkle", color = C3(206, 242, 255), rate = 18, size = 0.42, speed = 0.9,
		light = { C3(150, 220, 255), 1.9, 9 }, rim = C3(206, 242, 255) },
	Peppermint = { texture = "sparkle", color = C3(255, 232, 232), rate = 16, size = 0.44, speed = 1.2,
		light = { C3(255, 120, 130), 1.5, 8 }, rim = C3(255, 184, 194) },
	Tinselgold = { texture = "sparkle", color = C3(255, 242, 194), rate = 20, size = 0.48, speed = 1.2,
		light = { C3(255, 230, 160), 2.1, 9 }, rim = C3(255, 242, 194) },
}

-- Built on the FX part the species may already have created, so a Sprite keeps
-- its own glow and gains the variant's on top.
local function applyVariantFX(c, model, variantId)
	local fx = PetModelFactory.VARIANT_FX[variantId]
	if not fx then
		return
	end
	c:sparkle(
		fx.rainbow and RAINBOW or fx.color,
		fx.rate,
		fx.speed,
		fx.size,
		PetModelFactory.TEX[fx.texture or "sparkle"]
	)
	if fx.light then
		c:light(fx.light[1], fx.light[2], fx.light[3])
	end
	if fx.rim then
		-- One Highlight per model: a second just fights the first. An overlay
		-- recolours the rim the base laid down.
		local host = c:fx()
		local h = host:FindFirstChild("VariantRim")
		local existed = h ~= nil
		if not h then
			h = Instance.new("Highlight")
			h.Name = "VariantRim"
			h.Adornee = model
			h.FillTransparency = 1
			h.DepthMode = Enum.HighlightDepthMode.Occluded
			h.Parent = host
		end
		if not (existed and fx.keepBaseRim) then
			h.OutlineColor = fx.rim
		end
		h.OutlineTransparency = 0.15
	end
end

local function applyRarity(c, model, rarityId, anchors)
	local fx = PetModelFactory.RARITY_FX[rarityId]
	if not fx then
		return
	end
	if fx.accessory then
		local acc = PetModelFactory.ACCESSORIES[fx.accessory]
		if acc then
			acc.build(c, anchors[acc.slot] or anchors.head)
		end
	end
	if fx.light then
		c:light(C3(255, 236, 190), fx.light, fx.range or 9)
	end
	if fx.sparkle then
		c:sparkle(C3(255, 236, 190), fx.sparkle, 1.0, 0.26)
	end
end

-- "Ember Fox" -> "fox". Falls back to the first species if nothing matches.
function PetModelFactory.speciesFromName(name)
	if type(name) ~= "string" then
		return nil
	end
	local lowered = string.lower(name)
	for id in pairs(PetModelFactory.SPECIES) do
		if string.find(lowered, id, 1, true) then
			return id
		end
	end
	for id, def in pairs(PetModelFactory.SPECIES) do
		if string.find(lowered, string.lower(def.label), 1, true) then
			return id
		end
	end
	return nil
end

function PetModelFactory.resolveSpecies(species)
	if type(species) == "string" then
		local direct = PetModelFactory.SPECIES[string.lower(species)]
		if direct then
			return string.lower(species)
		end
		local guess = PetModelFactory.speciesFromName(species)
		if guess then
			return guess
		end
	end
	return "fox"
end

--[[
	PetModelFactory.build{
		species = "fox",          -- or "Ember Fox", or a card name
		type = "Crystal",         -- picks the colour from TYPE_TINT
		variant = "Golden",       -- see VARIANTS
		rarity = "Legendary",     -- see RARITY_FX, optional
		accessories = { "santa_hat" },
		scale = 1.0,
		name = "Gilded Vixen",
	}
]]
function PetModelFactory.build(opts)
	opts = opts or {}
	local speciesId = PetModelFactory.resolveSpecies(opts.species)
	local def = PetModelFactory.SPECIES[speciesId]
	local base = def.tint or PetModelFactory.TYPE_TINT[opts.type] or C3(196, 158, 120)

	local model = Instance.new("Model")
	model.Name = opts.name or def.label
	local c = Ctx.new(model)

	local root = c:box(Vector3.new(0.2, 0.2, 0.2), CFrame.new(), base)
	root.Name = "Root"
	root.Transparency = 1
	model.PrimaryPart = root

	def.build(c, palette(base))

	local anchors = {
		head = def.head or CFrame.new(0, 0.7, 0),
		neck = def.neck or CFrame.new(0, 0.3, 0.2),
		back = def.back or CFrame.new(0, 0.4, -0.3),
	}
	for _, accId in ipairs(opts.accessories or {}) do
		local acc = PetModelFactory.ACCESSORIES[accId]
		if acc then
			acc.build(c, anchors[acc.slot] or anchors.head)
		end
	end

	applyRarity(c, model, opts.rarity, anchors)
	-- Base recolour first, then each overlay in order, so Shiny polishes the gold
	-- rather than replacing it.
	local base, overlays = PetModelFactory.resolveVariant(opts.variant, opts.shiny)
	applyVariant(model, base)
	applyVariantFX(c, model, base)
	for _, id in ipairs(overlays) do
		applyVariant(model, id)
		applyVariantFX(c, model, id)
	end

	-- `def.scale` is art intent (a Golem should out-bulk a Sprite); FIT_SIZE then
	-- normalises the whole roster so no species dwarfs the rest.
	local scale = (def.scale or 1) * (opts.scale or 1)
	if PetModelFactory.FIT_SIZE and opts.fit ~= false then
		local _, size = model:GetBoundingBox()
		local largest = math.max(size.X, size.Y, size.Z)
		if largest > 0.01 then
			scale *= PetModelFactory.FIT_SIZE / largest
		end
	end
	if math.abs(scale - 1) > 0.001 then
		pcall(function()
			model:ScaleTo(scale)
		end)
	end

	model:SetAttribute("Species", speciesId)
	model:SetAttribute("SpeciesLabel", def.label)
	-- `Variant` stays the BASE so existing checks (Rainbow chroma, sorting) keep
	-- working; `Shiny` and `VariantLabel` carry the stack.
	model:SetAttribute("Variant", base)
	model:SetAttribute("Shiny", table.find(overlays, "Shiny") ~= nil)
	model:SetAttribute("VariantLabel", PetModelFactory.variantLabel(base, overlays))
	if def.season then
		model:SetAttribute("Season", def.season)
	end
	if opts.rarity then
		model:SetAttribute("Rarity", opts.rarity)
	end
	return model
end

-- Convenience for the mine client, which hands us a whole card.
function PetModelFactory.fromCard(card)
	card = card or {}
	return PetModelFactory.build({
		species = card.species or card.name,
		type = card.typeId,
		variant = card.variant,
		shiny = card.shiny,
		rarity = card.rarityId or card.rarity,
		accessories = card.accessories,
		name = card.name,
	})
end

--------------------------------------------------------------------------------
-- VIEWPORT HELPERS
--------------------------------------------------------------------------------

-- Lights and particles never render inside a ViewportFrame, so drop them and
-- keep the geometry. Use this for inventory tiles and pack reveals.
function PetModelFactory.stripFX(model)
	local fx = model:FindFirstChild("FX")
	if fx then
		fx:Destroy()
	end
	return model
end

-- Point a viewport camera at a model whatever its size, so a Snowman and a Ray
-- both fill the tile.
function PetModelFactory.frameCamera(model, camera, yawDeg, pitchDeg, pad)
	local _, size = model:GetBoundingBox()
	local radius = math.max(size.X, size.Y, size.Z) * 0.5
	local dist = math.max(2.2, radius * (pad or 3.1))
	local yaw = math.rad(yawDeg or 26)
	local pitch = math.rad(pitchDeg or 14)
	local centre = model:GetPivot().Position + Vector3.new(0, size.Y * 0.06, 0)
	local dir = Vector3.new(math.sin(yaw) * math.cos(pitch), math.sin(pitch), math.cos(yaw) * math.cos(pitch))
	camera.CFrame = CFrame.lookAt(centre + dir * dist, centre)
	return camera
end

-- Cycle hue on parts a Rainbow variant tagged. Call from a RenderStepped loop.
function PetModelFactory.animateChroma(model, clock)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part:GetAttribute("Chroma") then
			local offset = (part.Position.X + part.Position.Y) * 0.08
			part.Color = Color3.fromHSV((clock * 0.25 + offset) % 1, 0.62, 1)
		end
	end
end

--------------------------------------------------------------------------------
-- NAME IDEAS
--------------------------------------------------------------------------------

-- "Golden" + "Vixen" -> "Gilded Vixen". Deterministic when you pass a seed, so
-- the same card always gets the same name.
-- Stacked variants stack their prefixes too: Shiny + Golden -> "Gleaming Gilded
-- Vixen". Overlay prefix leads, base prefix sits next to the stem.
function PetModelFactory.suggestName(speciesId, variantId, seed, shiny)
	local def = PetModelFactory.SPECIES[PetModelFactory.resolveSpecies(speciesId)]
	local base, overlays = PetModelFactory.resolveVariant(variantId, shiny)
	local names = def.names or { def.label }
	local n = seed or math.random(1, 100000)
	local words = {}
	for i, id in ipairs(overlays) do
		local pre = PetModelFactory.VARIANTS[id].prefixes
		if pre and #pre > 0 then
			table.insert(words, pre[(math.floor(n / (3 + i)) % #pre) + 1])
		end
	end
	local basePre = (PetModelFactory.VARIANTS[base] or {}).prefixes
	if base ~= "Normal" and basePre and #basePre > 0 then
		table.insert(words, basePre[(n % #basePre) + 1])
	elseif base == "Normal" and #words == 0 and basePre then
		table.insert(words, basePre[(n % #basePre) + 1])
	end
	table.insert(words, names[(math.floor(n / 7) % #names) + 1])
	return table.concat(words, " ")
end

-- Every prefix crossed with every stem, for browsing while you pick favourites.
function PetModelFactory.suggestNames(speciesId, variantId, limit)
	local id = PetModelFactory.resolveSpecies(speciesId)
	local def = PetModelFactory.SPECIES[id]
	local variant = PetModelFactory.VARIANTS[variantId or "Normal"] or PetModelFactory.VARIANTS.Normal
	local out = {}
	for _, prefix in ipairs(variant.prefixes or { "" }) do
		for _, stem in ipairs(def.names or { def.label }) do
			table.insert(out, prefix == "" and stem or (prefix .. " " .. stem))
			if limit and #out >= limit then
				return out
			end
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- ROSTER
--------------------------------------------------------------------------------

-- Ordered species ids: core first, then Halloween, then Christmas.
function PetModelFactory.speciesOrder()
	local out = {}
	for _, key in ipairs({ "Core", "Halloween", "Christmas" }) do
		for _, id in ipairs(PetModelFactory.SEASONS[key].species) do
			if PetModelFactory.SPECIES[id] then
				table.insert(out, id)
			end
		end
	end
	return out
end

function PetModelFactory.variantOrder()
	local out = {}
	for id in pairs(PetModelFactory.VARIANTS) do
		table.insert(out, id)
	end
	table.sort(out, function(a, b)
		return PetModelFactory.VARIANTS[a].order < PetModelFactory.VARIANTS[b].order
	end)
	return out
end

return PetModelFactory
