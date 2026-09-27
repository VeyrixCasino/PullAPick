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

--[[
	SHINY, AS GEOMETRY.

	Everything else that says "shiny" is a particle, a light or a Highlight, and
	a ViewportFrame renders none of the three -- stripFX drops the whole FX host
	before an inventory tile or a pack reveal ever sees the pet. That left a
	Shiny card pixel-identical to a plain one on its own card face, which is a
	strange thing to charge a chase rate for.

	These are neon slivers parented to the MODEL, not to the FX host, so they
	ride into the viewport with the pet and read at tile size. Shadow needs no
	such help: it repaints the body, and paint survives anything.
]]
function Ctx:shinyGlints()
	local cf, size = self.model:GetBoundingBox()
	local span = math.max(size.X, size.Y, size.Z)
	local col = C3(236, 250, 255)
	--[[
		A twinkle, not a plus sign. Two crossed slivers of EQUAL length read as
		a "+" at tile size, so the cross arm is a little over half the long one
		and both are thin; the tilt stops the three from lining up into a
		pattern. Small on purpose -- these sit on the silhouette of a pet that
		is barely an inch tall on a card.
	]]
	local spots = {
		{ Vector3.new(size.X * 0.34, size.Y * 0.38, size.Z * 0.16), 0.15, 18 },
		{ Vector3.new(-size.X * 0.33, size.Y * 0.06, -size.Z * 0.24), 0.10, -26 },
		{ Vector3.new(size.X * 0.05, -size.Y * 0.30, size.Z * 0.33), 0.075, 42 },
	}
	for _, row in ipairs(spots) do
		local len = math.clamp(span * row[2], 0.10, 0.44)
		local thin = len * 0.11
		local at = CFrame.new(cf.Position + row[1]) * CFrame.Angles(0, 0, math.rad(row[3]))
		self:box(Vector3.new(thin, len, thin), at, col, NEON)
		self:last().Name = "ShinyGlint"
		self:box(Vector3.new(len * 0.58, thin, thin), at, col, NEON)
		self:last().Name = "ShinyGlint"
	end
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
	e.Name = "Sparkle"
	e.Texture = texture or PetModelFactory.TEX.sparkle
	e.Color = typeof(color) == "ColorSequence" and color or ColorSequence.new(color)
	e.LightEmission = 0.9
	e.LightInfluence = 0
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, (size or 0.35) * 0.35),
		NumberSequenceKeypoint.new(0.3, size or 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.55, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Rate = rate or 8
	e.Lifetime = NumberRange.new(0.7, 1.4)
	e.Speed = NumberRange.new((speed or 1.2) * 0.45, speed or 1.2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-120, 120)
	e.Drag = 1.5
	e.Acceleration = Vector3.new(0, 0.6, 0)
	e.LockedToPart = false
	e.Parent = self:fx()
	return e
end

-- Readable "this pet is shiny" without going nova: dense flecks + slower glints.
function Ctx:shinySparkles()
	local host = self:fx()
	-- Grow the FX host to the pet so sparkles wrap the silhouette, not a 0.6 stud bead.
	local cf, size = self.model:GetBoundingBox()
	host.Size = Vector3.new(
		math.clamp(size.X * 0.55, 0.8, 3.2),
		math.clamp(size.Y * 0.55, 0.8, 3.2),
		math.clamp(size.Z * 0.55, 0.8, 3.2)
	)
	host.CFrame = cf
	host.Shape = Enum.PartType.Ball

	local whiteGold = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C3(255, 255, 255)),
		ColorSequenceKeypoint.new(0.55, C3(255, 236, 190)),
		ColorSequenceKeypoint.new(1, C3(210, 230, 255)),
	})

	-- Dense body flecks — the tell at a glance.
	local core = self:sparkle(whiteGold, 78, 1.9, 0.55)
	core.Name = "ShinyCore"
	core.Lifetime = NumberRange.new(0.55, 1.15)
	core.SpreadAngle = Vector2.new(180, 180)

	-- Bigger, slower glints so it still reads while idle.
	local glint = self:sparkle(C3(255, 248, 220), 22, 0.9, 0.95)
	glint.Name = "ShinyGlint"
	glint.Lifetime = NumberRange.new(1.0, 1.8)
	glint.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.0),
		NumberSequenceKeypoint.new(0.4, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})

	self:light(C3(245, 250, 255), 1.85, 9)
	return core, glint
end

-- Shadow is Shiny's rare twin and should read as demonic from across the pit.
-- The palette is fixed: #C41E3A for anything that glows or flies off, #6E0814
-- for painted neon, #000000 for the obsidian body.
local SHADOW_GLOW = C3(0xC4, 0x1E, 0x3A)
local SHADOW_NEON = C3(0x6E, 0x08, 0x14)

function Ctx:shadowFlames()
	local host = self:fx()
	local cf, size = self.model:GetBoundingBox()
	host.Size = Vector3.new(
		math.clamp(size.X * 0.6, 0.8, 3.4),
		math.clamp(size.Y * 0.6, 0.8, 3.4),
		math.clamp(size.Z * 0.6, 0.8, 3.4)
	)
	host.CFrame = cf
	host.Shape = Enum.PartType.Ball

	-- Hellfire licking up off the body.
	local flames = self:sparkle(ColorSequence.new(SHADOW_GLOW, SHADOW_NEON), 40, 1.8, 0.95, PetModelFactory.TEX.fire)
	flames.Name = "ShadowFlames"
	flames.Lifetime = NumberRange.new(0.35, 0.7)
	flames.Acceleration = Vector3.new(0, 4, 0)
	flames.Drag = 2
	flames.LightEmission = 1
	flames.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.6, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})

	-- Embers that drift up and wink out.
	local embers = self:sparkle(SHADOW_GLOW, 34, 1.4, 0.32)
	embers.Name = "ShadowEmbers"
	embers.Lifetime = NumberRange.new(0.8, 1.6)
	embers.Acceleration = Vector3.new(0, 2.2, 0)

	-- Black smoke rolling off it. No light emission, so it darkens rather
	-- than glows.
	local smoke = self:sparkle(ColorSequence.new(C3(0, 0, 0), SHADOW_NEON), 9, 0.7, 1.4, PetModelFactory.TEX.smoke)
	smoke.Name = "ShadowSmoke"
	smoke.LightEmission = 0
	smoke.Lifetime = NumberRange.new(1.2, 2.2)
	smoke.Acceleration = Vector3.new(0, 1.2, 0)
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 1.7),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})

	self:light(SHADOW_GLOW, 2.6, 10)
	return flames, embers, smoke
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
		-- Shiny does NOT recolour, and its gloss scales with how bright the part
		-- already is. A flat reflectance mirrors the skybox, which lifts a
		-- near-black Void by ~75% and turns it lavender; reflectBoost gives a
		-- white pet real shine and a black pet almost none.
		reflectBoost = 0.38,
		sparkle = C3(226, 246, 255),
		prefixes = { "Glimmer", "Sheen", "Lustre", "Polished", "Gleam", "Brightscale" },
	},
	-- Shadow is Shiny's rare twin: one shiny in twenty comes out Shadow instead
	-- (MineConfig.SHADOW_OF_SHINY). Also an overlay, so a Golden that rolls
	-- Shadow is obsidian first. Black metal body (Metal at zero reflectance is
	-- the one material that stays black under its own red light -- glass and
	-- any reflectance turn it pink), the model's neon burns #6E0814, and the
	-- eyes glow #C41E3A.
	Shadow = {
		order = 12,
		overlay = true,
		blend = 0.94,
		recolor = C3(0, 0, 0),
		material = METAL,
		reflect = 0,
		accentGlow = C3(0x6E, 0x08, 0x14),
		eyeGlow = C3(0xC4, 0x1E, 0x3A),
		-- Obsidian wins over a cycling hue. Without this a Rainbow pet that
		-- rolls Shadow -- and the four chroma skins (Rainbow Unicorn, Rainbow
		-- Gecko, Colorful Dog, Patchwork Dog) whatever they roll -- keeps the
		-- Chroma tag, and animateChroma repaints the obsidian back to rainbow
		-- every frame. The pet was built black and then painted over sixty
		-- times a second. Shadow has order 12 so it lands last and this sticks.
		chromaOff = true,
		prefixes = { "Hellborn", "Obsidian", "Dread", "Infernal", "Cinderheart", "Abyssal" },
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
-- ROSTER ARCHETYPES
--
-- Body shapes the named pet roster needs. The roster has 228 distinct animals,
-- which is far too many to sculpt one at a time -- so each animal is an
-- archetype plus a skin (colour, ears, a trait or two). "Tuxedo Cat" and
-- "Ginger Cat" are the same cat shape wearing different paint.
--
-- Same rules as the core set: one blocky body, a face, and the snout / ears /
-- tail / markings that say what it is.
--------------------------------------------------------------------------------

S.cat = {
	label = "Cat",
	names = { "Whiskers", "Marble", "Mittens", "Tango", "Smudge", "Patches", "Tofu", "Chai" },
	head = CFrame.new(0, 1.14, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			snout = { w = 0.56, h = 0.38, d = 0.44, color = p.pale },
			tailSize = Vector3.new(0.32, 0.32, 0.44), tailColor = p.base,
		})
		ears(c, p.base, "up", C3(238, 172, 182))
		-- Upright tail and whiskers: cat, not dog.
		c:ovoid(Vector3.new(0.30, 0.86, 0.30), CFrame.new(0, 0.20, -1.16) * CFrame.Angles(0.28, 0, 0), p.base)
		c:ovoid(Vector3.new(0.28, 0.30, 0.28), CFrame.new(0, 0.62, -1.28), p.light)
		for _, s in ipairs({ -1, 1 }) do
			for w = -1, 1 do
				c:box(Vector3.new(0.34, 0.035, 0.035), CFrame.new(0.44 * s, -0.30 + w * 0.09, 1.02) * CFrame.Angles(0, 0.35 * s, 0), p.pale)
			end
		end
	end,
}

S.bunny = {
	label = "Bunny",
	names = { "Pebble", "Flopsy", "Binky", "Fennel", "Mallow", "Gumdrop", "Nori", "Muffin" },
	head = CFrame.new(0, 1.42, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			snout = { w = 0.50, h = 0.34, d = 0.36, color = p.pale, nose = C3(234, 156, 168) },
			bib = { w = 0.80, h = 0.56, y = -0.62, color = p.pale },
			legSize = Vector3.new(0.44, 0.34, 0.62), legZ = { 0.40, -0.46 },
			tail = false,
		})
		-- Long upright ears, the whole silhouette.
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.36, 1.10, 0.30), CFrame.new(0.38 * s, 1.44, -0.02) * CFrame.Angles(0, 0, -0.12 * s), p.base)
			c:ovoid(Vector3.new(0.18, 0.76, 0.18), CFrame.new(0.38 * s, 1.42, 0.12) * CFrame.Angles(0, 0, -0.12 * s), C3(238, 172, 182))
		end
		c:ovoid(Vector3.new(0.46, 0.46, 0.46), CFrame.new(0, -0.34, -1.06), p.pale)
		for _, s in ipairs({ -1, 1 }) do
			c:box(Vector3.new(0.20, 0.10, 0.06), CFrame.new(0.14 * s, -0.48, 1.00), C3(236, 232, 226))
		end
	end,
}

