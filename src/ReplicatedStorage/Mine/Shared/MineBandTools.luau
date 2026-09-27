-- Band chest forever-tools ONLY (not shop).
-- 3 bands (a shallow / b mid / c deep) × 2–3 tools × 10 zones = 80.
-- Power tracks band-exit dirt so they stay relevant in that band.
-- Dropped from zone chest opens in the matching band (see MineServer.rollChestTool).

local Depth = require(script.Parent:WaitForChild("MineDepth"))

local MineBandTools = {}

local ZONE_ORDER = {
	"meadow", "sunscar", "mistreef", "arcwork", "bloodmoon",
	"eclipse", "riftmarch", "starfall", "mythral", "primordium",
}

local BAND_EXIT_HP = {
	shallow = 5500,
	mid = 320000,
	deep = 18000000,
}

-- Forever chest tools used to be ~band-exit HP (Briarpick ~4950 in meadow),
-- which deleted zone-1 dirt. Scale to a fraction of exit so they stay ahead
-- of early shop rungs without skipping the whole band.
local BAND_POWER_SCALE = 0.12

local BAND_SLOTS = {
	-- Forever tools: Rare floor. Find chance is global (MineTools.TOOL_RARITY_FIND).
	-- Shallow: pick Rare, drill Epic, bomb Legendary
	-- Mid:     pick Epic, drill Legendary
	-- Deep:    pick Mythic, drill Divine, bomb Exotic
	shallow = {
		{ key = "pick", family = "pickaxe", rate = 2.9, powerMul = 0.90, rarity = "Rare" },
		{ key = "drill", family = "drill", width = 1, cells = 1, shape = "down", axis = "down", turn = 1.1, rate = 3.6, powerMul = 1.55, rarity = "Epic" },
		{ key = "bomb", family = "explosive", bombs = 1, pattern = "splash", radius = 1, cooldown = 2.7, rate = 1, powerMul = 2.60, rarity = "Legendary" },
	},
	mid = {
		{ key = "pick", family = "pickaxe", rate = 3.0, powerMul = 1.05, rarity = "Epic" },
		{ key = "drill", family = "drill", width = 2, cells = 4, shape = "down", axis = "down", turn = 1.0, rate = 3.9, powerMul = 0.58, rarity = "Legendary" },
	},
	deep = {
		{ key = "pick", family = "pickaxe", rate = 3.1, powerMul = 0.95, rarity = "Mythic" },
		{ key = "drill", family = "drill", width = 1, cells = 1, shape = "dir", axis = "aim", turn = 0, rate = 4.2, special = "zeroturn", powerMul = 1.65, rarity = "Divine" },
		{ key = "bomb", family = "explosive", bombs = 3, pattern = "cluster", radius = 1, cooldown = 3.0, rate = 1, powerMul = 2.75, rarity = "Exotic" },
	},
}

local NAMES = {
	meadow = {
		shallow = { pick = "BoomAdze", drill = "Venom Rockbit", bomb = "ObsidianUrn" },
		mid = { pick = "Cinder Cutter", drill = "WraithSpike" },
		deep = { pick = "BossPike", drill = "TidalGimlet", bomb = "RoadPack" },
	},
	sunscar = {
		shallow = { pick = "Crimson Piercer", drill = "ScarletSpinner", bomb = "WeaveFlask" },
		mid = { pick = "TallChopper", drill = "ArchScrew" },
		deep = { pick = "TallScraper", drill = "DriftDirtbit", bomb = "DeepBrick" },
	},
	mistreef = {
		shallow = { pick = "SavageSplitter", drill = "GraniteBit", bomb = "VolcanicShell" },
		mid = { pick = "BrutalHook", drill = "ScarletShaft" },
		deep = { pick = "TidalSlicer", drill = "ScarletCorer", bomb = "HollowBomb" },
	},
	arcwork = {
		shallow = { pick = "Crimson Borer", drill = "MouthGimlet", bomb = "BindDet" },
		mid = { pick = "WildTalon", drill = "GlyphDrill" },
		deep = { pick = "Gilded Hook", drill = "CrestTwister", bomb = "DarkShell2" },
	},
	bloodmoon = {
		shallow = { pick = "HardPiercer", drill = "WraithSpiral", bomb = "AshenFuse" },
		mid = { pick = "Fang Spade", drill = "GranitePiercer" },
		deep = { pick = "Keen Claw", drill = "Onyx Spire", bomb = "GlyphDrum" },
	},
	eclipse = {
		shallow = { pick = "WeaveRipper", drill = "Cinder Carbide", bomb = "BossKeg" },
		mid = { pick = "Span Borer", drill = "Cap Orebit" },
		deep = { pick = "Prime Ripper", drill = "Void Spiral", bomb = "TidalPack" },
	},
	riftmarch = {
		shallow = { pick = "Prime Cutter", drill = "Feral Carbide", bomb = "TallPack" },
		mid = { pick = "SpikeHacker", drill = "HollowTwist" },
		deep = { pick = "ObsidianPick", drill = "NailDrill", bomb = "ThornCartridge" },
	},
	starfall = {
		shallow = { pick = "BossSpike", drill = "ArchRockbit", bomb = "ArchBoomjar" },
		mid = { pick = "SpikeWedge", drill = "WraithShaft" },
		deep = { pick = "Wild Hook", drill = "BrightBore", bomb = "WideCap" },
	},
	mythral = {
		shallow = { pick = "ThornScoop", drill = "Crown Orebit", bomb = "BossWarhead" },
		mid = { pick = "HollowAxe", drill = "BossWriggle" },
		deep = { pick = "BindSlicer", drill = "BrightWriggle", bomb = "Gilded Jar" },
	},
	primordium = {
		shallow = { pick = "ThornHook", drill = "BlightPiercer", bomb = "BrutalCask" },
		mid = { pick = "SlagAxe", drill = "Gilded Auger" },
		deep = { pick = "Span Fang", drill = "RoadAuger", bomb = "WraithCharge" },
	},
}

