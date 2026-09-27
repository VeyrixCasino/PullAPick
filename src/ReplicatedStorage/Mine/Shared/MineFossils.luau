-- MineFossils: paired zone collections (1-2, 3-4, 5-6, 7-8, 9-10).
-- Each pair shares one fossil set. 5 recipes per band (shallow/mid/deep) =
-- pick, drill, bomb, plus 2 extras. Placeholder names — see ZONE_BAND_CONTENT.md.

local MineFossils = {}

MineFossils.FOSSIL_LAYER_CHANCE = 0.10
MineFossils.HP_MULT = 2
MineFossils.MAX_LAYER = 2500
MineFossils.ZONE_HP_MULT = 6

local function clamp01(x)
	return math.clamp(x, 0, 1)
end

local function zoneMult(zi)
	zi = math.max(1, math.floor(tonumber(zi) or 1))
	return MineFossils.ZONE_HP_MULT ^ (zi - 1)
end

-- Shared collections. Digging either zone rolls the same recipe ids.
MineFossils.PAIRS = {
	-- powerZi is the earlier zone. zi stays the higher one for sell-gems only,
	-- so a meadow fossil is not a sunscar tool and gem payouts do not move.
	{ id = "pair_grove", zones = { "meadow", "sunscar" }, zi = 2, powerZi = 1, label = "Grove pair (z1-2)" },
	{ id = "pair_tide", zones = { "mistreef", "arcwork" }, zi = 4, powerZi = 3, label = "Tide pair (z3-4)" },
	{ id = "pair_scarlet", zones = { "bloodmoon", "eclipse" }, zi = 6, label = "Scarlet pair (z5-6)" },
	{ id = "pair_fracture", zones = { "riftmarch", "starfall" }, zi = 8, label = "Fracture pair (z7-8)" },
	{ id = "pair_myth", zones = { "mythral", "primordium" }, zi = 10, label = "Myth pair (z9-10)" },
}

MineFossils.ZONE_TO_PAIR = {}
for _, pair in ipairs(MineFossils.PAIRS) do
	for _, zid in ipairs(pair.zones) do
		MineFossils.ZONE_TO_PAIR[zid] = pair
	end
end

-- 5 slots per band: core trio + 2 extras.
local BANDS = {
	{
		id = "shallow", unlock = 1, pieces = 5, rarity = "Common",
		slots = {
			{ key = "pick", family = "pickaxe", special = "none", hp = 2800 },
			{ key = "drill", family = "drill", special = "down 1", hp = 5500 },
			{ key = "bomb", family = "explosive", special = "disc", hp = 5500 },
			{ key = "pick2", family = "pickaxe", special = "none", hp = 3500 },
			{ key = "drill2", family = "drill", special = "down 1", hp = 7000 },
		},
	},
	{
		id = "mid", unlock = 501, pieces = 6, rarity = "Rare",
		slots = {
			{ key = "pick", family = "pickaxe", special = "multi-tap", hp = 70000 },
			{ key = "drill", family = "drill", special = "down 2", hp = 150000 },
			{ key = "bomb", family = "explosive", special = "disc+slow", hp = 320000 },
			{ key = "pick2", family = "pickaxe", special = "multi-tap", hp = 90000 },
			{ key = "bomb2", family = "explosive", special = "splash", hp = 200000 },
		},
	},
	{
		id = "deep", unlock = 1501, pieces = 8, rarity = "Legendary",
		slots = {
			{ key = "pick", family = "pickaxe", special = "echo", hp = 3500000 },
			{ key = "drill", family = "drill", special = "zeroturn lite", hp = 8000000 },
			{ key = "bomb", family = "explosive", special = "cluster", hp = 8000000 },
			{ key = "drill2", family = "drill", special = "zeroturn lite", hp = 12000000 },
			{ key = "bomb2", family = "explosive", special = "blackhole-lite", hp = 18000000 },
		},
	},
}

-- Meadow/grove legacy ids so existing piece/tool saves still resolve.
local LEGACY_IDS = {
	["pair_grove|shallow|pick"] = "seismic_reaver",
	["pair_grove|shallow|drill"] = "wraithorebit",
	["pair_grove|mid|pick"] = "spikeslicer",
	["pair_grove|mid|bomb"] = "tallurn",
	["pair_grove|deep|drill"] = "yardspiral",
	["pair_grove|deep|bomb"] = "archcask",
}