S.bear = {
	label = "Bear",
	names = { "Pudding", "Cocoa", "Teddy", "Fudge", "Huckle", "Bramble", "Wicket", "Gummy" },
	head = CFrame.new(0, 1.08, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(2.14, 1.96, 1.88),
			snout = { w = 0.80, h = 0.56, d = 0.48, color = p.pale },
			legSize = Vector3.new(0.56, 0.42, 0.60), legX = 0.62,
			tailSize = Vector3.new(0.30, 0.30, 0.32),
		})
		ears(c, p.dark, "round", p.pale)
		-- Broad chest and heavy paws read as bear rather than big dog.
		c:ovoid(Vector3.new(1.02, 0.86, 0.24), CFrame.new(0, -0.52, 0.96), p.pale)
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.40, 0.20, 0.30), CFrame.new(0.62 * s, -1.02, 0.70), p.pale)
		end
	end,
}

S.wolf = {
	label = "Wolf",
	names = { "Tundra", "Blizzard", "Sterling", "Quasar", "Wisp", "Aurora", "Fang", "Shade" },
	head = CFrame.new(0, 1.16, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			snout = { w = 0.62, h = 0.48, d = 0.66, color = p.pale },
			brow = p.deep,
			bib = { w = 0.78, h = 0.62, y = -0.58, color = p.pale },
			legColor = p.deep,
			tailSize = Vector3.new(0.52, 0.52, 0.86), tailColor = p.dark,
		})
		-- Taller, sharper ears than a hound, and a ruff.
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.38, 0.76, 0.26), CFrame.new(0.50 * s, 1.24, 0) * CFrame.Angles(0, 0, -0.10 * s), p.base)
			c:ovoid(Vector3.new(0.18, 0.46, 0.16), CFrame.new(0.50 * s, 1.20, 0.12) * CFrame.Angles(0, 0, -0.10 * s), p.deep)
			c:ovoid(Vector3.new(0.28, 0.62, 0.50), CFrame.new(1.02 * s, -0.20, 0.30) * CFrame.Angles(0, 0, -0.3 * s), p.pale)
		end
	end,
}

S.bigcat = {
	label = "Bigcat",
	names = { "Paws", "Saffron", "Flash", "Bolt", "Haze", "Vanta", "Sol", "Rajah" },
	head = CFrame.new(0, 1.14, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(2.16, 1.92, 1.86),
			snout = { w = 0.72, h = 0.44, d = 0.48, color = p.pale },
			legSize = Vector3.new(0.52, 0.40, 0.58), legX = 0.62,
			tailSize = Vector3.new(0.34, 0.34, 0.90), tailColor = p.base,
		})
		ears(c, p.base, "round", p.pale)
		-- Stripes. Swap `dark` for spots and this is a leopard.
		for i = -1, 1 do
			c:ovoid(Vector3.new(0.16, 0.90, 0.20), CFrame.new(i * 0.52, 0.42, -0.96), p.deep)
			c:ovoid(Vector3.new(0.90, 0.16, 0.20), CFrame.new(0, 0.86, -0.40 + i * 0.34), p.deep)
		end
		c:ovoid(Vector3.new(0.96, 0.62, 0.22), CFrame.new(0, -0.56, 0.96), p.pale)
	end,
}

S.mouse = {
	label = "Mouse",
	names = { "Button", "Nibbles", "Cheddar", "Tinker", "Squeaky", "Pika", "Pecan", "Chippy" },
	head = CFrame.new(0, 1.10, 0.06),
	neck = CFrame.new(0, -0.30, 0.58),
	back = CFrame.new(0, 0.20, -0.58),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(1.86, 1.76, 1.70),
			snout = { w = 0.44, h = 0.34, d = 0.52, color = p.pale, nose = C3(234, 150, 164) },
			legSize = Vector3.new(0.34, 0.30, 0.42),
			tail = false,
		})
		-- Huge round ears and a thin rope tail.
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.72, 0.70, 0.24), CFrame.new(0.72 * s, 1.02, -0.02), p.base)
			c:ovoid(Vector3.new(0.42, 0.40, 0.16), CFrame.new(0.74 * s, 1.02, 0.10), C3(238, 172, 182))
		end
		c:rod(Vector3.new(0, -0.44, -0.86), Vector3.new(0.26, -0.10, -1.62), 0.075, C3(232, 178, 186))
	end,
}

S.bird = {
	label = "Bird",
	names = { "Chirpy", "Pips", "Kiwi", "Skye", "Zest", "Cranberry", "Poppy", "Basil" },
	head = CFrame.new(0, 1.10, 0.06),
	neck = CFrame.new(0, -0.20, 0.58),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(1.84, 1.80, 1.72),
			mouth = false,
			bib = { w = 0.88, h = 0.76, y = -0.42, color = p.pale },
			legColor = C3(246, 186, 62), legSize = Vector3.new(0.40, 0.22, 0.52), legZ = { 0.22 },
			tail = false,
		})
		c:cone(Vector3.new(0.30, 0.40, 0.36), CFrame.new(0, -0.18, 0.98) * CFrame.Angles(1.75, 0, 0), C3(246, 186, 62))
		-- Folded wings and a fanned tail.
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.26, 0.96, 0.86), CFrame.new(0.96 * s, -0.12, -0.06) * CFrame.Angles(0, 0, s * 0.14), p.dark)
		end
		c:ovoid(Vector3.new(0.86, 0.28, 0.90), CFrame.new(0, -0.24, -1.06) * CFrame.Angles(0.35, 0, 0), p.dark)
		c:ovoid(Vector3.new(0.44, 0.34, 0.30), CFrame.new(0, 0.92, 0.10), p.light)
	end,
}

S.duck = {
	label = "Duck",
	names = { "Waffles", "Boogie", "Quackers", "Puddle", "Splash", "Dabble", "Paddle", "Bill" },
	head = CFrame.new(0, 1.10, 0.06),
	neck = CFrame.new(0, -0.20, 0.58),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(1.96, 1.72, 1.84),
			mouth = false,
			legColor = C3(246, 168, 48), legSize = Vector3.new(0.52, 0.20, 0.64), legZ = { 0.24 },
			tail = false,
		})
		-- The flat bill is the whole read.
		c:ovoid(Vector3.new(0.66, 0.22, 0.62), CFrame.new(0, -0.24, 1.06), C3(246, 168, 48))
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.24, 0.86, 0.76), CFrame.new(0.98 * s, -0.10, -0.06) * CFrame.Angles(0, 0, s * 0.12), p.light)
		end
		c:ovoid(Vector3.new(0.60, 0.40, 0.54), CFrame.new(0, 0.16, -1.00) * CFrame.Angles(-0.4, 0, 0), p.light)
	end,
}

S.horse = {
	label = "Horse",
	names = { "Starlight", "Glimmer", "Lollipop", "Pizzazz", "Swirl", "Twirl", "Prism", "Ziggy" },
	head = CFrame.new(0, 1.20, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			snout = { w = 0.62, h = 0.66, d = 0.66, color = p.light },
			legSize = Vector3.new(0.36, 0.48, 0.40), legColor = p.deep,
			tailSize = Vector3.new(0.36, 0.72, 0.40), tailColor = p.light,
		})
		ears(c, p.base, "tuft")
		-- Mane down the neck, and the horn slot a unicorn skin fills.
		for i = 0, 2 do
			c:ovoid(Vector3.new(0.26, 0.52, 0.34), CFrame.new(0, 1.06 - i * 0.16, -0.30 - i * 0.30), p.light)
		end
	end,
}

S.pig = {
	label = "Pig",
	names = { "Truffle", "Snoot", "Bubba", "Churro", "Caper", "Buttercup", "Hamlet", "Biscuit" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(2.14, 1.82, 1.90),
			mouth = false,
			legSize = Vector3.new(0.44, 0.36, 0.48), legX = 0.62,
			tailSize = Vector3.new(0.24, 0.24, 0.28),
		})
		-- Flat disc snout with two nostrils.
		c:ovoid(Vector3.new(0.70, 0.54, 0.26), CFrame.new(0, -0.30, 1.02), p.light)
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.14, 0.20, 0.10), CFrame.new(0.16 * s, -0.30, 1.14), p.deep)
			c:cone(Vector3.new(0.36, 0.40, 0.22), CFrame.new(0.52 * s, 1.06, 0.12) * CFrame.Angles(0.3, 0, -0.2 * s), p.light)
		end
	end,
}

S.sheep = {
	label = "Sheep",
	names = { "Cloudy", "Oatmeal", "Cotton", "Frizzle", "Churro Pop", "Woolly", "Fluff", "Baa" },
	head = CFrame.new(0, 1.12, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		-- Dark face poking out of a pale fleece: the sheep silhouette.
		block(c, p, {
			bodySize = Vector3.new(2.10, 1.88, 1.86), bodyColor = p.pale,
			snout = { w = 0.66, h = 0.50, d = 0.46, color = p.dark, nose = C3(40, 36, 44) },
			legSize = Vector3.new(0.32, 0.44, 0.36), legColor = p.dark,
			tailSize = Vector3.new(0.28, 0.28, 0.28), tailColor = p.pale,
		})
		c:ovoid(Vector3.new(1.10, 0.94, 0.60), CFrame.new(0, 0.10, 0.78), p.dark)
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.40, 0.26, 0.34), CFrame.new(0.66 * s, 0.30, 0.72) * CFrame.Angles(0, 0, -0.3 * s), p.dark)
		end
		-- Fleece lumps.
		for _, v in ipairs({ { -0.66, 0.92, -0.30 }, { 0.10, 1.02, -0.62 }, { 0.70, 0.90, -0.26 }, { 0, 0.86, 0.10 } }) do
			c:ovoid(Vector3.new(0.62, 0.50, 0.62), CFrame.new(v[1], v[2], v[3]), p.pale)
		end
	end,
}

