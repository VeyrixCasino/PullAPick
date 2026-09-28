--[[
	MineOreLook -- what an ore block looks like up close.

	A flat coloured cube tells you an ore is there and nothing else. Two greys
	twenty tiers apart are the same cube. This puts a pattern on all SIX faces
	of the block, because you come at a block from any side and an ore you can
	only read from the front is one you walk past.

	The art is DRAWN, not textured -- the same call MineFossils makes, and for
	the same reasons: a marketplace decal can be moderated away under you, none
	of them match this game's art, and everything else here (pets, tools,
	icons) is generated. Nothing to upload, nothing to break.

	If you do upload ore art later, set MineOreLook.DECAL_BY_ID[oreId] to its
	asset id and every face of that ore uses the image instead -- nothing else
	has to change.

	Colour still comes from MineConfig.ORES. The pattern only ever draws in
	shades OF that colour, so the read from across a shaft ("that block is
	green") never changes; the pattern is what you get when you walk up to it.

	Cost: six SurfaceGuis of ~10 frames. Built ONCE per ore id into a template
	and cloned after that, so the 200th Copper block costs six clones rather
	than sixty Instance.new calls. Ore is 1 in 200 blocks -- a 21x21 layer
	carries about two.
]]

local MineOreLook = {}

MineOreLook.FACES = {
	Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left,
	Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom,
}

-- oreId -> "rbxassetid://..." to override the drawn art with an image.
MineOreLook.DECAL_BY_ID = {}

MineOreLook.PIXELS_PER_STUD = 20

--------------------------------------------------------------------------
-- Which pattern an ore wears
--------------------------------------------------------------------------

--[[
	Twelve families, because twelve is how many distinct things you can tell
	apart on a 5-stud cube at digging distance. Past that they blur and you
	are paying instances for nothing.
]]
MineOreLook.FAMILIES = {
	"grain",   -- plain rock, mottled
	"cobble",  -- rounded chunks in grout
	"bands",   -- horizontal strata
	"speckle", -- two-tone flecks
	"cubes",   -- an aligned crystal grid
	"shard",   -- angular chips, glassy
	"pores",   -- holes, volcanic
	"vein",    -- bright metal strung through rock
	"plate",   -- worked metal, bolted
	"facet",   -- a cut gem
	"core",    -- something radioactive in the middle
	"void",    -- not from here
}

-- Material is the fallback: an ore with no opinion wears whatever its
-- Roblox material would imply.
local BY_MATERIAL = {
	[Enum.Material.Rock] = "grain",
	[Enum.Material.Ground] = "grain",
	[Enum.Material.Concrete] = "grain",
	[Enum.Material.Pavement] = "grain",
	[Enum.Material.Asphalt] = "grain",
	[Enum.Material.Cobblestone] = "cobble",
	[Enum.Material.Sandstone] = "bands",
	[Enum.Material.Limestone] = "bands",
	[Enum.Material.Slate] = "bands",
	[Enum.Material.Mud] = "bands",
	[Enum.Material.Brick] = "bands",
	[Enum.Material.Wood] = "bands",
	[Enum.Material.Granite] = "speckle",
	[Enum.Material.Pebble] = "speckle",
	[Enum.Material.Sand] = "speckle",
	[Enum.Material.Plaster] = "speckle",
	[Enum.Material.CeramicTiles] = "speckle",
	[Enum.Material.Marble] = "speckle",
	[Enum.Material.Salt] = "cubes",
	[Enum.Material.Glass] = "facet",
	[Enum.Material.Ice] = "facet",
	[Enum.Material.Glacier] = "facet",
	[Enum.Material.SmoothPlastic] = "facet",
	[Enum.Material.ForceField] = "void",
	[Enum.Material.Metal] = "vein",
	[Enum.Material.Foil] = "vein",
	[Enum.Material.CorrodedMetal] = "vein",
	[Enum.Material.DiamondPlate] = "plate",
	[Enum.Material.Basalt] = "pores",
	[Enum.Material.CrackedLava] = "pores",
	[Enum.Material.Neon] = "core",
}