local BAND_LABEL = { shallow = "Surface", mid = "Deeprock", deep = "Shadowzone" }

local LIST = {}
local BY_ZONE_BAND = {}
local BY_ID = {}

local function copyFam(slot)
	local row = {
		family = slot.family,
		rate = slot.rate,
		cells = slot.cells or 1,
		shape = slot.shape or (slot.family == "pickaxe" and "melee" or nil),
	}
	if slot.width then row.width = slot.width end
	if slot.axis then row.axis = slot.axis end
	if slot.turn ~= nil then row.turn = slot.turn end
	if slot.bombs then row.bombs = slot.bombs end
	if slot.pattern then row.pattern = slot.pattern end
	if slot.radius then row.radius = slot.radius end
	if slot.cooldown then row.cooldown = slot.cooldown end
	if slot.special then row.special = slot.special end
	return row
end

for zi, zoneId in ipairs(ZONE_ORDER) do
	local mult = Depth.zoneMult(zi)
	local zoneNames = NAMES[zoneId] or {}
	for _, band in ipairs({ "shallow", "mid", "deep" }) do
		local exitHp = (BAND_EXIT_HP[band] or 5500) * mult
		local slots = BAND_SLOTS[band]
		local bandNames = zoneNames[band] or {}
		-- One place that answers "what power does this slot get", so the blast
		-- tuner and the row itself cannot drift apart.
		local function powerFor(sl)
			local pw = math.max(3, math.floor(exitHp * sl.powerMul * BAND_POWER_SCALE + 0.5))
			-- Zones 1-4 chest tools were skipping the shop ladder. Later zones stay.
			if zi <= 4 then
				local scale = 0.80
				if band == "shallow" then
					-- One scale for every family. Splitting it (pick 0.20, everything
					-- else 0.12) quietly dropped zone 1-4 chest drills to 1.03x their
					-- own band's pick -- a rare drop that was not an upgrade.
					scale = 0.20
				elseif band == "mid" then
					scale = 0.72
				end
				pw = math.max(3, math.floor(pw * scale + 0.5))
			end
			return pw
		end
		local pickPower
		for _, sl in ipairs(slots) do
			if sl.family == "pickaxe" then
				pickPower = powerFor(sl)
			end
		end
		for _, slot in ipairs(slots) do
			local power = powerFor(slot)
			local name = bandNames[slot.key] or (zoneId .. " " .. slot.key)
			local row = copyFam(slot)
			row.id = zoneId .. "_" .. band .. "_" .. slot.key
			row.name = name
			row.modelName = name
			row.zoneId = zoneId
			row.band = band
			row.power = power
			-- Explicit rarity; find chance is global (same Epic % every zone/layer).
			local ToolsMod = nil
			do
				local okT, T = pcall(require, script.Parent:WaitForChild("MineTools"))
				if okT then ToolsMod = T end
			end
			local rar = (ToolsMod and ToolsMod.normalizeToolRarity and ToolsMod.normalizeToolRarity(slot.rarity))
				or slot.rarity or "Rare"
			local floor = (ToolsMod and ToolsMod.CHEST_RARITY_FLOOR) or "Rare"
			local rank = ToolsMod and ToolsMod.RARITY_RANK
			if rank and (rank[rar] or 0) < (rank[floor] or 3) then
				rar = floor
			end
			row.rarity = rar
			row.rarityId = rar
			row.drop = (ToolsMod and ToolsMod.TOOL_RARITY_FIND and ToolsMod.TOOL_RARITY_FIND[rar]) or slot.drop or 0.006
			row.source = "chest"
			row.chest = "band:" .. zoneId .. ":" .. band
			local defBlurb = ToolsMod and ToolsMod.rarityDef and ToolsMod.rarityDef(rar)
			row.blurb = (defBlurb and defBlurb.blurb and (BAND_LABEL[band] .. " · " .. defBlurb.blurb))
				or (BAND_LABEL[band] .. " forever tool · " .. zoneId)
			if row.family == "explosive" then
				local ok, Tools = pcall(require, script.Parent:WaitForChild("MineTools"))
				if ok and Tools and Tools.tuneExplosive then
					-- Against the band's PICK, not against itself: handing the
					-- charge its own power normalised every bomb to 4x ITSELF,
					-- which is why band charges landed 7-30x a same-band pick.
					Tools.tuneExplosive(row, pickPower or power)
				end
			end
			table.insert(LIST, row)
			BY_ID[row.id] = row
			local bk = zoneId .. "|" .. band
			BY_ZONE_BAND[bk] = BY_ZONE_BAND[bk] or {}
			table.insert(BY_ZONE_BAND[bk], row)
		end
	end
