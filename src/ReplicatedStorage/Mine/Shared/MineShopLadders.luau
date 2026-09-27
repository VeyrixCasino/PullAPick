--[[
	MineShopLadders — buyable tools only (not chest drops).

	Surface shop (every zone): 6 picks + 2 drills + 2 bombs = 10.
	Depth desks a/b/c: 1 pick + 1 drill + 1 bomb each.
	→ 19 per zone · 190 shop tools total.
	A/B/C drill/bomb prices never undercut earlier surface/desk rungs.
	See handoff/launch/TOOL_AND_BAG_COUNTS.md
]]

local shared = script.Parent
local Eco = require(shared:WaitForChild("MineShopEconomy"))
local Tools = require(shared:WaitForChild("MineTools"))

local MineShopLadders = {}

local ZONE_ORDER = {
	"meadow", "sunscar", "mistreef", "arcwork", "bloodmoon",
	"eclipse", "riftmarch", "starfall", "mythral", "primordium",
}

local ZONE_LABEL = {
	meadow = "Meadow", sunscar = "Greyvein", mistreef = "Mistreef",
	arcwork = "Arcwork", bloodmoon = "Bloodmoon", eclipse = "HardCell",
	riftmarch = "Riftmarch", starfall = "Starfall", mythral = "Mythral",
	primordium = "Primordium",
}

local DESK_BAND = {
	surface = "shallow", shallow = "shallow", a = "shallow",
	mid = "mid", deeprock = "mid", b = "mid",
	deep = "deep", shadowzone = "deep", c = "deep",
}

local TRIO = {
	{ key = "pick", family = "pickaxe", rate = 2.9 },
	{ key = "drill", family = "drill", width = 1, cells = 1, shape = "down", axis = "down", turn = 1.15, rate = 3.6 },
	{ key = "bomb", family = "explosive", bombs = 1, pattern = "splash", radius = 1, cooldown = 2.8, rate = 1 },
}

-- Surface shop ladder: mostly picks, weave in drill/bomb.
-- Surface: 6 picks, 2 drills, 2 bombs. NO rotate weave.
local SURFACE_PATTERN = {
	"pick", "pick", "pick", "pick", "pick", "pick",
	"drill", "drill",
	"bomb", "bomb",
}

local LIST = {}
local BY_ZONE_DESK = {}
local BY_ID = {}