S.turtle = {
	label = "Turtle",
	names = { "Sprout", "Reef", "Turbo", "Shelly", "Pokey", "Mossback", "Tide", "Skipper" },
	head = CFrame.new(0, 0.92, 0.06),
	neck = CFrame.new(0, -0.20, 0.62),
	back = CFrame.new(0, 0.30, -0.62),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(2.16, 1.36, 1.90), bodyColor = p.dark,
			snout = { w = 0.54, h = 0.36, d = 0.40, color = p.light },
			legSize = Vector3.new(0.50, 0.28, 0.56), legX = 0.72, legY = -0.74,
			tailSize = Vector3.new(0.24, 0.22, 0.34),
		})
		-- Domed shell with plates.
		c:ovoid(Vector3.new(2.02, 1.10, 1.74), CFrame.new(0, 0.52, -0.16), p.base)
		for _, v in ipairs({ { 0, 1.02, -0.16 }, { -0.62, 0.86, -0.16 }, { 0.62, 0.86, -0.16 }, { 0, 0.86, -0.86 } }) do
			c:ovoid(Vector3.new(0.56, 0.20, 0.56), CFrame.new(v[1], v[2], v[3]), p.light)
		end
	end,
}

S.fish = {
	label = "Fish",
	names = { "Sushi", "Bloop", "Squish", "Coral", "Puffer", "Bubbles", "Gill", "Finn" },
	head = CFrame.new(0, 0.98, 0.06),
	neck = CFrame.new(0, -0.20, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(1.70, 1.80, 2.00),
			mouthY = -0.42, mouthSize = Vector3.new(0.40, 0.26, 0.16),
			legs = false, tail = false,
		})
		-- Tail fin, side fins, dorsal.
		c:ovoid(Vector3.new(0.20, 1.10, 0.86), CFrame.new(0, 0.06, -1.24) * CFrame.Angles(0, 0, 0), p.light)
		c:ovoid(Vector3.new(0.86, 0.20, 0.62), CFrame.new(0, 1.06, -0.30) * CFrame.Angles(0.2, 0, 0), p.light)
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.56, 0.18, 0.50), CFrame.new(0.94 * s, -0.32, 0.14) * CFrame.Angles(0, 0, -0.4 * s), p.light)
		end
	end,
}

S.dolphin = {
	label = "Dolphin",
	names = { "Ripple", "Skipper", "Lotus", "Riptide", "Drift", "Tide", "Wave", "Splash" },
	head = CFrame.new(0, 1.00, 0.06),
	neck = CFrame.new(0, -0.20, 0.60),
	back = CFrame.new(0, 0.30, -0.60),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(1.72, 1.60, 2.10),
			snout = { w = 0.44, h = 0.32, d = 0.76, color = p.light, nose = p.deep },
			bib = { w = 0.84, h = 0.70, y = -0.48, color = p.pale },
			legs = false, tail = false,
		})
		c:ovoid(Vector3.new(0.22, 0.72, 0.56), CFrame.new(0, 0.96, -0.44) * CFrame.Angles(-0.3, 0, 0), p.dark)
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.62, 0.18, 0.52), CFrame.new(0.92 * s, -0.34, 0.10) * CFrame.Angles(0, 0, -0.35 * s), p.dark)
		end
		c:ovoid(Vector3.new(1.10, 0.20, 0.52), CFrame.new(0, -0.10, -1.32) * CFrame.Angles(0.15, 0, 0), p.dark)
	end,
}

S.lizard = {
	label = "Lizard",
	names = { "Skittles", "Cactus", "Vivid", "Sizzle", "Chomp", "Basil", "Scute", "Gecko" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		block(c, p, {
			bodySize = Vector3.new(2.02, 1.62, 1.90),
			mouthY = -0.40, mouthSize = Vector3.new(0.94, 0.16, 0.16),
			legSize = Vector3.new(0.48, 0.28, 0.44), legX = 0.78, legY = -0.78,
			tailSize = Vector3.new(0.44, 0.40, 0.96),
		})
		-- Eye turrets and a back ridge.
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.42, 0.42, 0.42), CFrame.new(0.50 * s, 0.86, 0.30), p.base)
		end
		ridge(c, p.deep, 4, 0.92, -0.30, 0.36, 0.24)
	end,
}