end

MineBandTools.LIST = LIST
MineBandTools.ZONE_ORDER = ZONE_ORDER
MineBandTools.NAMES = NAMES
MineBandTools.CHEST_ONLY = true

function MineBandTools.forZoneBand(zoneId, band)
	band = tostring(band or "shallow")
	if band == "a" or band == "surface" then band = "shallow" end
	if band == "b" or band == "deeprock" then band = "mid" end
	if band == "c" or band == "shadowzone" then band = "deep" end
	return BY_ZONE_BAND[tostring(zoneId) .. "|" .. band] or {}
end

function MineBandTools.forZoneSection(zoneId, sectionId)
	local sec = nil
	for _, s in ipairs(Depth.SECTIONS or {}) do
		if s.id == sectionId then sec = s break end
	end
	return MineBandTools.forZoneBand(zoneId, sec and sec.band or "shallow")
end

function MineBandTools.forZoneLayer(zoneId, layer)
	local band = Depth.bandForLayer and Depth.bandForLayer(layer) or "shallow"
	return MineBandTools.forZoneBand(zoneId, band)
end

function MineBandTools.byId(id)
	return BY_ID[tostring(id or "")]
end

function MineBandTools.forZone(zoneId)
	zoneId = tostring(zoneId or "")
	local out = {}
	for _, t in ipairs(LIST) do
		if t.zoneId == zoneId then
			table.insert(out, t)
		end
	end
	return out
end

function MineBandTools.counts()
	return {
		total = #LIST,
		perZone = 8,
		zones = #ZONE_ORDER,
		shallow = 3,
		mid = 2,
		deep = 3,
		section = 0,
	}
end