local NAMES = {
	-- Meadow surface (6p / 2d / 2b)
	meadow_surface_1_pick = "FangAdze",
	meadow_surface_2_pick = "TrackScoop",
	meadow_surface_3_pick = "NexusCrusher",
	meadow_surface_4_pick = "PhantomAxe",
	meadow_surface_5_pick = "SeismicCleaver2",
	meadow_surface_6_pick = "BossHacker",
	meadow_surface_7_drill = "Prime Spinner",
	meadow_surface_8_drill = "NobleShaft",
	meadow_surface_9_bomb = "AshenBrick",
	meadow_surface_10_bomb = "WraithFlashpot",
	meadow_surface_band_pick = "BossChopper",
	meadow_surface_band_drill = "ThornWriggle",
	meadow_surface_band_bomb = "ArchGrenade",
	meadow_deeprock_pick = "Gilded Tooth",
	meadow_deeprock_drill = "Prime Crownbit",
	meadow_deeprock_bomb = "ThornSpark",
	meadow_shadowzone_pick = "TallCleaver2",
	meadow_shadowzone_drill = "BoomScrew",
	meadow_shadowzone_bomb = "MoltenBoomjar",
	sunscar_surface_1_pick = "BrutalHewer",
	sunscar_surface_2_pick = "TrailSledge",
	sunscar_surface_3_pick = "Fang Wedge",
	sunscar_surface_4_pick = "TallAdze",
	sunscar_surface_5_pick = "BindWedge",
	sunscar_surface_6_pick = "AncientRipper",
	sunscar_surface_7_drill = "BindDeepbit",
	sunscar_surface_8_drill = "BlightAuger",
	sunscar_surface_9_bomb = "BoomVial",
	sunscar_surface_10_bomb = "SpikeUrn",
	sunscar_surface_band_pick = "BoomHatchet",
	sunscar_surface_band_drill = "ArchBorer2",
	sunscar_surface_band_bomb = "DawnFuse",
	sunscar_deeprock_pick = "ShatterSilent",
	sunscar_deeprock_drill = "SlagDirtbit",
	sunscar_deeprock_bomb = "HardDustbin",
	sunscar_shadowzone_pick = "HardBeak",
	sunscar_shadowzone_drill = "BossReamer",
	sunscar_shadowzone_bomb = "BindShell2",
	mistreef_surface_1_pick = "AncientHewer",
	mistreef_surface_2_pick = "ThornTusk",
	mistreef_surface_3_pick = "BrutalCleaver",
	mistreef_surface_4_pick = "MastMattock",
	mistreef_surface_5_pick = "GlyphBar",
	mistreef_surface_6_pick = "Wild Chisel",
	mistreef_surface_7_drill = "BossBore",
	mistreef_surface_8_drill = "NailCorebit",
	mistreef_surface_9_bomb = "RoadMinepot",
	mistreef_surface_10_bomb = "RoadBlast",
	mistreef_surface_band_pick = "BindSpade",
	mistreef_surface_band_drill = "BossDrill",
	mistreef_surface_band_bomb = "SlagDrum",
	mistreef_deeprock_pick = "ClawBind",
	mistreef_deeprock_drill = "JadePiercer",
	mistreef_deeprock_bomb = "IronCanister",
	mistreef_shadowzone_pick = "VenomWedge",
	mistreef_shadowzone_drill = "RawLance",
	mistreef_shadowzone_bomb = "HardGrenade",
	arcwork_surface_1_pick = "DeepSpike",
	arcwork_surface_2_pick = "Phantom Gouge",
	arcwork_surface_3_pick = "NailClaw",
	arcwork_surface_4_pick = "HardRod",
	arcwork_surface_5_pick = "HotSpike",
	arcwork_surface_6_pick = "SpikeBar",
	arcwork_surface_7_drill = "GlyphHelix",
	arcwork_surface_8_drill = "DeepProbe",
	arcwork_surface_9_bomb = "GlyphPot",
	arcwork_surface_10_bomb = "BoundFuse",
	arcwork_surface_band_pick = "SpikeChisel",
	arcwork_surface_band_drill = "NobleRockbit",
	arcwork_surface_band_bomb = "SpikeSpark",
	arcwork_deeprock_pick = "Seismic Chisel",
	arcwork_deeprock_drill = "CobaltSpike",
	arcwork_deeprock_bomb = "HardCask",
	arcwork_shadowzone_pick = "PrismSplitter",
	arcwork_shadowzone_drill = "Cap Rockbit",
	arcwork_shadowzone_bomb = "DeepCell",
	bloodmoon_surface_1_pick = "TallBeak",
	bloodmoon_surface_2_pick = "HollowCrusher",
	bloodmoon_surface_3_pick = "Crimson Spade",
	bloodmoon_surface_4_pick = "SeismicSplitter",
	bloodmoon_surface_5_pick = "Track Sledge",
	bloodmoon_surface_6_pick = "Prime Borer",
	bloodmoon_surface_7_drill = "AncientHelix",
	bloodmoon_surface_8_drill = "WraithTwister",
	bloodmoon_surface_9_bomb = "DarkMineball",
	bloodmoon_surface_10_bomb = "ArchCapsule",
	bloodmoon_surface_band_pick = "WraithBlade",
	bloodmoon_surface_band_drill = "SpikeRigger",
	bloodmoon_surface_band_bomb = "TallOrb",
	bloodmoon_deeprock_pick = "FangGouge",
	bloodmoon_deeprock_drill = "DeepGimlet",
	bloodmoon_deeprock_bomb = "RustJar",
	bloodmoon_shadowzone_pick = "BossHorn",
	bloodmoon_shadowzone_drill = "ScarletTurbine",
	bloodmoon_shadowzone_bomb = "HollowGrenade",
	eclipse_surface_1_pick = "RoadNeedle",
	eclipse_surface_2_pick = "TallHewer",
	eclipse_surface_3_pick = "Phantom Tusk",
	eclipse_surface_4_pick = "TidalWedge",
	eclipse_surface_5_pick = "BossMallet",
	eclipse_surface_6_pick = "Cinder Mallet",
	eclipse_surface_7_drill = "GridDeepbit",
	eclipse_surface_8_drill = "ColdDeep",
	eclipse_surface_9_bomb = "NovaAshcan",
	eclipse_surface_10_bomb = "BossShell2",
	eclipse_surface_band_pick = "ArchSlicer",
	eclipse_surface_band_drill = "Stern Spiral",
	eclipse_surface_band_bomb = "SpikePot",
	eclipse_deeprock_pick = "Fang Spear",
	eclipse_deeprock_drill = "Mesh Gimlet",
	eclipse_deeprock_bomb = "DeepDrum",
	eclipse_shadowzone_pick = "Hot Hammer",
	eclipse_shadowzone_drill = "Open Helix",
	eclipse_shadowzone_bomb = "GlyphBrick",
	riftmarch_surface_1_pick = "OreReaver",
	riftmarch_surface_2_pick = "HardNabber",
	riftmarch_surface_3_pick = "TidalChisel",
	riftmarch_surface_4_pick = "Gilded Hacker",
	riftmarch_surface_5_pick = "BoomMaul",
	riftmarch_surface_6_pick = "KeelGlyph",
	riftmarch_surface_7_drill = "SlagGimlet",
	riftmarch_surface_8_drill = "NexusSpike",
	riftmarch_surface_9_bomb = "BrandOrb",
	riftmarch_surface_10_bomb = "ObsidianGrenade",
	riftmarch_surface_band_pick = "PrismCleaver",
	riftmarch_surface_band_drill = "HollowShaft",
	riftmarch_surface_band_bomb = "SpikeAshcan",
	riftmarch_deeprock_pick = "WraithDigger",
	riftmarch_deeprock_drill = "HardRotor",
	riftmarch_deeprock_bomb = "SlagDet",
	riftmarch_shadowzone_pick = "TidalFang",
	riftmarch_shadowzone_drill = "RoadVortex",
	riftmarch_shadowzone_bomb = "ArchCell",
	starfall_surface_1_pick = "WraithCleaver",
	starfall_surface_2_pick = "BrutalTooth",
	starfall_surface_3_pick = "AzureWraith",
	starfall_surface_4_pick = "SlagSplitter",
	starfall_surface_5_pick = "BoomScraper",
	starfall_surface_6_pick = "ObsidianBar",
	starfall_surface_7_drill = "BoomDeepbit",
	starfall_surface_8_drill = "ColdTall",
	starfall_surface_9_bomb = "ThornDet",
	starfall_surface_10_bomb = "BindUrn",
	starfall_surface_band_pick = "CinderMattock",
	starfall_surface_band_drill = "VeinDawn",
	starfall_surface_band_bomb = "WeaveBrick",
	starfall_deeprock_pick = "SlagChopper",
	starfall_deeprock_drill = "NailGimlet",
	starfall_deeprock_bomb = "TallNuke",
	starfall_shadowzone_pick = "GlyphChopper",
	starfall_shadowzone_drill = "Venom Driver",
	starfall_shadowzone_bomb = "ThornWarhead",
	mythral_surface_1_pick = "BoomReaver",
	mythral_surface_2_pick = "Cinder Talon",
	mythral_surface_3_pick = "BrutalReaver",
	mythral_surface_4_pick = "ThornSpear",
	mythral_surface_5_pick = "BrutalLance",
	mythral_surface_6_pick = "FrozenSplitter",
	mythral_surface_7_drill = "Keen Carbide",
	mythral_surface_8_drill = "TallRockbit",
	mythral_surface_9_bomb = "HardAmpoule",
	mythral_surface_10_bomb = "Keen Mine",
	mythral_surface_band_pick = "BindPick",
	mythral_surface_band_drill = "AncientChuck",
	mythral_surface_band_bomb = "HeavyMineball",
	mythral_deeprock_pick = "ThornPike",
	mythral_deeprock_drill = "PrismTwist",
	mythral_deeprock_bomb = "DeepBurst",
	mythral_shadowzone_pick = "Prime Hacker",
	mythral_shadowzone_drill = "RoadDirtbit",
	mythral_shadowzone_bomb = "BossBrick",
	primordium_surface_1_pick = "WraithChopper",
	primordium_surface_2_pick = "Hot Breaker",
	primordium_surface_3_pick = "WraithSpear",
	primordium_surface_4_pick = "Cap Spear",
	primordium_surface_5_pick = "DeepCrusher",
	primordium_surface_6_pick = "ThornSplitter",
	primordium_surface_7_drill = "Cap Reamer",
	primordium_surface_8_drill = "Seismic Vortex",
	primordium_surface_9_bomb = "BoomCapsule",
	primordium_surface_10_bomb = "PathMinepot",
	primordium_surface_band_pick = "CrownNeedle",
	primordium_surface_band_drill = "Savage Reamer",
	primordium_surface_band_bomb = "BrutalAmpoule",
	primordium_deeprock_pick = "BrutalHacker",
	primordium_deeprock_drill = "JadeProbe",
	primordium_deeprock_bomb = "ThornCanister",
	primordium_shadowzone_pick = "SlagTusk",
	primordium_shadowzone_drill = "Gilded Screw",
	primordium_shadowzone_bomb = "SpikePayload",
}
local DEPTH_OF_DESK = {
	surface = 0, surface_band = 0,
	deeprock = 500, thousand = 1000,
	shadowzone = 1500, twothou = 2000,
}