--[[
	Explicit picks beat the material fallback. These are the ores where the
	material is right for the SHADE but wrong for the SHAPE -- Obsidian is
	Glass because it is glossy, not because it is a cut gem, and Steel is
	DiamondPlate because it is worked, which is exactly the point.
]]
MineOreLook.PATTERN_BY_ID = {
	-- Rock that is just rock
	stone = "grain", limestone = "grain", marble = "grain",
	silicon_nitride = "grain", alumina = "grain", boron_nitride = "grain",
	cobblestone = "cobble",

	-- Layered
	sandstone = "bands", slate = "bands", clay = "bands", brick = "bands",
	petrified_wood = "bands", lignite = "bands", bone = "bands",
	monazite = "bands", cassiterite = "bands",

	-- Flecked
	granite = "speckle", diorite = "speckle", kimberlite = "speckle",
	dunite = "speckle", impactite = "speckle", pallasite = "speckle",
	bauxite = "speckle",

	-- Grown in cubes
	quartzite = "cubes", coesite = "cubes", pyrite = "cubes",
	galena = "cubes", fluorite = "cubes", sphalerite = "cubes",

	-- Chipped and glassy -- conchoidal fracture, the thing that makes a
	-- flint knapper's edge
	flint = "shard", chert = "shard", obsidian = "shard", shungite = "shard",
	tektite = "shard", moldavite = "shard", graphene = "shard",
	bituminous_coal = "shard", anthracite = "shard", fulgurite = "shard",
	silicon_carbide = "shard", boron_carbide = "shard",

	-- Holed
	basalt = "pores", charcoal = "pores", meteorite = "pores",
	graphite = "pores",

	-- Raw metal in rock
	copper = "vein", tin = "vein", lead = "vein", zinc = "vein",
	iron = "vein", nickel = "vein", cobalt = "vein", manganese = "vein",
	silver = "vein", gold = "vein", platinum = "vein", palladium = "vein",
	rhodium = "vein", titanium = "vein", tungsten = "vein", niobium = "vein",
	beryllium = "vein", zirconium = "vein", electrum = "vein",
	chalcopyrite = "vein", hematite = "vein", magnetite = "vein",
	ilmenite = "vein", chromite = "vein", wolframite = "vein",
	orichalcum = "vein", adamantite = "vein", mythril = "vein",

	-- Worked metal: an alloy nobody dug out of the ground looking like this
	bronze = "plate", brass = "plate", steel = "plate", cast_iron = "plate",
	damascus_steel = "plate", pewter = "plate", chromium = "plate",
	meteoric_iron = "plate", vanadium_steel = "plate",

	-- Cut stones
	amber = "facet", quartz = "facet", amethyst = "facet", citrine = "facet",
	agate = "facet", jasper = "facet", onyx = "facet", malachite = "facet",
	azurite = "facet", turquoise = "facet", garnet = "facet",
	peridot = "facet", topaz = "facet", diamond = "facet", ruby = "facet",
	sapphire = "facet", emerald = "facet", tourmaline = "facet",
	tanzanite = "facet", alexandrite = "facet", jade = "facet",
	moonstone = "facet", spinel = "facet", zircon = "facet", opal = "facet",
	aquamarine = "facet", stishovite = "facet", ringwoodite = "facet",
	bridgmanite = "facet", apatite = "facet", sunstone = "facet",
	prismarine = "facet",

	-- Hot
	phosphorus = "core", thorium = "core", uranium = "core",
	plutonium = "core", fermium = "core", lawrencium = "core",

	oganesson = "void",
}

function MineOreLook.family(oreDef)
	if type(oreDef) == "string" then
		return MineOreLook.PATTERN_BY_ID[oreDef] or "grain"
	end
	if not oreDef then
		return "grain"
	end
	local pick = MineOreLook.PATTERN_BY_ID[tostring(oreDef.id or "")]
	if pick then
		return pick
	end
	return BY_MATERIAL[oreDef.material] or "grain"
