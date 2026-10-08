--!strict
--[[
	ORE FACES, DRAWN PER ORE AND HUNG AS DECALS.

	Owner, 2026-10-08: "make the stone ore, just a grey block, and make ore
	blocks look better (i hate the design now. should be like a mash of blocks
	inside of the block, to resemble an ore.. make it a decal so its not so
	glitchy, and make crystals, metals, and all that shit different ore looks)".

	Four things in that, and each one is a decision here.

	A MASH OF BLOCKS. The face is a cluster of chunky nodules crowded toward
	the middle, not a texture. Each nodule is a solid shape with a lit top-left
	edge and a shaded bottom-right one, so it reads as a lump embedded in rock
	rather than a sticker on a wall. That two-pixel bevel is doing most of the
	work: without it the same shapes read flat and painted-on.

	A DECAL, NOT A TEXTURE. MineOreArt hung six Textures per block with
	StudsPerTileU/V set to the part's size, so each face showed "one tile" only
	as long as that arithmetic held -- and at block edges a tile that is a
	hair off repeats or bleeds, which is the glitching. A Decal has no tiling
	properties at all. It fits the face it is on, by definition, at any block
	size.

	A DIFFERENT LOOK PER MATERIAL, and it reads the SAME two fields the
	hardness curve does -- `met` and `rough` off the roster row -- so an ore
	that feels like metal also looks like metal. A third table keyed by ore
	would drift away from both.

	    metal    few big rounded nuggets, a hard specular glint
	    crystal  angular facets, bright core, dark rim
	    rock     many small dull speckles, no glint
	    glow     crystal, plus a soft halo, for ores with a `glow` colour

	STONE IS A PLAIN GREY BLOCK. It is in PLAIN below and gets no face at all,
	because an "ore" that is the same grey as the wall it sits in should not be
	advertising itself with a nugget cluster.

	WHY THE PIXELS ARE BUILT AT RUNTIME. Same reason MineOreArt gives: this
	place belongs to a GROUP and anything the upload tooling produces belongs
	to a USER, so an uploaded image loads as nothing and reports nothing.
	EditableImage does not replicate either, so this runs on the CLIENT, where
	the block is drawn. The server stamps OreId and nothing else.

	One image per ore, built on first sight and cached, so 82 ores cost at most
	82 decodes in a session and nothing after.
]]
local AssetService = game:GetService("AssetService")

local MineOreFace = {}

local SIZE = 64

--[[
	Ores drawn as a bare block. The host part already carries the ore's colour
	and material, so a "face" would be a cluster of the same grey on grey.

	Read from MineConfig rather than restated: the SERVER uses the same set to
	decide whether to paint the block its ore colour instead of the darkened
	host rock, and two copies of a list like this diverge the first time one of
	them is edited. The literal here is only the fallback for a load failure.
]]
MineOreFace.PLAIN = (function()
	local ok, C = pcall(function()
		return require(script.Parent:WaitForChild("MineConfig"))
	end)
	if ok and type(C) == "table" and type(C.ORE_PLAIN) == "table" then
		return C.ORE_PLAIN
	end
	return { stone = true }
end)()

local FACES = {
	Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Right,
	Enum.NormalId.Left, Enum.NormalId.Top, Enum.NormalId.Bottom,
}

-- Deterministic per ore, so a block looks the same every time it streams in
-- and two players see the same rock.
local function hash32(s: string): number
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (h * 16777619) % 4294967296
	end
	return h
end

local function rng(seed: number)
	local s = seed % 2147483647
	if s <= 0 then
		s = 1
	end
	return function()
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

type Px = { r: number, g: number, b: number, a: number }

local function shade(c: Color3, towards: number, amt: number): Px
	return {
		r = math.clamp(lerp(c.R * 255, towards, amt), 0, 255),
		g = math.clamp(lerp(c.G * 255, towards, amt), 0, 255),
		b = math.clamp(lerp(c.B * 255, towards, amt), 0, 255),
		a = 255,
	}
end