local function push(row)
	row.minDepth = DEPTH_OF_DESK[row.desk]
	if row.minDepth == nil then
		row.minDepth = 0
	end
	table.insert(LIST, row)
	BY_ID[row.id] = row
	local key = row.zoneId .. "|" .. row.desk
	BY_ZONE_DESK[key] = BY_ZONE_DESK[key] or {}
	table.insert(BY_ZONE_DESK[key], row)
end

local function famSpec(key)
	for _, t in ipairs(TRIO) do
		if t.key == key then return t end
	end
	return TRIO[1]
end

for zi, zoneId in ipairs(ZONE_ORDER) do
	-- Surface shop
	local maxSurfDrillPrice = 0
	local maxSurfBombPrice = 0
	-- Each pick on a shelf has to beat the one before it. The meadow paywall
	-- cut below once left Ironvine level with Coppervine -- a purchase that
	-- changed nothing -- so a rung is now at least 12% over the last.
	local prevPickPower = 0
	-- The best pick on this shelf so far; drills and charges are valued
	-- against it (see SHELF VALUE below).
	local topPick = nil
	for slot, key in ipairs(SURFACE_PATTERN) do
		local spec = famSpec(key)
		local rung = slot
		-- Meadow only: insert a gentler first drill/bomb before the old first-tier.
		if zi == 1 then
			if key == "drill" and slot == 7 then
				rung = 3
			elseif key == "drill" and slot == 8 then
				rung = 7
			elseif key == "bomb" and slot == 9 then
				rung = 4
			elseif key == "bomb" and slot == 10 then
				rung = 9
			end
		end
		local rawPower = Eco.toolPowerRaw(zi, "shallow", rung)
		local power = Eco.toolPower(zi, "shallow", rung, spec.family)
		if zi == 1 and key == "drill" and slot == 7 then
			-- Mid-meadow paywall: soft combat, not a 500-coin oneshot drill.
			power = math.max(1, math.floor(power * 0.40 + 0.5))
			rawPower = math.max(1, math.floor(rawPower * 0.40 + 0.5))
		elseif zi == 1 and key == "bomb" and slot == 9 then
			-- Was pretune ~8 at ~1k coins; soft + expensive now.
			power = math.max(1, math.floor(power * 0.35 + 0.5))
			rawPower = math.max(1, math.floor(rawPower * 0.35 + 0.5))
		elseif zi == 1 and key == "drill" and slot == 8 then
			-- Stay above Twig Auger; keep under depth-300 cruise.
			power = math.max(1, math.floor(power * 0.62 + 0.5))
			rawPower = math.max(1, math.floor(rawPower * 0.62 + 0.5))
		elseif zi == 1 and key == "bomb" and slot == 10 then
			-- Clayfuse: keep it clearly under Spark Charge, not a shelf monster.
			power = math.max(1, math.floor(power * 0.40 + 0.5))
			rawPower = math.max(1, math.floor(rawPower * 0.40 + 0.5))
		elseif zi == 1 and key == "pick" and slot >= 5 then
			power = math.max(1, math.floor(power * 0.82 + 0.5))
			rawPower = math.max(1, math.floor(rawPower * 0.82 + 0.5))
		end
		if zi == 1 and key == "pick" then
			--[[
				MEADOW PICKS, SET BY BREAKPOINT (2026-09-19). A new player wears the
				Sod Charm (+110% Mine Speed) from their first block, and Meadow dirt
				is 10 / 22 / 45 HP down the first three layers. So, with the charm:
				Sodpick 8.4 dmg (two hits), Bronzewedge 12.6 (one-shots surface
				dirt -- the moment the user asked to land on the SECOND pick),
				Irongrasp 23 (one-shots 51-100m; one-shots the surface even naked),
				Ironvine 46 (one-shots 101-150m), Hillforge 59. All under
				Greyvein's first pick (34 x 2.1). Prices are unchanged.
			]]
			power = ({ 4, 6, 11, 16, 22, 28 })[slot] or power
		end
		if key == "pick" then
			power = math.max(power, math.ceil(prevPickPower * 1.12))
			prevPickPower = power
		end
		local row = {
			id = zoneId .. "_surface_" .. slot .. "_" .. key,
			name = "UNNAMED",
			needsName = true,
			family = spec.family,
			zoneId = zoneId,
			zoneIndex = zi,
			desk = "surface",
			band = "shallow",
			slot = slot,
			power = power,
			rate = spec.rate,
			price = Eco.toolPrice(zi, "surface", rawPower, "shallow", math.max(1, rung - 2)),
			source = "shop",
			blurb = (ZONE_LABEL[zoneId] or zoneId) .. " surface shop",
			cells = spec.cells or 1,
			shape = spec.shape or (spec.family == "pickaxe" and "melee" or spec.shape),
			width = spec.width,
			axis = spec.axis,
			turn = spec.turn,
			bombs = spec.bombs,
			pattern = spec.pattern,
			radius = spec.radius,
			cooldown = spec.cooldown,
		}
		if zi == 1 and key == "drill" and slot == 7 then
			row.rate = 2.6
			row.turn = 1.35
			row.price = 75000
			row.blurb = "First meadow drill — soft, mid-tier price"
		elseif zi == 1 and key == "drill" and slot == 8 then
			row.price = 95000
		elseif zi == 1 and key == "bomb" and slot == 9 then
			row.cooldown = 2.05
			row.radius = 1
			row.price = 110000
			row.blurb = "First meadow charge — soft, mid-tier price"
		elseif zi == 1 and key == "bomb" and slot == 10 then
			row.price = 145000
			row.cooldown = 4.0
		end
		if spec.family == "explosive" then
			Tools.tuneExplosive(row, power)
		end
		--[[
			SHELF VALUE — drills ≤2× top-pick budget; Spark ≤2×; Clayfuse ≤1.5×.
			Uses MineTools.budget meters: pick power×rate, bomb power×cells/cd.
			(Do NOT use patternWeight here — that under-counts cells and overshoots.)
		]]
		if key == "pick" then
			topPick = row
		elseif topPick and key == "drill" then
			local m = (slot == 7) and 1.5 or 2.0
			row.power = math.max(row.power, math.ceil(m * topPick.power * (topPick.rate or 2.9) / (row.rate or 3.6)))
		elseif topPick and key == "bomb" then
			-- Spark ≤2× pick budget; Clayfuse ≤1.5× (weaker than Spark, not stronger).
			local m = (slot == 9) and 2.0 or 1.5
			local cells = math.max(1, Tools.cellsOf(row))
			row.power = math.max(row.power, math.ceil(m * topPick.power * (topPick.rate or 2.9) * (row.cooldown or 2.8) / cells))
			-- 3x / 5x the top pick's price: dearer for a reason, not a wall.
			row.price = math.floor(topPick.price * ((slot == 9) and 3 or 5) / 100 + 0.5) * 100
		end
		if zi == 1 then
			-- Post–Sep 18 mid-tier stickers (before soft 11k cut / before 5× bump).
			if key == "drill" then
				row.price = (slot == 7) and 75000 or 95000
			elseif key == "bomb" then
				row.price = (slot == 9) and 110000 or 145000
			end
		end
		if key == "drill" then
			maxSurfDrillPrice = math.max(maxSurfDrillPrice, row.price)
		elseif key == "bomb" then
			maxSurfBombPrice = math.max(maxSurfBombPrice, row.price)
		end
		push(row)
	end

	-- Depth desks a/b/c: always 1 pick + 1 drill + 1 bomb
	-- Track prior-desk floors so later desks never undercut earlier drill/bomb rungs.
	local priorDrillFloor = maxSurfDrillPrice
	local priorBombFloor = maxSurfBombPrice
	for _, deskInfo in ipairs({
		{ desk = "surface_band", band = "shallow", label = "a" },
		{ desk = "deeprock", band = "mid", label = "b" },
		{ desk = "shadowzone", band = "deep", label = "c" },
	}) do
		local deskPick = nil
		for slot, spec in ipairs(TRIO) do
			local rawPower = Eco.toolPowerRaw(zi, deskInfo.band, slot + 2)
			local power = Eco.toolPower(zi, deskInfo.band, slot + 2, spec.family)
			local row = {
				id = zoneId .. "_" .. deskInfo.desk .. "_" .. spec.key,
				name = "UNNAMED",
				needsName = true,
				family = spec.family,
				zoneId = zoneId,
				zoneIndex = zi,
				desk = deskInfo.desk,
				band = deskInfo.band,
				slot = slot,
				power = power,
				rate = spec.rate,
				price = Eco.toolPrice(zi, deskInfo.desk, rawPower, deskInfo.band, slot),
				source = "shop",
				blurb = (ZONE_LABEL[zoneId] or zoneId) .. " " .. deskInfo.desk,
				cells = spec.cells or 1,
				shape = spec.shape or (spec.family == "pickaxe" and "melee" or spec.shape),
				width = spec.width,
				axis = spec.axis,
				turn = spec.turn,
				bombs = spec.bombs,
				pattern = spec.pattern,
				radius = spec.radius,
				cooldown = spec.cooldown,
			}
			if deskInfo.band == "deep" and spec.key == "drill" then
				row.shape = "dir"; row.axis = "aim"; row.turn = 0; row.special = "zeroturn"; row.rate = 4.1
			end
			if deskInfo.band == "mid" and spec.key == "bomb" then
				row.radius = 1; row.cooldown = 2.6
			end
			if deskInfo.band == "deep" and spec.key == "bomb" then
				row.pattern = "cluster"; row.bombs = 3; row.radius = 1; row.cooldown = 3.0
			end
			-- Paywall spirit (all zones): A/B/C drill/bomb never undercut earlier rungs.
			-- Meadow keeps its explicit mid-tier floors on surface_band.
			if spec.key == "drill" then
				local floor = priorDrillFloor
				if zi == 1 and deskInfo.desk == "surface_band" then
					floor = math.max(floor, 160000)
				end
				row.price = math.max(row.price, floor)
				priorDrillFloor = math.max(priorDrillFloor, row.price)
			elseif spec.key == "bomb" then
				local floor = priorBombFloor
				if zi == 1 and deskInfo.desk == "surface_band" then
					floor = math.max(floor, 190000)
				end
				row.price = math.max(row.price, floor)
				priorBombFloor = math.max(priorBombFloor, row.price)
			end
			if spec.family == "explosive" then
				Tools.tuneExplosive(row, power)
			end
			-- Shelf value for the desks too: against the desk's own pick, or
			-- the surface shelf's best when that is stronger (desk A).
			if spec.key == "pick" then
				-- Desk A sells in the surface shelf's own band, so its pick has
				-- to beat that shelf's best, or it is a dearer copy of it.
				if deskInfo.desk == "surface_band" and topPick then
					row.power = math.max(row.power, math.ceil(topPick.power * 1.3))
					row.price = math.max(row.price, math.floor(topPick.price * 2 / 100 + 0.5) * 100)
				end
				deskPick = row
			else
				local ref = deskPick
				if topPick and (not ref or topPick.power > ref.power) then
					ref = topPick
				end
				if ref and spec.key == "drill" then
					row.power = math.max(row.power, math.ceil(2.0 * ref.power * (ref.rate or 2.9) / (row.rate or 3.6)))
				elseif ref and spec.key == "bomb" then
					local cells = math.max(1, Tools.cellsOf(row))
					row.power = math.max(row.power, math.ceil(4.0 * ref.power * (ref.rate or 2.9) * (row.cooldown or 2.8) / cells))
				end
			end
			push(row)
		end
	end