end

--------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------

-- Every ore draws the same pattern every time. FNV-1a over the id, so the
-- jitter is stable across servers and across a rejoin: the Copper in your
-- wall this session is the Copper you remember.
local function seedOf(id)
	local h = 2166136261
	for i = 1, #id do
		h = bit32.bxor(h, string.byte(id, i))
		h = (h * 16777619) % 4294967296
	end
	return h
end

local function shade(c, t)
	-- t < 0 darkens toward black, t > 0 lightens toward white.
	if t < 0 then
		return c:Lerp(Color3.new(0, 0, 0), -t)
	end
	return c:Lerp(Color3.new(1, 1, 1), t)
end

local function frame(gui, x, y, w, h, opts)
	opts = opts or {}
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(x, y)
	f.Size = UDim2.fromScale(w, h)
	f.Rotation = opts.rot or 0
	f.BackgroundColor3 = opts.color or Color3.new(0, 0, 0)
	f.BackgroundTransparency = opts.clear or 0.25
	f.BorderSizePixel = 0
	f.ZIndex = opts.z or 1
	f.Parent = gui
	if opts.round and opts.round > 0 then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(opts.round, 0)
		c.Parent = f
	end
	return f
end

--[[
	Each family gets (gui, p, rng) where p is the palette:
	  p.base   the ore's own colour, as the part is painted
	  p.dark   / p.deep   shadow tones of it
	  p.light  / p.pale   highlight tones of it
	  p.glow   the ore's glow colour if it has one, else p.pale
]]
local DRAW = {}

function DRAW.grain(gui, p, rng)
	for _ = 1, 5 do
		frame(gui, rng:NextNumber(0.15, 0.85), rng:NextNumber(0.15, 0.85),
			rng:NextNumber(0.22, 0.4), rng:NextNumber(0.18, 0.34),
			{ color = p.dark, clear = 0.62, round = 0.5, rot = rng:NextNumber(0, 180) })
	end
	for _ = 1, 3 do
		frame(gui, rng:NextNumber(0.2, 0.8), rng:NextNumber(0.2, 0.8),
			rng:NextNumber(0.14, 0.26), rng:NextNumber(0.12, 0.22),
			{ color = p.light, clear = 0.72, round = 0.5, rot = rng:NextNumber(0, 180) })
	end
end

function DRAW.cobble(gui, p, rng)
	-- Grout first, chunks on top: the gaps between the chunks ARE the grout.
	frame(gui, 0.5, 0.5, 1, 1, { color = p.deep, clear = 0.35, z = 1 })
	for row = 0, 2 do
		for col = 0, 2 do
			local jx = rng:NextNumber(-0.02, 0.02)
			local jy = rng:NextNumber(-0.02, 0.02)
			frame(gui, 0.1667 + col * 0.3333 + jx, 0.1667 + row * 0.3333 + jy,
				rng:NextNumber(0.26, 0.31), rng:NextNumber(0.26, 0.31),
				{ color = (rng:NextNumber() < 0.4) and p.light or p.base,
					clear = 0.1, round = 0.35, rot = rng:NextNumber(-8, 8), z = 2 })
		end
	end
end

function DRAW.bands(gui, p, rng)
	local y = 0.06
	local flip = false
	while y < 0.98 do
		local h = rng:NextNumber(0.07, 0.19)
		frame(gui, 0.5, math.min(y + h * 0.5, 0.98), 1, h,
			{ color = flip and p.light or p.dark, clear = flip and 0.66 or 0.5 })
		y += h + rng:NextNumber(0.01, 0.04)
		flip = not flip
	end
end

function DRAW.speckle(gui, p, rng)
	for i = 1, 16 do
		local s = rng:NextNumber(0.05, 0.13)
		frame(gui, rng:NextNumber(0.08, 0.92), rng:NextNumber(0.08, 0.92), s, s,
			{ color = (i % 3 == 0) and p.light or p.deep,
				clear = 0.28, round = 0.5 })
	end