S.slime = {
	label = "Slime",
	names = { "Jellybean", "Lava Lamp", "Goop", "Blob", "Ooze", "Wobble", "Squelch", "Gel" },
	head = CFrame.new(0, 0.98, 0.06),
	neck = CFrame.new(0, -0.20, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		local _, _, body = block(c, p, {
			bodySize = Vector3.new(2.16, 1.66, 2.00),
			mouthY = -0.42, mouthSize = Vector3.new(0.52, 0.22, 0.16),
			legs = false, tail = false,
		})
		body.Transparency = 0.24
		body.Material = GLASS
		-- Drips round the base and a brighter inner core.
		for i = 0, 4 do
			local a = (i / 5) * math.pi * 2
			c:ovoid(
				Vector3.new(0.42, 0.52, 0.42),
				CFrame.new(math.cos(a) * 0.72, -0.86, math.sin(a) * 0.62),
				p.base
			).Transparency = 0.24
		end
		c:ovoid(Vector3.new(0.86, 0.66, 0.80), CFrame.new(0, -0.16, -0.10), p.glow, NEON)
	end,
}

S.critter = {
	label = "Critter",
	names = { "Bandit", "Snickers", "Opie", "Ramen", "Dusty", "Stumpy", "Quibble", "Scamp" },
	head = CFrame.new(0, 1.10, 0.06),
	neck = CFrame.new(0, -0.30, 0.60),
	back = CFrame.new(0, 0.20, -0.60),
	build = function(c, p)
		-- The catch-all small mammal: raccoon, ferret, quokka, opossum, sloth.
		block(c, p, {
			bodySize = Vector3.new(1.96, 1.82, 1.78),
			snout = { w = 0.54, h = 0.40, d = 0.54, color = p.pale },
			bib = { w = 0.82, h = 0.60, y = -0.58, color = p.pale },
			legSize = Vector3.new(0.40, 0.34, 0.46),
			tailSize = Vector3.new(0.46, 0.46, 0.72), tailColor = p.dark,
		})
		ears(c, p.dark, "round", p.pale)
		-- Bandit mask. A skin can recolour it away.
		for _, s in ipairs({ -1, 1 }) do
			c:ovoid(Vector3.new(0.62, 0.44, 0.20), CFrame.new(0.40 * s, 0.20, 0.90), p.dark)
		end
		for i = 0, 2 do
			c:ovoid(Vector3.new(0.48, 0.20, 0.48), CFrame.new(0, -0.10 + i * 0.22, -1.02 - i * 0.06), p.pale)
		end
	end,
}

S.matterbox = {
	label = "Matter Box",
	scale = 1.0,
	names = { "Matter", "Cube", "Parity", "Voidbox" },
	head = CFrame.new(0, 1.06, 0.06),
	neck = CFrame.new(0, -0.30, 0.62),
	back = CFrame.new(0, 0.20, -0.62),
	build = function(c, p)
		-- Plain glowing cube: White Box / Black Box pets.
		block(c, p, {
			square = true,
			bodyMat = NEON,
			bodyColor = p.base,
			mouth = false,
			tail = false,
			legs = false,
			eyeColor = p.glow or WHITE,
		})
	end,
}

--------------------------------------------------------------------------------
-- ANIMALS
--
-- GENERATED from the design roster (roster/genmap.js). Every animal in the pet
-- list resolves to an archetype body plus a skin, because 228 animals is far
-- too many to sculpt individually: "Tuxedo Cat" and "Ginger Cat" are the same
-- cat shape in different paint.
--
-- Hand-edit freely -- adding a row here overrides the generated mapping, and a
-- new species in SPECIES can be pointed at from any row.
--------------------------------------------------------------------------------

PetModelFactory.ANIMALS = {
	["Alien"] = { species = "sprite", tint = Color3.fromRGB(180, 200, 255) },
	["Alpaca"] = { species = "sheep", tint = Color3.fromRGB(238, 226, 206) },
	["Angel Cat"] = { species = "cat", tint = Color3.fromRGB(226, 232, 250), transparency = 0.2, glow = Color3.fromRGB(200, 210, 255) },
	["Arctic Fox"] = { species = "fox", tint = Color3.fromRGB(242, 246, 252) },
	["Armadillo"] = { species = "critter", tint = Color3.fromRGB(178, 158, 134) },
	["Astronaut Dog"] = { species = "hound", tint = Color3.fromRGB(72, 62, 130), glow = Color3.fromRGB(150, 190, 255), detail = { "helmet" } },
	["Axolotl"] = { species = "toad", tint = Color3.fromRGB(248, 172, 196) },
	["Baby Alligator"] = { species = "lizard", tint = Color3.fromRGB(104, 138, 82), detail = { "scales", "jaws" } },
	["Baby Elephant"] = { species = "pig", tint = Color3.fromRGB(242, 168, 178) },
	["Baby Hippo"] = { species = "pig", tint = Color3.fromRGB(242, 168, 178) },
	["Bat"] = { species = "moth", tint = Color3.fromRGB(188, 168, 220) },
	["Beagle"] = { species = "hound", tint = Color3.fromRGB(214, 174, 128) },
	["Bear"] = { species = "bear", tint = Color3.fromRGB(140, 100, 68) },
	["Beaver"] = { species = "critter", tint = Color3.fromRGB(140, 100, 68) },
	["Bee"] = { species = "beetle", tint = Color3.fromRGB(250, 206, 60), detail = { "bands", "bugwings" } },
	["Black Cat"] = { species = "cat", tint = Color3.fromRGB(44, 42, 52) },
	["Black Fox"] = { species = "fox", tint = Color3.fromRGB(44, 42, 52) },
	["Black Rabbit"] = { species = "bunny", tint = Color3.fromRGB(44, 42, 52) },
	["Blobfish"] = { species = "fish", tint = Color3.fromRGB(238, 136, 92) },
	["Blue Bear"] = { species = "bear", tint = Color3.fromRGB(70, 150, 250) },
	["Blue Dragon"] = { species = "drake", tint = Color3.fromRGB(70, 150, 250), detail = { "scales" } },
	["Blue Jay"] = { species = "bird", tint = Color3.fromRGB(70, 150, 250) },
	["Blue Shark"] = { species = "dolphin", tint = Color3.fromRGB(70, 150, 250) },
	["Bread Dog"] = { species = "hound", tint = Color3.fromRGB(206, 158, 96), detail = { "crust" } },
	["Brick Golem"] = { species = "golem", tint = Color3.fromRGB(136, 132, 128) },
	["Brown Bear"] = { species = "bear", tint = Color3.fromRGB(138, 96, 62) },
	["Brownie Bear"] = { species = "bear", tint = Color3.fromRGB(86, 54, 38) },
	["Bulldog"] = { species = "hound", tint = Color3.fromRGB(156, 112, 72) },
	["Bumblebee"] = { species = "beetle", tint = Color3.fromRGB(250, 206, 60), detail = { "bands", "bugwings" } },
	["Bunny"] = { species = "bunny", tint = Color3.fromRGB(232, 224, 214) },
	["Calico Cat"] = { species = "cat", tint = Color3.fromRGB(238, 196, 148) },
	["Campfire Bear"] = { species = "bear", tint = Color3.fromRGB(244, 108, 48), glow = Color3.fromRGB(255, 150, 60) },
	["Canary"] = { species = "bird", tint = Color3.fromRGB(250, 216, 72) },
	["Candy Bunny"] = { species = "bunny", tint = Color3.fromRGB(246, 148, 186) },
	["Candy Cat"] = { species = "cat", tint = Color3.fromRGB(246, 148, 186) },
	["Candy Horse"] = { species = "horse", tint = Color3.fromRGB(244, 140, 180) },
	["Capybara"] = { species = "pig", tint = Color3.fromRGB(166, 124, 84) },
	["Cat"] = { species = "cat", tint = Color3.fromRGB(212, 168, 118) },
	["Chameleon"] = { species = "lizard", tint = Color3.fromRGB(124, 196, 108), detail = { "scales" } },
	["Cheetah"] = { species = "bigcat", tint = Color3.fromRGB(232, 190, 116), detail = { "spots" } },
	["Chick"] = { species = "bird", tint = Color3.fromRGB(252, 220, 96) },
	["Chipmunk"] = { species = "mouse", tint = Color3.fromRGB(190, 140, 92) },
	["Circus Elephant"] = { species = "pig", tint = Color3.fromRGB(242, 168, 178) },
	["Cloud Bunny"] = { species = "bunny", tint = Color3.fromRGB(242, 246, 252) },
	["Cloud Cat"] = { species = "cat", tint = Color3.fromRGB(242, 246, 252) },
	["Coal Cat"] = { species = "cat", tint = Color3.fromRGB(44, 42, 52) },
	["Colorful Dog"] = { species = "hound", tint = Color3.fromRGB(230, 140, 220), chroma = true },
	["Cookie Dog"] = { species = "hound", tint = Color3.fromRGB(176, 124, 72), detail = { "chips" } },
	["Corgi"] = { species = "hound", tint = Color3.fromRGB(222, 158, 92) },
	["Cosmic Wolf"] = { species = "wolf", tint = Color3.fromRGB(72, 62, 130), glow = Color3.fromRGB(150, 190, 255) },
	["Cow"] = { species = "pig", tint = Color3.fromRGB(242, 244, 248) },
	["Cricket"] = { species = "beetle", tint = Color3.fromRGB(110, 150, 210), detail = { "bugwings" } },
	["Crow"] = { species = "hawk", tint = Color3.fromRGB(42, 42, 52) },
	["Crystal Bunny"] = { species = "bunny", tint = Color3.fromRGB(188, 224, 250), material = GLASS, reflect = 0.3, glow = Color3.fromRGB(200, 240, 255) },
	["Crystal Pony"] = { species = "horse", tint = Color3.fromRGB(188, 224, 250), material = GLASS, reflect = 0.3, glow = Color3.fromRGB(200, 240, 255) },
	["Cupcake Cat"] = { species = "cat", tint = Color3.fromRGB(238, 210, 196), detail = { "frosting" } },
	["Cyber Fox"] = { species = "fox", tint = Color3.fromRGB(176, 186, 200), material = METAL, reflect = 0.4, glow = Color3.fromRGB(110, 230, 255), detail = { "robot" } },
	["Dalmatian"] = { species = "hound", tint = Color3.fromRGB(242, 244, 248), detail = { "spots" } },
	["Dandelion Sprite"] = { species = "sprite", tint = Color3.fromRGB(250, 216, 72) },
	["Deer"] = { species = "stag", tint = Color3.fromRGB(172, 124, 82) },
	["Desert Lizard"] = { species = "lizard", tint = Color3.fromRGB(124, 196, 108), detail = { "scales" } },
	["Digital Bunny"] = { species = "bunny", tint = Color3.fromRGB(176, 186, 200), material = METAL, reflect = 0.4, glow = Color3.fromRGB(110, 230, 255), detail = { "robot" } },
	["Dinosaur"] = { species = "lizard", tint = Color3.fromRGB(122, 156, 92), detail = { "scales", "jaws" } },
	["Disco Duck"] = { species = "duck", tint = Color3.fromRGB(86, 74, 120), detail = { "discoball" } },
	["Dog"] = { species = "hound", tint = Color3.fromRGB(156, 112, 72) },
	["Dolphin"] = { species = "dolphin", tint = Color3.fromRGB(126, 176, 220) },
	["Donut Dog"] = { species = "hound", tint = Color3.fromRGB(214, 168, 120), detail = { "glaze" } },
	["Dragon"] = { species = "drake", tint = Color3.fromRGB(148, 108, 220), detail = { "scales" } },
	["Duck"] = { species = "duck", tint = Color3.fromRGB(246, 214, 110) },
	["Eagle"] = { species = "hawk", tint = Color3.fromRGB(126, 96, 64) },
	["Electric Mouse"] = { species = "mouse", tint = Color3.fromRGB(250, 224, 96), glow = Color3.fromRGB(255, 240, 140) },
	["Elf Dog"] = { species = "hound", tint = Color3.fromRGB(156, 112, 72) },
	["Ewok-like Bear"] = { species = "bear", tint = Color3.fromRGB(140, 100, 68) },
	["Fairy"] = { species = "sprite", tint = Color3.fromRGB(180, 200, 255) },
	["Falcon"] = { species = "hawk", tint = Color3.fromRGB(150, 122, 92) },
	["Fancy Poodle"] = { species = "hound", tint = Color3.fromRGB(156, 112, 72) },
	["Fawn"] = { species = "stag", tint = Color3.fromRGB(172, 124, 82) },
	["Ferret"] = { species = "critter", tint = Color3.fromRGB(226, 206, 174) },
	["Fire Fox"] = { species = "fox", tint = Color3.fromRGB(244, 108, 48), glow = Color3.fromRGB(255, 150, 60) },
	["Fire Lizard"] = { species = "lizard", tint = Color3.fromRGB(244, 108, 48), glow = Color3.fromRGB(255, 150, 60) },
	["Firework Dragon"] = { species = "drake", tint = Color3.fromRGB(244, 108, 48), glow = Color3.fromRGB(255, 150, 60), detail = { "scales" } },
	["Flamingo"] = { species = "bird", tint = Color3.fromRGB(248, 146, 176) },
	["Flower Deer"] = { species = "stag", tint = Color3.fromRGB(172, 124, 82) },
	["Forest Fox"] = { species = "fox", tint = Color3.fromRGB(96, 190, 104) },
	["Fox"] = { species = "fox", tint = Color3.fromRGB(232, 138, 62) },
	["Frog"] = { species = "toad", tint = Color3.fromRGB(110, 196, 96) },
	["Gem Cat"] = { species = "cat", tint = Color3.fromRGB(188, 224, 250), material = GLASS, reflect = 0.3, glow = Color3.fromRGB(200, 240, 255) },
	["Ghost Dog"] = { species = "ghost", tint = Color3.fromRGB(226, 232, 250), transparency = 0.2, glow = Color3.fromRGB(200, 210, 255) },
	["Ginger Cat"] = { species = "cat", tint = Color3.fromRGB(246, 152, 58) },
	["Golden Retriever"] = { species = "hound", tint = Color3.fromRGB(232, 190, 120), material = METAL, reflect = 0.35 },
	["Golden Tiger"] = { species = "bigcat", tint = Color3.fromRGB(246, 200, 74), material = METAL, reflect = 0.35, detail = { "stripes" } },
	["Gorilla"] = { species = "critter", tint = Color3.fromRGB(64, 62, 70) },
	["Gray Kitten"] = { species = "cat", tint = Color3.fromRGB(166, 172, 186) },
	["Green Bird"] = { species = "bird", tint = Color3.fromRGB(96, 190, 104) },
	["Green Parrot"] = { species = "bird", tint = Color3.fromRGB(96, 190, 104) },
	["Gremlin"] = { species = "sprite", tint = Color3.fromRGB(180, 200, 255) },
	["Griffin"] = { species = "hawk", tint = Color3.fromRGB(178, 120, 74) },
	["Guinea Pig"] = { species = "pig", tint = Color3.fromRGB(222, 178, 130) },
	["Gummy Bear"] = { species = "bear", tint = Color3.fromRGB(232, 72, 96) },
	["Hamster"] = { species = "mouse", tint = Color3.fromRGB(226, 186, 138) },
	["Hedgehog"] = { species = "critter", tint = Color3.fromRGB(156, 128, 100) },
	["Holiday Reindeer"] = { species = "stag", tint = Color3.fromRGB(172, 124, 82) },
	["Husky"] = { species = "hound", tint = Color3.fromRGB(188, 200, 214) },
	["Ice Cream Unicorn"] = { species = "horse", tint = Color3.fromRGB(250, 234, 212), material = GLASS, reflect = 0.25 },
	["Ice Dragon"] = { species = "drake", tint = Color3.fromRGB(178, 226, 248), material = GLASS, reflect = 0.25, detail = { "scales" } },
	["Ice Wolf"] = { species = "wolf", tint = Color3.fromRGB(178, 226, 248), material = GLASS, reflect = 0.25 },
	["Japanese Spitz"] = { species = "hound", tint = Color3.fromRGB(156, 112, 72) },
	["Jungle Snake"] = { species = "serpent", tint = Color3.fromRGB(96, 190, 104), detail = { "scales" } },
	["Kangaroo"] = { species = "critter", tint = Color3.fromRGB(186, 132, 90) },
	["Kitten"] = { species = "cat", tint = Color3.fromRGB(212, 168, 118) },
	["Koala"] = { species = "bear", tint = Color3.fromRGB(168, 176, 186) },
	["Koi Fish"] = { species = "fish", tint = Color3.fromRGB(238, 136, 92) },
	["Ladybug"] = { species = "beetle", tint = Color3.fromRGB(220, 58, 54), detail = { "elytra", "spots", "bugwings" } },
	["Lamb"] = { species = "sheep", tint = Color3.fromRGB(244, 242, 238) },
	["Lava Dragon"] = { species = "drake", tint = Color3.fromRGB(244, 108, 48), glow = Color3.fromRGB(255, 150, 60), detail = { "scales" } },
	["Lemon Bird"] = { species = "bird", tint = Color3.fromRGB(250, 216, 72) },
	["Lightning Leopard"] = { species = "bigcat", tint = Color3.fromRGB(250, 224, 96), glow = Color3.fromRGB(255, 240, 140) },
	["Llama"] = { species = "sheep", tint = Color3.fromRGB(236, 224, 202) },
	["Lop Bunny"] = { species = "bunny", tint = Color3.fromRGB(232, 224, 214) },
	["Lunar Dragon"] = { species = "drake", tint = Color3.fromRGB(72, 62, 130), glow = Color3.fromRGB(150, 190, 255), detail = { "scales" } },
	["Magma Slime"] = { species = "slime", tint = Color3.fromRGB(244, 108, 48), glow = Color3.fromRGB(255, 150, 60) },
	["Marshmallow Bunny"] = { species = "bunny", tint = Color3.fromRGB(250, 246, 242) },
	["Mermaid Cat"] = { species = "cat", tint = Color3.fromRGB(212, 168, 118) },
	["Mini Dragon"] = { species = "drake", tint = Color3.fromRGB(148, 108, 220), detail = { "scales" } },
	["Misty Panther"] = { species = "bigcat", tint = Color3.fromRGB(140, 100, 210) },
	["Monkey"] = { species = "critter", tint = Color3.fromRGB(156, 116, 78) },
	["Moon Fox"] = { species = "fox", tint = Color3.fromRGB(72, 62, 130), glow = Color3.fromRGB(150, 190, 255) },
	["Moose"] = { species = "stag", tint = Color3.fromRGB(122, 88, 60) },
	["Mouse"] = { species = "mouse", tint = Color3.fromRGB(186, 170, 160) },
	["Northern Lights Wolf"] = { species = "wolf", tint = Color3.fromRGB(72, 62, 130), glow = Color3.fromRGB(150, 190, 255) },
	["Octopus"] = { species = "ray", tint = Color3.fromRGB(214, 108, 156) },
	["Opossum"] = { species = "critter", tint = Color3.fromRGB(190, 190, 196) },
	["Orange Cat"] = { species = "cat", tint = Color3.fromRGB(246, 152, 58) },
	["Orca"] = { species = "dolphin", tint = Color3.fromRGB(40, 44, 56) },
	["Otter"] = { species = "critter", tint = Color3.fromRGB(146, 110, 80) },
	["Owl"] = { species = "owl", tint = Color3.fromRGB(176, 142, 104) },
	["Pancake Penguin"] = { species = "penguin", tint = Color3.fromRGB(232, 190, 122), detail = { "syrup" } },
	["Panda"] = { species = "bear", tint = Color3.fromRGB(246, 248, 250) },
	["Parakeet"] = { species = "bird", tint = Color3.fromRGB(104, 168, 236) },
	["Parrot"] = { species = "bird", tint = Color3.fromRGB(226, 76, 68) },
	["Party Pony"] = { species = "horse", tint = Color3.fromRGB(228, 216, 226) },
	["Patchwork Dog"] = { species = "hound", tint = Color3.fromRGB(230, 140, 220), chroma = true },
	["Peacock"] = { species = "bird", tint = Color3.fromRGB(46, 148, 156) },
	["Penguin"] = { species = "penguin", tint = Color3.fromRGB(52, 56, 74) },
	["Persian Cat"] = { species = "cat", tint = Color3.fromRGB(238, 230, 214) },
	["Phoenix"] = { species = "hawk", tint = Color3.fromRGB(178, 120, 74) },
	["Pie Cat"] = { species = "cat", tint = Color3.fromRGB(226, 184, 120) },
	["Pig"] = { species = "pig", tint = Color3.fromRGB(244, 168, 178) },
	["Piglet"] = { species = "pig", tint = Color3.fromRGB(242, 168, 178) },
	["Pink Dolphin"] = { species = "dolphin", tint = Color3.fromRGB(246, 148, 186) },
	["Pirate Parrot"] = { species = "bird", tint = Color3.fromRGB(104, 168, 236), detail = { "pirate" } },
	["Planet Pup"] = { species = "hound", tint = Color3.fromRGB(72, 62, 130), glow = Color3.fromRGB(150, 190, 255), detail = { "helmet" } },
	["Polar Bear"] = { species = "bear", tint = Color3.fromRGB(242, 246, 252) },
	["Pomeranian"] = { species = "hound", tint = Color3.fromRGB(156, 112, 72) },
	["Poodle"] = { species = "hound", tint = Color3.fromRGB(156, 112, 72) },
	["Porcupine"] = { species = "critter", tint = Color3.fromRGB(128, 108, 88) },
	["Potato Penguin"] = { species = "penguin", tint = Color3.fromRGB(58, 64, 84) },
	["Pufferfish"] = { species = "fish", tint = Color3.fromRGB(238, 136, 92) },
	["Puffin"] = { species = "bird", tint = Color3.fromRGB(44, 44, 54) },
	["Quiet Owl"] = { species = "owl", tint = Color3.fromRGB(176, 142, 104) },
	["Quokka"] = { species = "critter", tint = Color3.fromRGB(178, 142, 104) },
	["Rabbit"] = { species = "bunny", tint = Color3.fromRGB(232, 224, 214) },
	["Raccoon"] = { species = "critter", tint = Color3.fromRGB(140, 146, 158) },
	["Racing Turtle"] = { species = "turtle", tint = Color3.fromRGB(110, 168, 96) },
	["Rain Cloud Pet"] = { species = "sprite", tint = Color3.fromRGB(242, 246, 252) },
	["Rainbow Gecko"] = { species = "lizard", tint = Color3.fromRGB(230, 140, 220), chroma = true, detail = { "scales" } },
	["Rainbow Unicorn"] = { species = "horse", tint = Color3.fromRGB(230, 140, 220), chroma = true },
	["Raven"] = { species = "hawk", tint = Color3.fromRGB(42, 42, 52) },
	["Razzberry Dragon"] = { species = "drake", tint = Color3.fromRGB(196, 60, 118), detail = { "scales" } },
	["Red Bird"] = { species = "bird", tint = Color3.fromRGB(222, 62, 62) },
	["Red Panda"] = { species = "bear", tint = Color3.fromRGB(214, 108, 62) },
	["Reindeer"] = { species = "stag", tint = Color3.fromRGB(172, 124, 82) },
	["Ribbon Unicorn"] = { species = "horse", tint = Color3.fromRGB(228, 216, 226) },
	["Robot Cat"] = { species = "cat", tint = Color3.fromRGB(176, 186, 200), material = METAL, reflect = 0.4, glow = Color3.fromRGB(110, 230, 255), detail = { "robot" } },
	["Robot Dog"] = { species = "hound", tint = Color3.fromRGB(176, 186, 200), material = METAL, reflect = 0.4, glow = Color3.fromRGB(110, 230, 255), detail = { "robot" } },
	["Robot Hamster"] = { species = "mouse", tint = Color3.fromRGB(176, 186, 200), material = METAL, reflect = 0.4, glow = Color3.fromRGB(110, 230, 255), detail = { "robot" } },
	["Rock Golem"] = { species = "golem", tint = Color3.fromRGB(136, 132, 128) },
	["Rock Star Dog"] = { species = "hound", tint = Color3.fromRGB(72, 62, 130), glow = Color3.fromRGB(150, 190, 255) },
	["Roly-Poly Bug"] = { species = "beetle", tint = Color3.fromRGB(110, 150, 210), detail = { "bands" } },
	["Sea Dragon"] = { species = "drake", tint = Color3.fromRGB(148, 108, 220), detail = { "scales" } },
	["Sea Turtle"] = { species = "turtle", tint = Color3.fromRGB(96, 156, 130) },
	["Seahorse"] = { species = "fish", tint = Color3.fromRGB(238, 136, 92) },
	["Seal"] = { species = "critter", tint = Color3.fromRGB(176, 182, 194) },
	["Shadow Cat"] = { species = "cat", tint = Color3.fromRGB(140, 100, 210) },
	["Shadow Panther"] = { species = "bigcat", tint = Color3.fromRGB(140, 100, 210) },
	["Shark"] = { species = "dolphin", tint = Color3.fromRGB(130, 148, 168) },
	["Sheep"] = { species = "sheep", tint = Color3.fromRGB(238, 236, 230) },
	["Sheepdog"] = { species = "sheep", tint = Color3.fromRGB(238, 236, 230) },
	["Shiba Inu"] = { species = "hound", tint = Color3.fromRGB(226, 160, 88) },
	["Siamese Cat"] = { species = "cat", tint = Color3.fromRGB(226, 208, 178) },
	["Silver Wolf"] = { species = "wolf", tint = Color3.fromRGB(166, 172, 186) },
	["Sleepy Sloth"] = { species = "critter", tint = Color3.fromRGB(166, 152, 128) },
	["Slime"] = { species = "slime", tint = Color3.fromRGB(122, 220, 168) },
	["Sloth"] = { species = "critter", tint = Color3.fromRGB(166, 152, 128) },
	["Snake"] = { species = "serpent", tint = Color3.fromRGB(126, 190, 118) },
	["Snow Bunny"] = { species = "bunny", tint = Color3.fromRGB(242, 246, 252) },
	["Snow Monster"] = { species = "bear", tint = Color3.fromRGB(242, 246, 252) },
	["Soda Cat"] = { species = "cat", tint = Color3.fromRGB(198, 112, 62), detail = { "soda" } },
	["Soda Cub"] = { species = "bear", tint = Color3.fromRGB(198, 112, 62), detail = { "soda" } },
	["Space Bunny"] = { species = "bunny", tint = Color3.fromRGB(72, 62, 130), glow = Color3.fromRGB(150, 190, 255) },
	["Space Cat"] = { species = "cat", tint = Color3.fromRGB(72, 62, 130), glow = Color3.fromRGB(150, 190, 255) },
	["Space Dragon"] = { species = "drake", tint = Color3.fromRGB(72, 62, 130), glow = Color3.fromRGB(150, 190, 255), detail = { "scales" } },
	["Sparkle Fox"] = { species = "fox", tint = Color3.fromRGB(232, 138, 62) },
	["Sparrow"] = { species = "bird", tint = Color3.fromRGB(166, 130, 96) },
	["Spider"] = { species = "spider", tint = Color3.fromRGB(86, 66, 108) },
	["Spirit Wolf"] = { species = "ghost", tint = Color3.fromRGB(226, 232, 250), transparency = 0.2, glow = Color3.fromRGB(200, 210, 255) },
	["Squirrel"] = { species = "mouse", tint = Color3.fromRGB(176, 122, 74) },
	["Storm Serpent"] = { species = "serpent", tint = Color3.fromRGB(250, 224, 96), glow = Color3.fromRGB(255, 240, 140), detail = { "scales" } },
	["Sun Lion"] = { species = "bigcat", tint = Color3.fromRGB(246, 200, 74), material = METAL, reflect = 0.35 },
	["Swan"] = { species = "bird", tint = Color3.fromRGB(246, 248, 252) },
	["Tanuki"] = { species = "fox", tint = Color3.fromRGB(150, 122, 96) },
	["Teacup Poodle"] = { species = "hound", tint = Color3.fromRGB(156, 112, 72) },
	["Teddy Bear"] = { species = "bear", tint = Color3.fromRGB(186, 142, 96) },
	["Terrier"] = { species = "hound", tint = Color3.fromRGB(156, 112, 72) },
	["Thorn Bear"] = { species = "bear", tint = Color3.fromRGB(140, 100, 68) },
	["Tiger"] = { species = "bigcat", tint = Color3.fromRGB(240, 156, 52), detail = { "stripes" } },
	["Tiny Dalmatian"] = { species = "hound", tint = Color3.fromRGB(242, 244, 248), detail = { "spots" } },
	["Toucan"] = { species = "bird", tint = Color3.fromRGB(40, 40, 48) },
	["Tumbleweed Pup"] = { species = "hound", tint = Color3.fromRGB(156, 112, 72) },
	["Turtle"] = { species = "turtle", tint = Color3.fromRGB(110, 168, 96) },
	["Tuxedo Cat"] = { species = "cat", tint = Color3.fromRGB(40, 40, 48), detail = { "tuxedo" } },
	["Unicorn"] = { species = "horse", tint = Color3.fromRGB(228, 216, 226) },
	["White Cat"] = { species = "cat", tint = Color3.fromRGB(242, 246, 252) },
	["Wild Dog"] = { species = "hound", tint = Color3.fromRGB(156, 112, 72) },
	["Wind Hawk"] = { species = "hawk", tint = Color3.fromRGB(178, 120, 74) },
	["Wolf"] = { species = "wolf", tint = Color3.fromRGB(126, 136, 154) },
	["Yellow Chick"] = { species = "bird", tint = Color3.fromRGB(250, 216, 72) },
	["Zebra"] = { species = "horse", tint = Color3.fromRGB(242, 244, 248), detail = { "stripes" } },
	["White Box"] = { species = "matterbox", tint = Color3.fromRGB(245, 248, 255), glow = Color3.fromRGB(220, 230, 255) },
	["Black Box"] = { species = "matterbox", tint = Color3.fromRGB(12, 10, 18), glow = Color3.fromRGB(90, 40, 140) },
	["Albert Einstein"] = { species = "sprite", tint = Color3.fromRGB(232, 220, 200), glow = Color3.fromRGB(255, 240, 180), detail = { "helmet" } },
}

--------------------------------------------------------------------------------
-- DETAILS
--
-- Colour alone cannot say "cookie". A brown dog is a brown dog until it has
-- chocolate chips in it; a Disco Duck without a mirrorball is just a duck.
--
-- Each entry adds props on top of the finished species body. They run after the
-- skin, so they can assume the standard chassis: body roughly 2.0 x 1.9 x 1.8
-- centred at y = 0.06, front face near z = 0.9, and `p` is the palette.
--
-- Referenced by name from PetModelFactory.ANIMALS[...].detail.
--------------------------------------------------------------------------------

PetModelFactory.DETAILS = {}
local D = PetModelFactory.DETAILS

local CHOC = C3(74, 46, 30)
local ICING = C3(250, 246, 238)

-- Chocolate chips pressed into the dough. THE cookie tell.
D.chips = function(c, p)
	-- Weighted to the FRONT face and the top. Chips buried on the flanks are
	-- invisible at follow distance, which is where the pet actually lives.
	local front = {
		{ -0.62, 0.62, 0.94 }, { 0.66, 0.50, 0.94 }, { -0.20, 0.78, 0.94 },
		{ 0.30, -0.52, 0.94 }, { -0.66, -0.30, 0.94 }, { 0.70, -0.14, 0.94 },
	}
	for _, v in ipairs(front) do
		c:ovoid(Vector3.new(0.30, 0.30, 0.18), CFrame.new(v[1], v[2], v[3]), CHOC)
	end
	local top = { { -0.42, 1.00, -0.10 }, { 0.34, 1.00, 0.34 }, { 0.02, 1.00, -0.62 } }
	for _, v in ipairs(top) do
		c:ovoid(Vector3.new(0.32, 0.20, 0.32), CFrame.new(v[1], v[2], v[3]), CHOC)
	end
	for _, s in ipairs({ -1, 1 }) do
		c:ovoid(Vector3.new(0.18, 0.30, 0.30), CFrame.new(1.02 * s, 0.30, 0.10), CHOC)
		c:ovoid(Vector3.new(0.18, 0.28, 0.28), CFrame.new(1.02 * s, -0.30, -0.44), CHOC)
	end
	-- A bitten edge, so it is unmistakably a biscuit.
	c:ovoid(Vector3.new(0.62, 0.62, 0.62), CFrame.new(0.86, 0.96, -0.86), p.dark)
end

-- Mirrorball overhead, plus the coloured light it throws.
D.discoball = function(c, p)
	local ball = Vector3.new(0, 1.86, 0)
	c:rod(Vector3.new(0, 1.20, 0), ball, 0.05, C3(80, 80, 90))
	c:ball(Vector3.new(0.78, 0.78, 0.78), CFrame.new(ball), C3(198, 206, 220), METAL)
	-- Facets.
	for i = 0, 9 do
		local a = (i / 10) * math.pi * 2
		c:box(
			Vector3.new(0.22, 0.22, 0.06),
			CFrame.new(ball + Vector3.new(math.cos(a) * 0.38, math.sin(a * 2) * 0.28, math.sin(a) * 0.38))
				* CFrame.Angles(0, a, 0),
			C3(236, 242, 252),
			METAL
		)
	end
	c:light(C3(255, 150, 220), 3.0, 12)
	c:sparkle(C3(255, 170, 235), 16, 1.6, 0.34)
	-- Dance floor squares under the feet.
	for i = 0, 3 do
		local a = (i / 4) * math.pi * 2 + 0.4
		c:box(
			Vector3.new(0.42, 0.05, 0.42),
			CFrame.new(math.cos(a) * 0.66, -1.24, math.sin(a) * 0.66),
			i % 2 == 0 and C3(255, 90, 190) or C3(120, 220, 255),
			NEON
		)
	end
end

-- Ridged back and belly plates. What makes a reptile read as a reptile.
D.scales = function(c, p)
	-- A single mid ridge disappears at distance. Three rows of plates across the
	-- whole back is what actually reads as "reptile" rather than "frog".
	for i = 0, 5 do
		local t = i / 5
		c:cone(
			Vector3.new(0.44 - t * 0.12, 0.48 - t * 0.14, 0.44 - t * 0.12),
			CFrame.new(0, 1.06 - t * 0.10, 0.52 - i * 0.34),
			p.deep
		)
	end
	for _, s in ipairs({ -1, 1 }) do
		for i = 0, 4 do
			c:cone(
				Vector3.new(0.28, 0.30, 0.28),
				CFrame.new(0.48 * s, 0.94 - i * 0.05, 0.40 - i * 0.34) * CFrame.Angles(0, 0, -0.35 * s),
				p.dark
			)
		end
	end
	-- Plated belly bands.
	for i = 0, 4 do
		c:ovoid(Vector3.new(1.00, 0.20, 0.16), CFrame.new(0, -0.48 - i * 0.14, 0.90 - i * 0.16), p.pale)
	end
end

-- Snapping jaw with visible teeth. Alligators are mouth-first animals.
D.jaws = function(c, p)
	c:ovoid(Vector3.new(0.92, 0.34, 0.86), CFrame.new(0, -0.10, 1.16), p.base)
	c:ovoid(Vector3.new(0.86, 0.26, 0.80), CFrame.new(0, -0.44, 1.12), p.light)
	for i = -2, 2 do
		c:cone(Vector3.new(0.12, 0.20, 0.12), CFrame.new(i * 0.17, -0.24, 1.34) * CFrame.Angles(math.pi, 0, 0), C3(250, 250, 244))
		c:cone(Vector3.new(0.11, 0.18, 0.11), CFrame.new(i * 0.17 + 0.08, -0.34, 1.30), C3(250, 250, 244))
	end
	-- Nostrils on top of the snout.
	for _, s in ipairs({ -1, 1 }) do
		c:ovoid(Vector3.new(0.12, 0.08, 0.12), CFrame.new(0.16 * s, 0.06, 1.42), p.deep)
	end
end

-- Horizontal bands. Bees, wasps, anything striped front-to-back.
D.bands = function(c, p, colour)
	for i = 0, 2 do
		c:ovoid(Vector3.new(2.06, 0.34, 1.86), CFrame.new(0, 0.44 - i * 0.52, 0), colour or C3(34, 32, 40))
	end
end

-- Vertical stripes. Zebras.
D.stripes = function(c, p)
	for i = -3, 3 do
		c:ovoid(Vector3.new(0.16, 1.94, 1.86), CFrame.new(i * 0.28, 0.06, 0), C3(38, 36, 44))
	end
end

-- Scattered dark spots. Dalmatians, ladybirds, appaloosas.
D.spots = function(c, p)
	local v = {
		{ -0.52, 0.52, 0.84 }, { 0.44, -0.10, 0.88 }, { 0.02, 0.70, -0.86 },
		{ -0.66, 0.02, -0.80 }, { 0.60, 0.44, -0.84 }, { 0.96, 0.10, 0.16 },
		{ -0.98, 0.40, -0.10 }, { 0.20, -0.44, 0.86 },
	}
	for _, s in ipairs(v) do
		c:ovoid(Vector3.new(0.32, 0.32, 0.24), CFrame.new(s[1], s[2], s[3]), C3(30, 28, 36))
	end
end

-- Antenna, seam and a single lens. Anything mechanical.
D.robot = function(c, p)
	c:rod(Vector3.new(0.30, 1.02, -0.10), Vector3.new(0.42, 1.62, -0.18), 0.05, C3(120, 128, 142))
	c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0.44, 1.66, -0.19), C3(255, 90, 90), NEON)
	c:box(Vector3.new(2.04, 0.07, 1.84), CFrame.new(0, 0.30, 0), C3(96, 104, 120))
	c:box(Vector3.new(0.60, 0.36, 0.10), CFrame.new(-0.52, -0.44, 0.92), C3(96, 104, 120))
	for i = 0, 2 do
		c:box(Vector3.new(0.10, 0.10, 0.06), CFrame.new(-0.68 + i * 0.16, -0.44, 0.97), C3(120, 230, 255), NEON)
	end
	c:light(C3(110, 230, 255), 1.6, 8)