end

local EXTRA_DESKS = {
	{ desk = "thousand", band = "kilo", word = "Kiln" },
	{ desk = "twothou", band = "abyss", word = "Abyss" },
}
for zi, zoneId in ipairs(ZONE_ORDER) do
	for _, ex in ipairs(EXTRA_DESKS) do
		for slot, spec in ipairs(TRIO) do
			local rawPower = Eco.toolPowerRaw(zi, ex.band, 1)
			local power = Eco.toolPower(zi, ex.band, 1, spec.family)
			local nice = (ZONE_LABEL[zoneId] or zoneId)
			local tail = (spec.key == "pick" and "Pick") or (spec.key == "drill" and "Drill") or "Charge"
			local depthWord = (ex.desk == "thousand") and "1000" or "2000"
			push({
				id = zoneId .. "_" .. ex.desk .. "_" .. spec.key,
				name = ex.word .. " " .. nice .. " " .. tail,
				family = spec.family,
				zoneId = zoneId,
				zoneIndex = zi,
				desk = ex.desk,
				band = ex.band,
				slot = slot,
				power = power,
				rate = spec.rate,
				price = Eco.toolPrice(zi, ex.desk, rawPower, ex.band, 1),
				source = "shop",
				blurb = nice .. " " .. depthWord .. " depth shop",
				cells = spec.cells or 1,
				shape = spec.shape or (spec.family == "pickaxe" and "melee" or spec.shape),
				width = spec.width,
				axis = spec.axis,
				turn = spec.turn,
				bombs = spec.bombs,
				pattern = spec.pattern,
				radius = spec.radius,
				cooldown = spec.cooldown,
			})
		end
	end