end

function DRAW.cubes(gui, p, rng)
	frame(gui, 0.5, 0.5, 1, 1, { color = p.deep, clear = 0.55, z = 1 })
	for row = 0, 3 do
		for col = 0, 3 do
			frame(gui, 0.125 + col * 0.25, 0.125 + row * 0.25, 0.2, 0.2,
				{ color = ((row + col) % 2 == 0) and p.pale or p.light,
					clear = rng:NextNumber(0.12, 0.34), round = 0.12, z = 2 })
		end
	end
end

function DRAW.shard(gui, p, rng)
	-- Squares turned off-axis read as conchoidal chips. No rounding: the
	-- whole point of a chipped face is the straight edge.
	for _ = 1, 5 do
		local s = rng:NextNumber(0.2, 0.42)
		frame(gui, rng:NextNumber(0.2, 0.8), rng:NextNumber(0.2, 0.8), s, s,
			{ color = p.deep, clear = 0.42, rot = rng:NextNumber(0, 90) })
	end
	for _ = 1, 3 do
		frame(gui, rng:NextNumber(0.2, 0.8), rng:NextNumber(0.2, 0.8),
			rng:NextNumber(0.18, 0.34), 0.035,
			{ color = p.pale, clear = 0.4, rot = rng:NextNumber(-60, 60), z = 3 })
	end
end

function DRAW.pores(gui, p, rng)
	for _ = 1, 18 do
		local s = rng:NextNumber(0.04, 0.12)
		frame(gui, rng:NextNumber(0.07, 0.93), rng:NextNumber(0.07, 0.93), s, s,
			{ color = p.deep, clear = 0.15, round = 0.5 })
	end
end

function DRAW.vein(gui, p, rng)
	-- Rock over the top, a seam of metal left showing through it. The part
	-- underneath is already the metal's colour, so the rock is what we add.
	for _ = 1, 4 do
		frame(gui, rng:NextNumber(0.1, 0.9), rng:NextNumber(0.1, 0.9),
			rng:NextNumber(0.4, 0.62), rng:NextNumber(0.36, 0.58),
			{ color = p.deep, clear = 0.3, round = 0.4, rot = rng:NextNumber(0, 180) })
	end
	local x, y = rng:NextNumber(0.12, 0.3), rng:NextNumber(0.1, 0.28)
	for _ = 1, 5 do
		local s = rng:NextNumber(0.12, 0.22)
		frame(gui, x, y, s, s * rng:NextNumber(0.6, 1.1),
			{ color = p.pale, clear = 0.08, round = 0.45,
				rot = rng:NextNumber(0, 180), z = 3 })
		x = math.clamp(x + rng:NextNumber(0.1, 0.22), 0.08, 0.92)
		y = math.clamp(y + rng:NextNumber(0.1, 0.22), 0.08, 0.92)
	end
end

function DRAW.plate(gui, p, rng)
	frame(gui, 0.5, 0.5, 0.84, 0.84, { color = p.light, clear = 0.32, round = 0.08, z = 1 })
	frame(gui, 0.5, 0.5, 0.84, 0.03, { color = p.deep, clear = 0.4, z = 2 })
	frame(gui, 0.5, 0.5, 0.03, 0.84, { color = p.deep, clear = 0.4, z = 2 })
	for _, xy in ipairs({ { 0.2, 0.2 }, { 0.8, 0.2 }, { 0.2, 0.8 }, { 0.8, 0.8 } }) do
		frame(gui, xy[1], xy[2], 0.1, 0.1, { color = p.deep, clear = 0.2, round = 0.5, z = 3 })
		frame(gui, xy[1], xy[2], 0.045, 0.045, { color = p.pale, clear = 0.35, round = 0.5, z = 4 })
	end
	if rng:NextNumber() < 0.5 then
		frame(gui, 0.5, 0.5, 0.58, 0.02, { color = p.pale, clear = 0.55, rot = 34, z = 5 })
	end
end