local LEGACY_NAMES = {
	rustpick = "Seismic Reaver",
	muckwedge = "WraithOrebit",
	ripsaw = "SpikeSlicer",
	sledge = "TallUrn",
	deepbore = "YardSpiral",
	sinkhole = "ArchCask",
}

local LIST = {}
for _, pair in ipairs(MineFossils.PAIRS) do
	local mult = zoneMult(pair.powerZi or pair.zi)
	for _, band in ipairs(BANDS) do
		for _, slot in ipairs(band.slots) do
			local legacyKey = pair.id .. "|" .. band.id .. "|" .. slot.key
			local id = LEGACY_IDS[legacyKey] or (pair.id .. "_" .. band.id .. "_" .. slot.key)
			local named = LEGACY_NAMES[id]
			local bandTitle = ({ shallow = "Shallow", mid = "Mid", deep = "Deep" })[band.id] or band.id
			local famTitle = ({ pickaxe = "Pick", drill = "Drill", explosive = "Bomb" })[slot.family] or slot.key
			-- Until a real collectable name lands, show band + family — never "UNNAMED".
			local displayName = named or (bandTitle .. " Fossil " .. famTitle)
			local hp = slot.hp * mult
			-- Zones 1-4: a finished fossil should sit near that band's shop pick,
			-- not skip the band. Sell gems still use pair.zi above.
			local bandScale = 1
			if pair.powerZi then
				if band.id == "shallow" then
					bandScale = 0.055
				elseif band.id == "mid" then
					bandScale = 0.32
				else
					bandScale = 0.32
				end
			end
			local pMin = math.max(2, math.floor(hp * 0.22 * bandScale + 0.5))
			local pMax = math.max(pMin + 1, math.floor(hp * 0.48 * bandScale + 0.5))
			local dustMin = math.max(20, math.floor(pMin * 4))
			local dustMax = math.max(dustMin + 1, math.floor(pMax * 8))
			local gemMin = math.max(1, math.floor(pair.zi * (band.id == "deep" and 40 or band.id == "mid" and 12 or 3)))
			local gemMax = math.max(gemMin + 1, math.floor(gemMin * (band.id == "deep" and 8 or 5)))
			table.insert(LIST, {
				id = id,
				name = displayName,
				needsName = named == nil,
				family = slot.family,
				pieces = band.pieces,
				rarity = band.rarity,
				unlock = band.unlock,
				pairId = pair.id,
				zones = pair.zones,
				zoneIndex = pair.zi,
				band = band.id,
				powerMin = pMin,
				powerMax = pMax,
				special = slot.special,
				sellDustMin = dustMin,
				sellDustMax = dustMax,
				sellGemsMin = gemMin,
				sellGemsMax = gemMax,
			})
		end
	end
end

MineFossils.RECIPES = LIST
MineFossils.BY_ID = {}
MineFossils.BY_ZONE_BAND = {}
MineFossils.BY_PAIR_BAND = {}

for _, recipe in ipairs(LIST) do
	MineFossils.BY_ID[recipe.id] = recipe
	local pairKey = recipe.pairId .. "|" .. recipe.band
	MineFossils.BY_PAIR_BAND[pairKey] = MineFossils.BY_PAIR_BAND[pairKey] or {}
	table.insert(MineFossils.BY_PAIR_BAND[pairKey], recipe)
	for _, zid in ipairs(recipe.zones) do
		local key = zid .. "|" .. recipe.band
		MineFossils.BY_ZONE_BAND[key] = MineFossils.BY_ZONE_BAND[key] or {}
		-- share the same recipe row across both zones in the pair
		local bag = MineFossils.BY_ZONE_BAND[key]
		local dup = false
		for _, existing in ipairs(bag) do
			if existing.id == recipe.id then dup = true break end
		end
		if not dup then
			table.insert(bag, recipe)
		end
	end
end

MineFossils.LEGACY_ALIAS = {
	amberpick = "seismic_reaver",
	stutter = "wraithorebit",
	needle = "wraithorebit",
	kilnbomb = "tallurn",
	corkscrew = "spikeslicer",
	pike = "spikeslicer",
	tarbomb = "tallurn",
	tricharge = "tallurn",
	depthpike = "yardspiral",
	sunglare = "archcask",
}