end

-- Glass bubble helmet with a gold ring.
D.helmet = function(c, p)
	local dome = c:ball(Vector3.new(2.12, 2.06, 2.06), CFrame.new(0, 0.20, 0.06), C3(210, 236, 255), GLASS)
	dome.Transparency = 0.55
	dome.Reflectance = 0.25
	c:cyl(Vector3.new(0.18, 1.94, 1.94), CFrame.new(0, -0.78, 0.06) * CFrame.Angles(0, 0, math.pi / 2), C3(240, 206, 90), METAL)
	c:sparkle(C3(190, 220, 255), 6, 0.7, 0.22)
end

-- Eyepatch and a tricorn. Pirates.
D.pirate = function(c, p)
	c:ovoid(Vector3.new(0.46, 0.44, 0.18), CFrame.new(-0.44, 0.20, 0.94), C3(26, 24, 32))
	c:box(Vector3.new(1.10, 0.06, 0.06), CFrame.new(0, 0.34, 0.94) * CFrame.Angles(0, 0, 0.18), C3(26, 24, 32))
	c:cone(Vector3.new(1.10, 0.56, 0.90), CFrame.new(0, 1.24, -0.02), C3(38, 34, 46))
	c:cyl(Vector3.new(0.14, 1.60, 1.60), CFrame.new(0, 1.00, 0) * CFrame.Angles(0, 0, math.pi / 2), C3(38, 34, 46))
	c:ovoid(Vector3.new(0.26, 0.26, 0.10), CFrame.new(0, 1.16, 0.62), C3(240, 236, 228))