function DRAW.facet(gui, p, rng)
	-- A cut stone: table, crown, one glint. Squares on 45 read as a gem
	-- outline and cost four frames instead of a mesh.
	frame(gui, 0.5, 0.5, 0.56, 0.56, { color = p.deep, clear = 0.35, rot = 45, z = 1 })
	frame(gui, 0.5, 0.5, 0.42, 0.42, { color = p.light, clear = 0.2, rot = 45, z = 2 })
	frame(gui, 0.5, 0.5, 0.24, 0.24, { color = p.pale, clear = 0.28, rot = 45, z = 3 })
	frame(gui, 0.38, 0.36, 0.14, 0.035, { color = p.glow, clear = 0.2, rot = -38, z = 4 })
	for _ = 1, 3 do
		local s = rng:NextNumber(0.05, 0.1)
		frame(gui, rng:NextNumber(0.1, 0.9), rng:NextNumber(0.1, 0.9), s, s,
			{ color = p.pale, clear = 0.55, rot = 45, z = 1 })
	end
end

function DRAW.core(gui, p, _rng)
	-- Something in there is on. Ring, core, four rays -- the trefoil read
	-- without drawing a trefoil.
	frame(gui, 0.5, 0.5, 0.62, 0.62, { color = p.deep, clear = 0.4, round = 0.5, z = 1 })
	frame(gui, 0.5, 0.5, 0.5, 0.5, { color = p.glow, clear = 0.72, round = 0.5, z = 2 })
	frame(gui, 0.5, 0.5, 0.26, 0.26, { color = p.glow, clear = 0.05, round = 0.5, z = 4 })
	for i = 0, 3 do
		frame(gui, 0.5, 0.5, 0.86, 0.045,
			{ color = p.glow, clear = 0.55, rot = i * 45 + 22.5, z = 3 })
	end
end

function DRAW.void(gui, p, rng)
	-- Oganesson. The block is a hole in the wall with a spectrum in it.
	frame(gui, 0.5, 0.5, 1, 1, { color = Color3.fromRGB(8, 4, 16), clear = 0.12, z = 1 })
	local a = rng:NextNumber(0, math.pi * 2)
	for i = 0, 6 do
		local r = 0.06 + i * 0.05
		local s = 0.16 - i * 0.014
		frame(gui, 0.5 + math.cos(a) * r, 0.5 + math.sin(a) * r, s, s,
			{ color = Color3.fromHSV((i / 7 + 0.05) % 1, 0.75, 1),
				clear = 0.22 + i * 0.06, round = 0.5, z = 2 + i })
		a += 0.85
	end
	frame(gui, 0.5, 0.5, 0.1, 0.1, { color = p.pale, clear = 0.1, round = 0.5, z = 12 })
end

--------------------------------------------------------------------------
-- Templates
--------------------------------------------------------------------------

-- oreId -> { SurfaceGui x6 }, built once and cloned from then on.
local templates = {}

local function paletteFor(oreDef)
	local base = oreDef.color or Color3.fromRGB(150, 150, 150)
	return {
		base = base,
		dark = shade(base, -0.28),
		deep = shade(base, -0.55),
		light = shade(base, 0.24),
		pale = shade(base, 0.52),
		glow = oreDef.glow or shade(base, 0.6),
	}
end

local function buildTemplate(oreDef)
	local id = tostring(oreDef.id or "ore")
	local fam = MineOreLook.family(oreDef)
	local draw = DRAW[fam] or DRAW.grain
	local p = paletteFor(oreDef)
	local decal = MineOreLook.DECAL_BY_ID[id]
	local set = {}
	for i, face in ipairs(MineOreLook.FACES) do
		if decal and decal ~= "" then
			local d = Instance.new("Decal")
			d.Name = "OreArt"
			d.Face = face
			d.Texture = decal
			set[i] = d
		else
			local gui = Instance.new("SurfaceGui")
			gui.Name = "OreArt"
			gui.Face = face
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = MineOreLook.PIXELS_PER_STUD
			gui.AlwaysOnTop = false
			-- Each face gets its own roll off one stable seed, so the six
			-- sides of a block are not six copies of the same picture.
			draw(gui, p, Random.new(seedOf(id) + i * 7919))
			set[i] = gui
		end
	end
	return set