--------------------------------------------------------------------------------
-- CANVAS
--------------------------------------------------------------------------------
local Canvas = {}
Canvas.__index = Canvas

local function newCanvas()
	local buf = buffer.create(SIZE * SIZE * 4)
	-- Transparent, so the host block's own colour and material show through
	-- everywhere the ore is not.
	return setmetatable({ buf = buf }, Canvas)
end

function Canvas:set(x: number, y: number, p: Px)
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE then
		return
	end
	local o = ((y * SIZE) + x) * 4
	buffer.writeu8(self.buf, o + 0, math.floor(p.r))
	buffer.writeu8(self.buf, o + 1, math.floor(p.g))
	buffer.writeu8(self.buf, o + 2, math.floor(p.b))
	buffer.writeu8(self.buf, o + 3, math.floor(p.a))
end

--[[
	A nodule: a solid block with a two-pixel lit edge up and left and a shaded
	one down and right. `squareness` of 1 is an axis-aligned block, 0 a
	diamond; crystals sit near 0 and metal near 1, which is the whole visual
	difference between a nugget and a facet.
]]
function Canvas:nodule(cx: number, cy: number, r: number, body: Px, lit: Px, dark: Px, squareness: number)
	local ri = math.max(1, math.floor(r))
	for dy = -ri, ri do
		for dx = -ri, ri do
			local inside
			if squareness >= 0.5 then
				inside = math.max(math.abs(dx), math.abs(dy)) <= ri
			else
				inside = (math.abs(dx) + math.abs(dy)) <= ri
			end
			if inside then
				local edge = (dx <= -ri + 1) or (dy <= -ri + 1)
				local backEdge = (dx >= ri - 1) or (dy >= ri - 1)
				self:set(cx + dx, cy + dy, edge and lit or (backEdge and dark or body))
			end
		end
	end
end

--------------------------------------------------------------------------------
-- STYLE
--------------------------------------------------------------------------------
--[[
	Chosen from the same two fields oreHardness reads, so look and feel agree.
	A `glow` colour on the row wins, because an ore that emits light should
	read as emitting light whatever it is made of.
]]
function MineOreFace.styleOf(ore: any): string
	if type(ore) ~= "table" then
		return "rock"
	end
	if typeof(ore.glow) == "Color3" then
		return "glow"
	end
	local met = math.clamp(tonumber(ore.met) or 0, 0, 1)
	local rough = math.clamp(tonumber(ore.rough) or 0.9, 0, 1)
	if met >= 0.5 then
		return "metal"
	elseif rough <= 0.45 then
		return "crystal"
	end
	return "rock"
end

-- count, radius lo/hi, squareness, how bright the glint is
local STYLE = {
	metal = { n = 5, lo = 6, hi = 10, square = 1, glint = 1.0 },
	crystal = { n = 7, lo = 5, hi = 9, square = 0, glint = 0.8 },
	glow = { n = 6, lo = 5, hi = 9, square = 0, glint = 1.0 },
	rock = { n = 12, lo = 2, hi = 4, square = 1, glint = 0 },
}

--------------------------------------------------------------------------------
-- BUILD
--------------------------------------------------------------------------------
local cache: { [string]: any } = {}