function MineFossils.bandForLayer(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	if layer <= 500 then
		return "shallow"
	elseif layer <= 1500 then
		return "mid"
	end
	return "deep"
end

function MineFossils.pairForZone(zoneId)
	zoneId = tostring(zoneId or "meadow")
	if zoneId == "bigbang" then
		zoneId = "meadow"
	end
	return MineFossils.ZONE_TO_PAIR[zoneId]
end

function MineFossils.recipesFor(zoneId, band)
	zoneId = tostring(zoneId or "meadow")
	if zoneId == "bigbang" then
		zoneId = "meadow"
	end
	band = tostring(band or "shallow")
	return MineFossils.BY_ZONE_BAND[zoneId .. "|" .. band]
		or MineFossils.BY_ZONE_BAND["meadow|" .. band]
		or {}
end

function MineFossils.recipeRarity(id)
	local recipe = MineFossils.recipe(id)
	return recipe and recipe.rarity or "Common"
end

function MineFossils.recipe(id)
	id = tostring(id or "")
	id = MineFossils.LEGACY_ALIAS[id] or id
	return MineFossils.BY_ID[id]
end

function MineFossils.rollIdentity(layer, rng, zoneId)
	rng = rng or Random.new()
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	zoneId = tostring(zoneId or "meadow")
	local band = MineFossils.bandForLayer(layer)
	local pool = MineFossils.recipesFor(zoneId, band)
	if #pool == 0 then
		pool = MineFossils.recipesFor("meadow", band)
	end
	if #pool == 0 then
		return "seismic_reaver"
	end
	return pool[rng:NextInteger(1, #pool)].id
end

function MineFossils.grade(pieces)
	if type(pieces) ~= "table" or #pieces == 0 then return 0 end
	local sum = 0
	for _, piece in ipairs(pieces) do
		local layer = math.max(1, math.floor(piece.layer or 1))
		local depth = clamp01(layer / MineFossils.MAX_LAYER)
		local quality = piece.qualityRoll or piece.quality
		if quality == nil then quality = 0.5 else quality = clamp01(quality) end
		sum += depth * 0.65 + quality * 0.35
	end
	return clamp01(sum / #pieces)
end

local function bandValue(minV, maxV, grade)
	return math.floor(minV + (maxV - minV) * clamp01(grade) + 0.5)
end

function MineFossils.unnamed()
	local out = {}
	for _, r in ipairs(LIST) do
		if r.needsName or r.name == "UNNAMED" then
			table.insert(out, r.id)
		end
	end
	return out
end

function MineFossils.toolFromPieces(fossilId, pieces)
	local recipe = MineFossils.recipe(fossilId)
	if not recipe then return nil end
	local g = MineFossils.grade(pieces)
	-- id (16-hex instance) is assigned by MineServer on assemble / migrate.
	local tool = {
		fossilId = recipe.id, name = recipe.name, family = recipe.family,
		power = bandValue(recipe.powerMin, recipe.powerMax, g),
		special = recipe.special, grade = g, piecesNeeded = recipe.pieces,
		rarity = recipe.rarity or "Common",
		source = "fossil", fossil = true,
		rate = recipe.family == "drill" and 3.2 or (recipe.family == "explosive" and 1 or 2.8),
	}
	for _, k in ipairs({ "width", "shape", "turn", "axis", "pattern", "radius", "cooldown", "bombs", "tick", "ticks" }) do
		if recipe[k] ~= nil then tool[k] = recipe[k] end
	end
	if tool.family == "pickaxe" then tool.cells = 1; tool.shape = tool.shape or "melee" end
	return tool
end

function MineFossils.sellDust(recipe, grade)
	if type(recipe) == "string" then recipe = MineFossils.recipe(recipe) end
	if not recipe then return 0 end
	return bandValue(recipe.sellDustMin, recipe.sellDustMax, grade or 0)
end

function MineFossils.sellGems(recipe, grade)
	if type(recipe) == "string" then recipe = MineFossils.recipe(recipe) end
	if not recipe then return 0 end
	return bandValue(recipe.sellGemsMin, recipe.sellGemsMax, grade or 0)
end

-- A fossil is dirt with something in it. It takes the colour of the stratum it
-- was dug out of and only shifts a shade, because the whole read is "that block
-- is slightly wrong" -- a tan cube sitting in grey rock is a pickup, not a find.
--
-- The bones are drawn rather than textured. A marketplace decal can be
-- moderated away under you and none of them match this game's art; everything
-- else here (pets, tools, icons) is generated, so this is too. If you do upload
-- a fossil image, set DECAL to its asset id and every face uses that instead --
-- nothing else has to change.
MineFossils.DECAL = ""

local BONE = Color3.fromRGB(226, 214, 186)
local BONE_DEEP = Color3.fromRGB(198, 182, 148)
local FACES = {
	Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left,
	Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom,
}

function MineFossils.look(section)
	-- Follow the stratum, then darken and desaturate a touch so it reads as
	-- denser rock rather than a different material.
	local base = (section and section.color) or Color3.fromRGB(150, 120, 86)
	return {
		color = base:Lerp(Color3.fromRGB(74, 66, 58), 0.22),
		material = Enum.Material.Sandstone,
	}
end

local function bone(parent, x, y, w, h, rot, colour, clear)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(x, y)
	f.Size = UDim2.fromScale(w, h)
	f.Rotation = rot or 0
	f.BackgroundColor3 = colour or BONE
	f.BackgroundTransparency = clear or 0.15
	f.BorderSizePixel = 0
	f.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = f
	return f
end

-- Put the find on the block. Six faces, because you can come at a block from
-- any side, and a fossil you can only see from the front is one you walk past.
-- The identity picks the shape, so two fossils of the same kind look alike and
-- a different kind looks different.
function MineFossils.decorate(part, seed)
	local n = 0
	for ch in tostring(seed or "fossil"):gmatch(".") do
		n = (n + string.byte(ch)) % 3
	end
	for _, face in ipairs(FACES) do
		if MineFossils.DECAL ~= "" then
			local d = Instance.new("Decal")
			d.Face = face
			d.Texture = MineFossils.DECAL
			d.Parent = part
		else
			local gui = Instance.new("SurfaceGui")
			gui.Face = face
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 20
			gui.AlwaysOnTop = false
			gui.Parent = part
			if n == 0 then
				-- Ribcage: a spine with ribs curling off it.
				bone(gui, 0.5, 0.5, 0.07, 0.6, 0, BONE)
				for i = 0, 3 do
					local y = 0.26 + i * 0.16
					bone(gui, 0.36, y, 0.22, 0.05, 18, BONE_DEEP, 0.2)
					bone(gui, 0.64, y, 0.22, 0.05, -18, BONE_DEEP, 0.2)
				end
			elseif n == 1 then
				-- Ammonite: a spiral of shrinking segments.
				for i = 0, 6 do
					local a = i * 0.9
					local r = 0.06 + i * 0.032
					local s = 0.20 - i * 0.021
					bone(gui, 0.5 + math.cos(a) * r, 0.5 + math.sin(a) * r, s, s, 0,
						(i % 2 == 0) and BONE or BONE_DEEP, 0.18)
				end
			else
				-- A single long bone, knuckled at both ends.
				bone(gui, 0.5, 0.5, 0.1, 0.52, 24, BONE)
				bone(gui, 0.39, 0.28, 0.2, 0.16, 0, BONE)
				bone(gui, 0.61, 0.72, 0.2, 0.16, 0, BONE)
			end
		end
	end
end


--[[
	SHARED MODULE -- it cannot reach into ServerStorage.

	This block is written by the tool-rename pass. Its original form was
	require(game.ServerStorage:WaitForChild("ApplyToolRename")), and
	ServerStorage never replicates: on the CLIENT that WaitForChild never
	returns, the require never finishes, and every script that required
	this module -- MineClient included -- stopped dead on that line. No
	HUD, no panels, nothing. The server was unaffected, which is what made
	it look like a UI bug instead of a require that never came back.

	Same rename, same effect, resolved from the copy already sitting in
	Shared. FindFirstChild does not yield, so the worst case is the rename
	is skipped -- not the game failing to start.

	IF THE RENAME PASS REWRITES THIS FILE IT WILL PUT THE OLD LINE BACK.
	The generator needs to emit this form too.
]]
do
	local src = script.Parent:FindFirstChild("ApplyToolRename")
		or game:GetService("ServerStorage"):FindFirstChild("ApplyToolRename")
	if src then
		pcall(function()
			require(src).apply(MineFossils)
		end)
	end
end
return MineFossils