end

-- Piped frosting swirl and a cherry.
D.frosting = function(c, p)
	for i = 0, 3 do
		local t = i / 3
		c:ovoid(
			Vector3.new(1.60 - t * 0.80, 0.36, 1.50 - t * 0.76),
			CFrame.new(0, 1.02 + i * 0.28, 0) * CFrame.Angles(0, i * 0.5, 0),
			C3(250, 196, 220)
		)
	end
	c:ball(Vector3.new(0.36, 0.36, 0.36), CFrame.new(0, 2.14, 0), C3(226, 52, 72))
	c:rod(Vector3.new(0, 2.28, 0), Vector3.new(0.10, 2.50, -0.08), 0.04, C3(96, 140, 66))
end

-- Syrup pooling over the top, and a pat of butter.
D.syrup = function(c, p)
	c:ovoid(Vector3.new(1.90, 0.24, 1.72), CFrame.new(0, 1.00, 0), C3(158, 92, 34))
	for i = 0, 3 do
		local a = (i / 4) * math.pi * 2 + 0.5
		c:ovoid(
			Vector3.new(0.28, 0.52, 0.28),
			CFrame.new(math.cos(a) * 0.78, 0.72, math.sin(a) * 0.72),
			C3(158, 92, 34)
		)
	end
	c:box(Vector3.new(0.44, 0.20, 0.44), CFrame.new(0, 1.20, 0), C3(250, 226, 132))