end

for _, row in ipairs(LIST) do
	local n = NAMES[row.id]
	if n then
		row.name = n
		row.needsName = nil
	end
end

MineShopLadders.LIST = LIST
MineShopLadders.ZONE_ORDER = ZONE_ORDER

function MineShopLadders.normalizeDesk(desk)
	desk = tostring(desk or "surface")
	if desk == "shallow" or desk == "a" then return "surface_band" end
	if desk == "mid" or desk == "b" then return "deeprock" end
	if desk == "deep" or desk == "c" then return "shadowzone" end
	return desk
end

function MineShopLadders.forDesk(zoneId, desk)
	zoneId = tostring(zoneId or "meadow")
	desk = MineShopLadders.normalizeDesk(desk)
	return BY_ZONE_DESK[zoneId .. "|" .. desk] or {}
end

function MineShopLadders.forZone(zoneId)
	zoneId = tostring(zoneId or "meadow")
	local out = {}
	for _, row in ipairs(LIST) do
		if row.zoneId == zoneId then
			table.insert(out, row)
		end
	end
	return out
end

function MineShopLadders.byId(id)
	return BY_ID[tostring(id or "")]
end

function MineShopLadders.counts()
	local per = {}
	for _, z in ipairs(ZONE_ORDER) do
		per[z] = #MineShopLadders.forZone(z)
	end
	return { total = #LIST, perZone = per }
end

-- Surface blacksmith catalog only (not depth desks). Ordered zone → slot.
function MineShopLadders.surfaceCatalog()
	local out = {}
	for _, row in ipairs(LIST) do
		if row.desk == "surface" then
			table.insert(out, row)
		end
	end
	return out
end

function MineShopLadders.firstSurfaceIndexForZone(zoneIndex)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	local list = MineShopLadders.surfaceCatalog()
	for i, row in ipairs(list) do
		if (row.zoneIndex or 1) == zoneIndex then
			return i
		end
	end
	return 1
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
			require(src).apply(MineShopLadders)
		end)
	end
end
return MineShopLadders