end

local function templateFor(oreDef)
	local id = tostring(oreDef.id or "ore")
	local set = templates[id]
	if not set then
		set = buildTemplate(oreDef)
		templates[id] = set
	end
	return set
end

-- Drop the cache after editing DECAL_BY_ID or a pattern, so the next block
-- rebuilds. Blocks already in the world keep the art they were given.
function MineOreLook.flush()
	templates = {}
end

--------------------------------------------------------------------------
-- Public
--------------------------------------------------------------------------

function MineOreLook.strip(part)
	for _, ch in ipairs(part:GetChildren()) do
		if ch.Name == "OreArt" then
			ch:Destroy()
		end
	end
end

--[[
	Put the ore on the block. Six faces.

	Callers guard this with pcall for the same reason the fossil art is
	guarded: decoration must never be able to stop a block existing.
]]
function MineOreLook.decorate(part, oreDef)
	if not (part and oreDef) then
		return
	end
	for _, tmpl in ipairs(templateFor(oreDef)) do
		tmpl:Clone().Parent = part
	end
end

--------------------------------------------------------------------------
-- Preview
--------------------------------------------------------------------------

--[[
	Every ore in the game, laid out in a grid, one block each, named. Run it
	from the command bar when you are judging the art:

		require(game.ReplicatedStorage.Mine.Shared.MineOreLook).buildPreview()

	It lands in Workspace._OrePreview -- so Workspace._OrePreview.Uranium is
	that ore's block -- and rebuilds from scratch every call. Nothing in the
	game reads it; delete the folder when you are done.
]]
function MineOreLook.buildPreview(parent, opts)
	opts = opts or {}
	local Config = require(script.Parent:WaitForChild("MineConfig"))
	parent = parent or workspace
	local old = parent:FindFirstChild("_OrePreview")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "_OrePreview"

	local size = opts.size or 5
	local gap = opts.gap or 4
	local perRow = opts.perRow or 12
	local origin = opts.origin or Vector3.new(0, 20, 0)

	for i, ore in ipairs(Config.ORES) do
		local col = (i - 1) % perRow
		local row = math.floor((i - 1) / perRow)
		local part = Instance.new("Part")
		part.Name = ore.name
		part.Anchored = true
		part.Size = Vector3.new(size, size, size)
		part.CFrame = CFrame.new(origin + Vector3.new(col * (size + gap), 0, row * (size + gap)))
		part.Color = ore.color
		part.Material = ore.material
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part:SetAttribute("OreId", ore.id)
		part:SetAttribute("OreTier", ore.tier)
		part:SetAttribute("Pattern", MineOreLook.family(ore))
		MineOreLook.decorate(part, ore)
		if ore.glow then
			local light = Instance.new("PointLight")
			light.Color = ore.glow
			light.Brightness = tonumber(ore.glowBright) or 1
			light.Range = 8 + (tonumber(ore.glowBright) or 1) * 5
			light.Shadows = false
			light.Parent = part
		end
		if opts.labels ~= false then
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromScale(6, 1.4)
			bb.StudsOffsetWorldSpace = Vector3.new(0, size * 0.75, 0)
			bb.AlwaysOnTop = true
			bb.Parent = part
			local tl = Instance.new("TextLabel")
			tl.Size = UDim2.fromScale(1, 1)
			tl.BackgroundTransparency = 1
			tl.Text = string.format("%d  %s\n%s", ore.tier, ore.name, MineOreLook.family(ore))
			tl.TextColor3 = Color3.new(1, 1, 1)
			tl.TextStrokeTransparency = 0.2
			tl.TextScaled = true
			tl.Font = Enum.Font.GothamMedium
			tl.Parent = bb
		end
		part.Parent = folder
	end

	folder.Parent = parent
	return folder
end

return MineOreLook