end

-- Slashes in the crust, and a dusting of flour.
D.crust = function(c, p)
	for i = -1, 1 do
		c:box(Vector3.new(0.14, 0.10, 0.86), CFrame.new(i * 0.42, 0.96, 0) * CFrame.Angles(0, 0.4, 0), p.pale)
	end
	c:ovoid(Vector3.new(1.86, 0.16, 1.70), CFrame.new(0, 0.98, 0), p.light)
end

-- Glaze cap with sprinkles.
D.glaze = function(c, p)
	c:ovoid(Vector3.new(2.02, 0.40, 1.84), CFrame.new(0, 0.90, 0), C3(248, 152, 194))
	local cols = { C3(255, 240, 120), C3(120, 220, 255), C3(140, 255, 160), C3(255, 130, 160) }
	for i = 0, 9 do
		local a = (i / 10) * math.pi * 2
		c:box(
			Vector3.new(0.16, 0.06, 0.06),
			CFrame.new(math.cos(a) * 0.62, 1.08, math.sin(a) * 0.56) * CFrame.Angles(0, a, 0),
			cols[(i % 4) + 1]
		)
	end
end

-- White bib, white paws, black everywhere else.
D.tuxedo = function(c, p)
	c:ovoid(Vector3.new(0.94, 1.10, 0.26), CFrame.new(0, -0.28, 0.86), C3(246, 246, 250))
	for _, s in ipairs({ -1, 1 }) do
		for _, z in ipairs({ 0.42, -0.42 }) do
			c:ovoid(Vector3.new(0.50, 0.24, 0.56), CFrame.new(0.56 * s, -1.00, z), C3(246, 246, 250))
		end
	end
	c:box(Vector3.new(0.34, 0.20, 0.10), CFrame.new(0, -0.02, 0.94) * CFrame.Angles(0, 0, 0.78), C3(26, 24, 32))
end

-- Clear insect wings.
D.bugwings = function(c, p)
	for _, s in ipairs({ -1, 1 }) do
		local w = c:ovoid(
			Vector3.new(1.20, 0.10, 0.92),
			CFrame.new(0.92 * s, 0.74, -0.32) * CFrame.Angles(0.2, 0, s * 0.34),
			C3(228, 244, 255)
		)
		w.Transparency = 0.45
		w.Material = GLASS
	end
end

-- Split shell down the middle, for beetles and ladybirds.
D.elytra = function(c, p)
	c:box(Vector3.new(0.10, 1.00, 1.84), CFrame.new(0, 0.62, 0), C3(30, 28, 36))
end

-- Fizzing bubbles and a straw.
D.soda = function(c, p)
	c:rod(Vector3.new(0.34, 0.90, 0.30), Vector3.new(0.58, 1.72, 0.12), 0.07, C3(250, 250, 252))
	for i = 0, 5 do
		local a = (i / 6) * math.pi * 2
		c:ball(
			Vector3.new(0.16, 0.16, 0.16),
			CFrame.new(math.cos(a) * 0.72, 1.10 + (i % 3) * 0.26, math.sin(a) * 0.66),
			C3(255, 255, 255)
		).Transparency = 0.35
	end
	c:sparkle(C3(255, 255, 255), 10, 1.2, 0.20)
end

--------------------------------------------------------------------------------
-- SEASONS
--
-- What an event should roll from. Add an id to a list and it is live.
--------------------------------------------------------------------------------