-- and a charge in three sections out of five. Old band tools stay in byId so
-- owned picks still equip.
do
	-- Drill and charge power are both derived from the section pick's, so the
	-- family ratios hold at every depth instead of only in the middle.
	local SECTION_DRILL_VS_PICK = 2.2
	local FAM = {
		-- Picks never below Rare. Section depth only climbs the ladder.
		{ key = "pick", family = "pickaxe", rate = 1.8, hits = 8, shape = "melee",
			rarities = { "Rare", "Rare", "Epic", "Epic", "Legendary" } },
		{ key = "drill", family = "drill", rate = 1.2, hits = 30, shape = "down", width = 5, cells = 25, axis = "down",
			rarities = { "Epic", "Epic", "Legendary", "Mythic", "Divine" } },
		{ key = "charge", family = "explosive", nameKey = "bomb", rate = 1,
			rarities = { "Legendary", "Legendary", "Mythic", "Divine", "Exotic" } },
	}
	local function sectionRarity(fam, si, nSec)
		local ladder = fam.rarities or { "Rare" }
		nSec = math.max(1, nSec or #ladder)
		local idx = math.clamp(math.ceil((si / nSec) * #ladder), 1, #ladder)
		return ladder[idx] or "Rare"
	end
	-- Flavour only: tuneExplosive rewrites power against the section's pick
	-- whichever shape this is, so every charge lands at EXPLOSIVE_VS_PICK.
	local CHARGE_SHAPE = {
		shallow = { bombs = 1, pattern = "splash", radius = 1, cooldown = 2.7 },
		mid = { bombs = 1, pattern = "sphere", radius = 1, cooldown = 2.4 },
		deep = { bombs = 2, pattern = "cluster", radius = 1, cooldown = 3.0 },
	}
	local TOKEN = {
		meadow = "Briar", sunscar = "Quartz", mistreef = "Mist", arcwork = "Brass",
		bloodmoon = "Crimson", eclipse = "HardCell", riftmarch = "Rift",
		starfall = "Star", mythral = "Myth", primordium = "Prime",
	}
	local TAIL = { pick = "pick", drill = "drill", charge = "charge" }
	local SECTION_LIST = {}
	do
		local snap = script.Parent:WaitForChild("MineDepth"):Clone()
		snap.Name = "_BandDepthSnap"
		snap.Parent = script
		local okS, DepthFresh = pcall(require, snap)
		snap:Destroy()
		if okS and DepthFresh then
			Depth = DepthFresh
		end
	end
	-- NAMES carries a `bomb` only for shallow and deep, so a mid-band charge
	-- has no name of its own. Fall through the other bands rather than ship
	-- 228 tools with no model.
	local function modelNameFor(zoneId, band, key)
		local nz = NAMES[zoneId] or {}
		return (nz[band] or {})[key]
			or (nz.shallow or {})[key]
			or (nz.deep or {})[key]
			or (nz.mid or {})[key]
	end
	for zi, zoneId in ipairs(ZONE_ORDER) do
		for si, sec in ipairs(Depth.SECTIONS or {}) do
			local mid = math.floor(((sec.layers and sec.layers[1] or 1) + (sec.layers and sec.layers[2] or 1)) / 2)
			local hp = (Depth.dirtHp and Depth.dirtHp(zi, mid)) or math.max(1, math.floor((sec.dirtHp or 10) * 2))
			local pickPower = math.max(8, math.floor(hp / 8 + 0.5))
			for _, fam in ipairs(FAM) do
				-- Charges are the rare third family: three sections in five,
				-- which puts ~450 in the pool against 750 picks and 750 drills.
				local isCharge = fam.family == "explosive"
				if not isCharge or ((zi + si) % 5) < 3 then
					local shape = isCharge
						and (CHARGE_SHAPE[tostring(sec.band)] or CHARGE_SHAPE.shallow)
						or nil
					local power
					if fam.key == "pick" or isCharge then
						power = pickPower
					else
						power = math.max(1, math.floor(
							pickPower * SECTION_DRILL_VS_PICK / math.max(1, fam.cells or 1) + 0.5))
					end
					local token = TOKEN[zoneId] or "Deep"
					local nSec = #(Depth.SECTIONS or {})
					local rar = sectionRarity(fam, si, nSec)
					local ToolsMod = nil
					do
						local okT, T = pcall(require, script.Parent:WaitForChild("MineTools"))
						if okT then ToolsMod = T end
					end
					if ToolsMod and ToolsMod.normalizeToolRarity then
						rar = ToolsMod.normalizeToolRarity(rar) or rar
					end
					local drop = (ToolsMod and ToolsMod.TOOL_RARITY_FIND and ToolsMod.TOOL_RARITY_FIND[rar]) or 0.006
					local defBlurb = ToolsMod and ToolsMod.rarityDef and ToolsMod.rarityDef(rar)
					local row = {
						id = zoneId .. "_" .. tostring(sec.id) .. "_" .. fam.key,
						name = tostring(sec.name or sec.id) .. " " .. token .. (TAIL[fam.key] or fam.key),
						modelName = modelNameFor(zoneId, sec.band, fam.nameKey or fam.key),
						family = fam.family,
						zoneId = zoneId,
						zoneIndex = zi,
						sectionId = sec.id,
						band = sec.band,
						power = power,
						rate = fam.rate,
						drop = drop,
						shape = fam.shape,
						width = fam.width,
						cells = fam.cells,
						axis = fam.axis,
						bombs = shape and shape.bombs or nil,
						pattern = shape and shape.pattern or nil,
						radius = shape and shape.radius or nil,
						cooldown = shape and shape.cooldown or nil,
						source = "section",
						rarity = rar,
						rarityId = rar,
						blurb = (defBlurb and defBlurb.blurb and (tostring(sec.name or sec.id) .. " · " .. defBlurb.blurb))
							or ((rar .. " chest tool for ") .. tostring(sec.name or sec.id)),
					}
					if isCharge then
						local okT, T2 = pcall(require, script.Parent:WaitForChild("MineTools"))
						if okT and T2 and T2.tuneExplosive then
							T2.tuneExplosive(row, pickPower)
						end
					end
					BY_ID[row.id] = row
					table.insert(LIST, row)
					table.insert(SECTION_LIST, row)
				end
			end
		end
	end

	function MineBandTools.forZoneLayer(zoneId, layer)
		local sec = Depth.sectionFor and Depth.sectionFor(layer)
		local sid = sec and sec.id
		local out = {}
		for _, t in ipairs(SECTION_LIST) do
			if t.zoneId == zoneId and t.sectionId == sid then
				table.insert(out, t)
			end
		end
		if #out > 0 then
			return out
		end
		local band = Depth.bandForLayer and Depth.bandForLayer(layer) or "shallow"
		return MineBandTools.forZoneBand(zoneId, band)
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
			require(src).apply(MineBandTools)
		end)
	end
end
return MineBandTools