function MineOreFace.image(ore: any)
	if type(ore) ~= "table" or type(ore.id) ~= "string" then
		return nil
	end
	if MineOreFace.PLAIN[ore.id] then
		return nil
	end
	local hit = cache[ore.id]
	if hit ~= nil then
		return hit or nil
	end

	local colour = (typeof(ore.color) == "Color3") and ore.color or Color3.fromRGB(170, 170, 180)
	local style = MineOreFace.styleOf(ore)
	local S = STYLE[style] or STYLE.rock

	local body = shade(colour, 0, 0)
	local lit = shade(colour, 255, 0.42)
	local dark = shade(colour, 0, 0.45)

	local c = newCanvas()
	local rand = rng(hash32(ore.id))

	--[[
		Crowded toward the middle, never touching the edge. A nodule that runs
		off the side of the face lines up with the one on the neighbouring
		block and the two read as a seam across the wall -- which is the other
		half of what looked glitchy.
	]]
	local mid = SIZE / 2
	for i = 1, S.n do
		local r = math.floor(lerp(S.lo, S.hi, rand()))
		local ang = rand() * math.pi * 2
		local spread = (SIZE * 0.22) * math.sqrt(rand())
		local cx = math.floor(mid + math.cos(ang) * spread)
		local cy = math.floor(mid + math.sin(ang) * spread)
		-- keep the whole nodule inside the face
		cx = math.clamp(cx, r + 2, SIZE - r - 3)
		cy = math.clamp(cy, r + 2, SIZE - r - 3)
		c:nodule(cx, cy, r, body, lit, dark, S.square)

		-- One hard glint on the first and biggest, not on every lump: a face
		-- where everything shines reads as noise rather than as metal.
		if i == 1 and S.glint > 0 then
			local g = {
				r = math.clamp(255 * S.glint, 0, 255),
				g = math.clamp(255 * S.glint, 0, 255),
				b = math.clamp(255 * S.glint, 0, 255),
				a = 255,
			}
			c:set(cx - math.floor(r * 0.4), cy - math.floor(r * 0.4), g)
			c:set(cx - math.floor(r * 0.4) + 1, cy - math.floor(r * 0.4), g)
			c:set(cx - math.floor(r * 0.4), cy - math.floor(r * 0.4) + 1, g)
		end
	end

	--[[
		A glowing ore gets a soft halo under the facets. Drawn as low-alpha
		rings rather than a solid wash, so the block underneath still shows and
		the ore does not turn into a bright blob.
	]]
	if style == "glow" and typeof(ore.glow) == "Color3" then
		local gl = ore.glow
		for ring = 1, 3 do
			local rr = 13 + ring * 4
			local a = 90 - ring * 25
			for deg = 0, 359, 3 do
				local x = math.floor(mid + math.cos(math.rad(deg)) * rr)
				local y = math.floor(mid + math.sin(math.rad(deg)) * rr)
				local o = ((math.clamp(y, 0, SIZE - 1) * SIZE) + math.clamp(x, 0, SIZE - 1)) * 4
				-- only where nothing has been drawn, so the halo sits behind
				if buffer.readu8(c.buf, o + 3) == 0 then
					c:set(x, y, { r = gl.R * 255, g = gl.G * 255, b = gl.B * 255, a = a })
				end
			end
		end
	end

	local okImg, img = pcall(function()
		return AssetService:CreateEditableImage({ Size = Vector2.new(SIZE, SIZE) })
	end)
	if not okImg or not img then
		cache[ore.id] = false
		return nil
	end
	local okW = pcall(function()
		img:WritePixelsBuffer(Vector2.zero, Vector2.new(SIZE, SIZE), c.buf)
	end)
	if not okW then
		cache[ore.id] = false
		return nil
	end
	cache[ore.id] = img
	return img
end

--[[
	Hang the face on all six sides.

	Safe to call twice: anything already named OreFace goes first, so a block
	that streams in and is skinned again does not end up with twelve decals
	fighting over the same side. That doubling was visible as a darkening on
	re-entered chunks.
]]
function MineOreFace.apply(part: BasePart, ore: any): boolean
	for _, d in ipairs(part:GetChildren()) do
		if d.Name == "OreFace" then
			d:Destroy()
		end
	end
	if type(ore) ~= "table" or MineOreFace.PLAIN[tostring(ore.id)] then
		-- Plain by design. The clear above still runs, so flipping an ore into
		-- PLAIN strips faces it already had.
		return false
	end
	local img = MineOreFace.image(ore)
	if not img then
		return false
	end
	local content = Content.fromObject(img)
	for _, face in ipairs(FACES) do
		local d = Instance.new("Decal")
		d.Name = "OreFace"
		d.Face = face
		d.TextureContent = content
		d.Parent = part
	end
	return true
end

return MineOreFace