PetModelFactory.SEASONS = {
	Core = {
		species = { "fox", "hound", "otter", "stag", "drake", "wyrm", "serpent", "toad",
			"crab", "beetle", "moth", "hawk", "owl", "ray", "golem", "sprite",
			-- Roster archetypes: the shapes the named pet list needs.
			"cat", "bunny", "bear", "wolf", "bigcat", "mouse", "bird", "duck",
			"horse", "pig", "sheep", "turtle", "fish", "dolphin", "lizard",
			"slime", "critter" },
		variants = { "Normal", "Shiny", "Shadow", "Golden", "Prism", "Rainbow" },
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
PetModelFactory.BUILD_TAG = "000258"

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

function PetModelFactory.resolveVariant(variant, shiny, shadow)
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
	if shadow then
		take("Shadow")
	elseif shiny then
		take("Shiny")
	end
	-- A Shadow is never also Shiny: it is what the shiny roll turned into.
	if seen.Shadow and seen.Shiny then
		table.remove(overlays, table.find(overlays, "Shiny"))
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
			if v.eyeGlow and part:GetAttribute("Eye") then
				-- The eyes burn instead of taking the tint.
				part.Color = v.eyeGlow
				part.Material = NEON
				part.Reflectance = 0
			elseif isAccent(part) then
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
				if v.reflectBoost then
					-- Scaled by the part's own brightness, so gloss never washes
					-- out a dark base.
					local col = part.Color
					local luma = (col.R + col.G + col.B) / 3
					part.Reflectance = math.clamp(part.Reflectance + v.reflectBoost * luma, 0, 0.6)
				end
				if v.transparency and part.Transparency < 0.05 and not part:GetAttribute("Eye") then
					part.Transparency = v.transparency
				end
			end
			if v.chroma and (isAccent(part) or not part:GetAttribute("Eye")) then
				part:SetAttribute("Chroma", true)
			end
			if v.chromaOff then
				part:SetAttribute("Chroma", nil)
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
	Shiny = { texture = "sparkle", color = C3(236, 250, 255), rate = 70, size = 0.62, speed = 2.0,
		light = { C3(240, 248, 255), 1.8, 9 }, rim = C3(240, 252, 255), keepBaseRim = true },
	-- Particles and light come from Ctx:shadowFlames; the rim always goes red.
	Shadow = { rim = SHADOW_GLOW },
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
	if variantId == "Shadow" and c.shadowFlames then
		-- Flames, embers and black smoke under a red glow.
		c:shadowFlames()
	elseif variantId == "Shiny" and c.shinySparkles then
		-- Dedicated readable sparkle stack (core flecks + slow glints + glow).
		c:shinySparkles()
	else
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
	-- `animal` is a roster entry like "Tuxedo Cat": it picks the archetype body
	-- and the paint in one go. Anything passed explicitly still wins.
	local skin = opts.animal and PetModelFactory.ANIMALS[opts.animal] or nil
	local speciesId = PetModelFactory.resolveSpecies(opts.species or (skin and skin.species))
	local def = PetModelFactory.SPECIES[speciesId]
	local base = opts.tint
		or (skin and skin.tint)
		or def.tint
		or PetModelFactory.TYPE_TINT[opts.type]
		or C3(196, 158, 120)

	local model = Instance.new("Model")
	model.Name = opts.name or def.label
	local c = Ctx.new(model)

	local root = c:box(Vector3.new(0.2, 0.2, 0.2), CFrame.new(), base)
	root.Name = "Root"
	root.Transparency = 1
	model.PrimaryPart = root

	local pal = palette(base)
	def.build(c, pal)

	-- Props that name the animal. A brown dog is a brown dog until it has
	-- chocolate chips in it; a Disco Duck without a mirrorball is just a duck.
	if skin and skin.detail then
		for _, id in ipairs(skin.detail) do
			local fn = PetModelFactory.DETAILS[id]
			if fn then
				fn(c, pal)
			end
		end
	end

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

	-- Skin finish before variants, so a Golden roll still overrides a robot's
	-- metal and a Void roll still darkens a crystal pet.
	if skin then
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") and not part:GetAttribute("Eye") and part.Name ~= "Root" then
				if skin.material and part.Material ~= NEON then
					part.Material = skin.material
				end
				if skin.reflect then
					part.Reflectance = skin.reflect
				end
				if skin.transparency and part.Transparency < 0.05 then
					part.Transparency = skin.transparency
				end
				if skin.chroma then
					part:SetAttribute("Chroma", true)
				end
			end
		end
		if skin.glow then
			c:light(skin.glow, 1.6, 8)
			c:sparkle(skin.glow, 10, 1.1, 0.30)
		end
		model:SetAttribute("Animal", opts.animal)
	end

	applyRarity(c, model, opts.rarity, anchors)
	-- Base recolour first, then each overlay in order, so Shiny polishes the gold
	-- rather than replacing it.
	local base, overlays = PetModelFactory.resolveVariant(opts.variant, opts.shiny, opts.shadow)
	local shadowed = table.find(overlays, "Shadow") ~= nil
	applyVariant(model, base)
	-- Under Shadow the base variant keeps its paint but not its sparkle, so a
	-- Shadow Golden reads as demonic, not as gold.
	if not shadowed then
		applyVariantFX(c, model, base)
	end
	for _, id in ipairs(overlays) do
		applyVariant(model, id)
		applyVariantFX(c, model, id)
	end
	-- After every variant has had its say, so nothing repaints them: the glints
	-- are the only part of Shiny that survives a ViewportFrame.
	if table.find(overlays, "Shiny") then
		c:shinyGlints()
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

	-- Where a real catalog hat sits on this species (PetModelFactory.wearHat).
	-- Stored unscaled: Model:GetScale() supplies the rest, so it stays right
	-- however the model is rescaled afterwards.
	model:SetAttribute("HatAnchor", anchors.head.Position)
	model:SetAttribute("Species", speciesId)
	model:SetAttribute("SpeciesLabel", def.label)
	-- `Variant` stays the BASE so existing checks (Rainbow chroma, sorting) keep
	-- working; `Shiny` and `VariantLabel` carry the stack.
	model:SetAttribute("Variant", base)
	model:SetAttribute("Shiny", table.find(overlays, "Shiny") ~= nil)
	model:SetAttribute("Shadow", shadowed)
	model:SetAttribute("VariantLabel", PetModelFactory.variantLabel(base, overlays))
	if def.season then
		model:SetAttribute("Season", def.season)
	end
	if opts.rarity then
		model:SetAttribute("Rarity", opts.rarity)
	end
	return model
end

--[[
	Build a named pet straight from the roster.

		local Roster = require(Shared.MinePetRoster)
		local model = PetModelFactory.buildFromRoster(Roster, "Dapper", { shiny = true })

	Falls back to a plain build if the name is unknown, so a typo in the roster
	yields a pet rather than an error.
]]
function PetModelFactory.buildFromRoster(roster, petName, opts)
	opts = table.clone(opts or {})
	local entry = roster and roster.BY_NAME and roster.BY_NAME[petName]
	if entry then
		opts.animal = entry.animal
		opts.name = opts.name or entry.name
		opts.tier = entry.tier
	else
		opts.name = opts.name or petName
	end
	local model = PetModelFactory.build(opts)
	if entry then
		model:SetAttribute("Tier", entry.tier)
	end
	return model
end

-- Convenience for the mine client, which hands us a whole card.
function PetModelFactory.fromCard(card)
	card = card or {}
	return PetModelFactory.build({
		species = card.species or card.name,
		animal = card.animal,
		type = card.typeId,
		variant = card.variant,
		shiny = card.shiny,
		shadow = card.shadow,
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
--------------------------------------------------------------------------------
-- REAL HATS ON PETS
--
-- A hat in this game is a real Roblox catalog accessory (MineHats), and this is
-- what puts one on a pet's head out in the world.
--
-- The accessory cannot simply be inserted: InsertService refuses assets the
-- place does not own, which is most of the catalog. What does work -- and is
-- what avatar shops use -- is asking the engine for a rig wearing it
-- (CreateHumanoidModelFromDescription with HatAccessory) and lifting the
-- Accessory out of the result. That call yields and is not cheap, so it happens
-- once per catalog id per session and the template is cached.
--
-- Pet parts are Anchored and the whole model is moved with PivotTo, so the hat
-- is Anchored too and rides along with everything else. No welds, no physics.
--------------------------------------------------------------------------------
PetModelFactory.HAT_CACHE = {}
PetModelFactory.HAT_PENDING = {}
PetModelFactory.HAT_ANCHOR_FALLBACK = Vector3.new(0, 1.06, 0.06)
-- A hat this share of the pet's longest axis reads as a hat rather than a shed.
PetModelFactory.HAT_WIDTH_SHARE = 0.62

-- Yields on the first call for a given id. `false` is cached for a hat the
-- engine would not build, so a bad id is asked for once and never again.
function PetModelFactory.hatTemplate(catalogId)
	catalogId = tonumber(catalogId)
	if not catalogId then
		return nil
	end
	local cached = PetModelFactory.HAT_CACHE[catalogId]
	if cached ~= nil then
		return cached or nil
	end
	-- Three pets in the same hat must not each build their own rig.
	if PetModelFactory.HAT_PENDING[catalogId] then
		local waited = 0
		while PetModelFactory.HAT_PENDING[catalogId] and waited < 10 do
			waited += task.wait(0.1)
		end
		return PetModelFactory.HAT_CACHE[catalogId] or nil
	end
	PetModelFactory.HAT_PENDING[catalogId] = true
	local template
	pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HatAccessory = tostring(catalogId)
		local rig = game:GetService("Players"):CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		if rig then
			for _, d in ipairs(rig:GetDescendants()) do
				if d:IsA("Accessory") or (d:IsA("BasePart") and d.Name == "Handle") then
					template = d:Clone()
					break
				end
			end
			rig:Destroy()
		end
	end)
	PetModelFactory.HAT_CACHE[catalogId] = template or false
	PetModelFactory.HAT_PENDING[catalogId] = nil
	return template
end

-- Where a hat sits on this model, in model space, at its current scale.
function PetModelFactory.hatAnchor(model)
	local a = model and model:GetAttribute("HatAnchor")
	local pos = (typeof(a) == "Vector3") and a or PetModelFactory.HAT_ANCHOR_FALLBACK
	local scale = 1
	pcall(function()
		scale = model:GetScale()
	end)
	return pos * (tonumber(scale) or 1)
end

--[[
	Put `catalogId` on `model`. Replaces whatever hat it was wearing, removes the
	hat when the id is nil, and returns the instance (or nil if the engine would
	not give us that accessory).

	YIELDS the first time each hat is seen. Call it from task.spawn.
]]
function PetModelFactory.wearHat(model, catalogId)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return nil
	end
	local old = model:FindFirstChild("PetHat")
	if old then
		old:Destroy()
	end
	-- Restore body if a prior Dominus-as-pet hid it.
	if model:GetAttribute("DominusPet") then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("DominusHidden") then
				d.Transparency = d:GetAttribute("DominusPrevTrans") or 0
				d:SetAttribute("DominusHidden", nil)
				d:SetAttribute("DominusPrevTrans", nil)
			end
		end
		model:SetAttribute("DominusPet", nil)
	end
	if not catalogId then
		return nil
	end
	local template = PetModelFactory.hatTemplate(catalogId)
	-- The pet may have been despawned while the rig was building.
	if not (template and model.Parent) then
		return nil
	end
	local hat = template:Clone()
	hat.Name = "PetHat"
	local handle = hat:IsA("BasePart") and hat
		or hat:FindFirstChild("Handle")
		or hat:FindFirstChildWhichIsA("BasePart")
	if not handle then
		hat:Destroy()
		return nil
	end
	-- Dominus catalog hats ARE the pet: hide the species body, scale Dominus to
	-- the pet's footprint, keep shiny/shadow/rainbow FX already on the model.
	local isDominus = false
	do
		local Hats = nil
		pcall(function()
			Hats = require(game:GetService("ReplicatedStorage").Mine.Shared.MineHats)
		end)
		if Hats and Hats.LIST then
			for _, h in ipairs(Hats.LIST) do
				if tonumber(h.catalogId) == tonumber(catalogId)
					and string.find(string.lower(tostring(h.name or "")), "dominus", 1, true) then
					isDominus = true
					break
				end
			end
		end
	end
	-- Size it for a pet, not for an avatar.
	local _, ext = model:GetBoundingBox()
	local want = math.max(ext.X, ext.Y, ext.Z) * (isDominus and 0.92 or PetModelFactory.HAT_WIDTH_SHARE)
	local widest = math.max(handle.Size.X, handle.Size.Z, 0.01)
	local k = math.clamp(want / widest, 0.05, 6)
	local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
	if mesh then
		mesh.Scale *= k
	end
	handle.Size *= k
	--[[
		HatAttachment is the point on the accessory that meets the head, so THAT
		is what goes at the pet's head anchor -- not the mesh's own origin, which
		for a tall hat sits somewhere up inside the crown. Resizing a part does
		not move its attachments, so the offset is scaled by hand.
	]]
	local att = handle:FindFirstChild("HatAttachment")
	local offset = CFrame.new()
	if att and att:IsA("Attachment") then
		offset = CFrame.new(att.Position * k) * (att.CFrame - att.Position)
	end
	for _, d in ipairs(hat:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			d.CastShadow = false
		elseif d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			-- Nothing to weld to, and a dangling weld can drag the hat to origin.
			d:Destroy()
		end
	end
	if hat:IsA("BasePart") then
		hat.Anchored = true
		hat.CanCollide = false
		hat.CanQuery = false
		hat.CanTouch = false
		hat.Massless = true
		hat.CastShadow = false
	end
	local pivot = model:GetPivot()
	if isDominus then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d ~= handle and not d:IsDescendantOf(hat) then
				-- Keep FX folder particles; hide solid body parts only.
				if not (d.Parent and d.Parent.Name == "FX") then
					d:SetAttribute("DominusPrevTrans", d.Transparency)
					d:SetAttribute("DominusHidden", true)
					d.Transparency = 1
				end
			end
		end
		model:SetAttribute("DominusPet", true)
		-- Centre Dominus on the pet pivot. Catalog Dominus faces -Look vs pet
		-- forward, so yaw π so the hood/visor reads the same way as the body.
		handle.CFrame = pivot * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, ext.Y * 0.05, 0)
	else
		local anchor = PetModelFactory.hatAnchor(model)
		-- Accessory meshes face the opposite yaw of pet LookVector; flip so
		-- brims/visors point the same way the pet is walking.
		handle.CFrame = pivot * CFrame.new(anchor) * CFrame.Angles(0, math.pi, 0) * offset:Inverse()
		--[[
			A helmet's attachment point is inside the skull, because on an avatar a
			helmet swallows the head. A pet's head anchor is the crown, so obeying
			that offset literally sinks the hat into the body. Let a hat hug the head
			a little, but never drop its brim below this floor.
		]]
		do
			local floorY = (pivot * CFrame.new(anchor)).Position.Y - math.max(ext.Y, 0.5) * 0.12
			local bottom = handle.Position.Y - handle.Size.Y * 0.5
			if bottom < floorY then
				handle.CFrame = handle.CFrame + Vector3.new(0, floorY - bottom, 0)
			end
		end
	end
	hat.Parent = model
	return hat
end

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
