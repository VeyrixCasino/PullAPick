--[[
	MinePackFX -- the ceremony a pack gets before it gives up its cards.

	Ported from TCG Life's SealedOpenFX.playPackOpen: the sealed pack rises into
	frame, a foil sweep runs across it, it squeezes, tears in half, and the two
	halves fly apart through a burst of sparks. About 1.4 seconds, and the caller
	reveals the cards after it returns.

	The art is this game's, not that one's: three tiers, each with its own colours
	and crest, and the set name printed on the wrapper.

	Self-contained on purpose -- the original leaned on UITheme/UIShell, and
	dragging those across would have brought half of another game's UI with them.
]]
local MinePackFX = {}

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local shared = game:GetService("ReplicatedStorage").Mine.Shared
local T = require(shared:WaitForChild("MineTheme"))
local Audio = require(shared:WaitForChild("MineAudio"))
local FONT = T.FONT
local FONT_M = T.FONT_M

-- Pack art, one entry per pack in Mine1PacksData. Ten strata packs that follow
-- the rock you dug them out of, three shape packs, and the Mirror.
--
-- Common/Gilded/Astral used to live here: that was the old three-tier system and
-- nothing drops it any more.
-- Pack face images: assets/pack/*_pack.png → pack-asset-ids.json (already uploaded).
-- Inventory/shop/open used only procedural colours before; image was never read.
MinePackFX.ART = {
	loam_pack    = { primary = Color3.fromRGB(74, 54, 34),  accent = Color3.fromRGB(186, 148, 96),  secondary = Color3.fromRGB(126, 96, 58),  image = "rbxassetid://135771038940547" },
	ashen_pack   = { primary = Color3.fromRGB(56, 58, 62),  accent = Color3.fromRGB(178, 182, 190), secondary = Color3.fromRGB(112, 116, 124), image = "rbxassetid://117982827237190" },
	clay_pack    = { primary = Color3.fromRGB(96, 46, 32),  accent = Color3.fromRGB(214, 122, 82),  secondary = Color3.fromRGB(158, 82, 54),  image = "rbxassetid://88856566440695" },
	slate_pack   = { primary = Color3.fromRGB(44, 54, 70),  accent = Color3.fromRGB(140, 166, 198), secondary = Color3.fromRGB(88, 108, 138), image = "rbxassetid://90464920617996" },
	cinder_pack  = { primary = Color3.fromRGB(88, 34, 16),  accent = Color3.fromRGB(255, 146, 62),  secondary = Color3.fromRGB(176, 78, 30),  image = "rbxassetid://85799358114935" },
	crimson_pack = { primary = Color3.fromRGB(88, 16, 30),  accent = Color3.fromRGB(240, 78, 104),  secondary = Color3.fromRGB(164, 40, 62),  image = "rbxassetid://89419742644062" },
	iron_pack    = { primary = Color3.fromRGB(62, 52, 44),  accent = Color3.fromRGB(198, 158, 116), secondary = Color3.fromRGB(126, 102, 76),  image = "rbxassetid://131680438153005" },
	night_pack   = { primary = Color3.fromRGB(30, 36, 68),  accent = Color3.fromRGB(120, 140, 230), secondary = Color3.fromRGB(66, 80, 148),  image = "rbxassetid://117990991046418" },
	void_pack    = { primary = Color3.fromRGB(38, 20, 60),  accent = Color3.fromRGB(178, 120, 250), secondary = Color3.fromRGB(104, 66, 168), image = "rbxassetid://102967692349659" },
	end_pack     = { primary = Color3.fromRGB(70, 62, 34),  accent = Color3.fromRGB(246, 232, 168), secondary = Color3.fromRGB(168, 152, 92),  image = "rbxassetid://110089431618831" },
	hopper_pack  = { primary = Color3.fromRGB(28, 66, 44),  accent = Color3.fromRGB(112, 216, 140), secondary = Color3.fromRGB(58, 140, 90),  image = "rbxassetid://72810712914851" },
	-- chrome_pack.png / magpie share magma art (pack-asset-ids aliases).
	magpie_pack  = { primary = Color3.fromRGB(24, 24, 28),  accent = Color3.fromRGB(232, 236, 244), secondary = Color3.fromRGB(120, 124, 134), image = "rbxassetid://99231272336656" },
	apex_pack    = { primary = Color3.fromRGB(96, 62, 18),  accent = Color3.fromRGB(255, 214, 90),  secondary = Color3.fromRGB(198, 142, 44),  image = "rbxassetid://124942960248864" },
	shiny_pack   = { primary = Color3.fromRGB(20, 62, 74),  accent = Color3.fromRGB(126, 244, 246), secondary = Color3.fromRGB(64, 158, 186),  image = "rbxassetid://119999326591264" }, -- mirror_pack.png

	magma_pack    = { primary = Color3.fromRGB(72, 14, 10),  accent = Color3.fromRGB(255, 108, 42),  secondary = Color3.fromRGB(158, 44, 22),  image = "rbxassetid://99231272336656" },
	cobalt_pack   = { primary = Color3.fromRGB(16, 42, 86),  accent = Color3.fromRGB(92, 166, 255),  secondary = Color3.fromRGB(44, 96, 178),  image = "rbxassetid://132968550858581" },
	omen_pack     = { primary = Color3.fromRGB(28, 20, 40),  accent = Color3.fromRGB(150, 232, 128), secondary = Color3.fromRGB(78, 62, 104),  image = "rbxassetid://102295376814707" },
	anomaly_pack  = { primary = Color3.fromRGB(34, 10, 44),  accent = Color3.fromRGB(255, 96, 214),  secondary = Color3.fromRGB(96, 208, 230), image = "rbxassetid://86407061845802" },
	heirloom_pack = { primary = Color3.fromRGB(44, 40, 22),  accent = Color3.fromRGB(226, 198, 116), secondary = Color3.fromRGB(122, 112, 62),  image = "rbxassetid://106597079706450" },

	--[[
		The three loot families, each a ladder so the cheap one and the dear one
		read apart on the shelf as well as in the price: amber for fossil, violet
		for rune, steel for gear. A player should be able to tell what family a
		wrapper belongs to before reading its name.
	]]
	fossil_pack       = { primary = Color3.fromRGB(74, 50, 22),  accent = Color3.fromRGB(214, 160, 74),  secondary = Color3.fromRGB(140, 100, 44), image = "rbxassetid://89465075108341" },
	fossil_deep_pack  = { primary = Color3.fromRGB(52, 34, 16),  accent = Color3.fromRGB(238, 186, 96),  secondary = Color3.fromRGB(122, 82, 36), image = "rbxassetid://89291064456627" },
	fossil_abyss_pack = { primary = Color3.fromRGB(26, 18, 12),  accent = Color3.fromRGB(248, 232, 196), secondary = Color3.fromRGB(126, 96, 54), image = "rbxassetid://88586083380814" },

	rune_pack         = { primary = Color3.fromRGB(46, 28, 72),  accent = Color3.fromRGB(178, 132, 240), secondary = Color3.fromRGB(98, 66, 152), image = "rbxassetid://113565242847795" },
	rune_heavy_pack   = { primary = Color3.fromRGB(34, 18, 62),  accent = Color3.fromRGB(200, 146, 255), secondary = Color3.fromRGB(112, 70, 180), image = "rbxassetid://119839016362746" },
	rune_sealed_pack  = { primary = Color3.fromRGB(22, 10, 46),  accent = Color3.fromRGB(226, 176, 255), secondary = Color3.fromRGB(130, 82, 208), image = "rbxassetid://91167732083445" },

	gear_pack         = { primary = Color3.fromRGB(30, 46, 66),  accent = Color3.fromRGB(122, 172, 224), secondary = Color3.fromRGB(66, 106, 152), image = "rbxassetid://131050081581531" },
	gear_case_pack    = { primary = Color3.fromRGB(22, 38, 60),  accent = Color3.fromRGB(146, 196, 246), secondary = Color3.fromRGB(76, 122, 176), image = "rbxassetid://132056496410791" },
	gear_vault_pack   = { primary = Color3.fromRGB(14, 28, 48),  accent = Color3.fromRGB(182, 222, 255), secondary = Color3.fromRGB(92, 146, 206), image = "rbxassetid://107524244339377" },
	-- Mine For Cards zone pouches (transparent cutouts, 2026-09-14).
	meadow_currency_common = { primary = Color3.fromRGB(74, 110, 48), accent = Color3.fromRGB(214, 186, 96), secondary = Color3.fromRGB(126, 148, 70), image = "rbxassetid://100495072429034" },
	meadow_currency_rare = { primary = Color3.fromRGB(74, 110, 48), accent = Color3.fromRGB(214, 186, 96), secondary = Color3.fromRGB(126, 148, 70), image = "rbxassetid://124884829756272" },
	meadow_pack_common = { primary = Color3.fromRGB(74, 110, 48), accent = Color3.fromRGB(214, 186, 96), secondary = Color3.fromRGB(126, 148, 70), image = "rbxassetid://76432131015339" },
	meadow_pack_rare = { primary = Color3.fromRGB(74, 110, 48), accent = Color3.fromRGB(214, 186, 96), secondary = Color3.fromRGB(126, 148, 70), image = "rbxassetid://121344446599449" },
	meadow_pack_legendary = { primary = Color3.fromRGB(74, 110, 48), accent = Color3.fromRGB(214, 186, 96), secondary = Color3.fromRGB(126, 148, 70), image = "rbxassetid://79675037204640" },
	sunscar_currency_common = { primary = Color3.fromRGB(62, 70, 82), accent = Color3.fromRGB(186, 198, 214), secondary = Color3.fromRGB(108, 120, 136), image = "rbxassetid://121559686202309" },
	sunscar_currency_rare = { primary = Color3.fromRGB(62, 70, 82), accent = Color3.fromRGB(186, 198, 214), secondary = Color3.fromRGB(108, 120, 136), image = "rbxassetid://70650703738917" },
	sunscar_pack_common = { primary = Color3.fromRGB(62, 70, 82), accent = Color3.fromRGB(186, 198, 214), secondary = Color3.fromRGB(108, 120, 136), image = "rbxassetid://83086571982004" },
	sunscar_pack_rare = { primary = Color3.fromRGB(62, 70, 82), accent = Color3.fromRGB(186, 198, 214), secondary = Color3.fromRGB(108, 120, 136), image = "rbxassetid://120352942931284" },
	sunscar_pack_legendary = { primary = Color3.fromRGB(62, 70, 82), accent = Color3.fromRGB(186, 198, 214), secondary = Color3.fromRGB(108, 120, 136), image = "rbxassetid://134954923855828" },
	mistreef_currency_common = { primary = Color3.fromRGB(22, 78, 88), accent = Color3.fromRGB(72, 196, 186), secondary = Color3.fromRGB(44, 128, 124), image = "rbxassetid://133825505687204" },
	mistreef_currency_rare = { primary = Color3.fromRGB(22, 78, 88), accent = Color3.fromRGB(72, 196, 186), secondary = Color3.fromRGB(44, 128, 124), image = "rbxassetid://98745953721707" },
	mistreef_pack_common = { primary = Color3.fromRGB(22, 78, 88), accent = Color3.fromRGB(72, 196, 186), secondary = Color3.fromRGB(44, 128, 124), image = "rbxassetid://121936495664171" },
	mistreef_pack_rare = { primary = Color3.fromRGB(22, 78, 88), accent = Color3.fromRGB(72, 196, 186), secondary = Color3.fromRGB(44, 128, 124), image = "rbxassetid://130343353191229" },
	mistreef_pack_legendary = { primary = Color3.fromRGB(22, 78, 88), accent = Color3.fromRGB(72, 196, 186), secondary = Color3.fromRGB(44, 128, 124), image = "rbxassetid://72354671694170" },
	arcwork_currency_common = { primary = Color3.fromRGB(48, 52, 70), accent = Color3.fromRGB(255, 186, 64), secondary = Color3.fromRGB(88, 120, 180), image = "rbxassetid://73140729807894" },
	arcwork_currency_rare = { primary = Color3.fromRGB(48, 52, 70), accent = Color3.fromRGB(255, 186, 64), secondary = Color3.fromRGB(88, 120, 180), image = "rbxassetid://70719859597287" },
	arcwork_pack_common = { primary = Color3.fromRGB(48, 52, 70), accent = Color3.fromRGB(255, 186, 64), secondary = Color3.fromRGB(88, 120, 180), image = "rbxassetid://125129025110772" },
	arcwork_pack_rare = { primary = Color3.fromRGB(48, 52, 70), accent = Color3.fromRGB(255, 186, 64), secondary = Color3.fromRGB(88, 120, 180), image = "rbxassetid://120598109305838" },
	arcwork_pack_legendary = { primary = Color3.fromRGB(48, 52, 70), accent = Color3.fromRGB(255, 186, 64), secondary = Color3.fromRGB(88, 120, 180), image = "rbxassetid://91937652635880" },
	bloodmoon_currency_common = { primary = Color3.fromRGB(88, 16, 22), accent = Color3.fromRGB(240, 64, 72), secondary = Color3.fromRGB(140, 32, 40), image = "rbxassetid://134664364010649" },
	bloodmoon_currency_rare = { primary = Color3.fromRGB(88, 16, 22), accent = Color3.fromRGB(240, 64, 72), secondary = Color3.fromRGB(140, 32, 40), image = "rbxassetid://91899903359166" },
	bloodmoon_pack_common = { primary = Color3.fromRGB(88, 16, 22), accent = Color3.fromRGB(240, 64, 72), secondary = Color3.fromRGB(140, 32, 40), image = "rbxassetid://82460859804051" },
	bloodmoon_pack_rare = { primary = Color3.fromRGB(88, 16, 22), accent = Color3.fromRGB(240, 64, 72), secondary = Color3.fromRGB(140, 32, 40), image = "rbxassetid://126874266552352" },
	bloodmoon_pack_legendary = { primary = Color3.fromRGB(88, 16, 22), accent = Color3.fromRGB(240, 64, 72), secondary = Color3.fromRGB(140, 32, 40), image = "rbxassetid://104995536033072" },
	eclipse_currency_common = { primary = Color3.fromRGB(20, 16, 28), accent = Color3.fromRGB(220, 196, 120), secondary = Color3.fromRGB(70, 50, 80), image = "rbxassetid://90183692406065" },
	eclipse_currency_rare = { primary = Color3.fromRGB(20, 16, 28), accent = Color3.fromRGB(220, 196, 120), secondary = Color3.fromRGB(70, 50, 80), image = "rbxassetid://85671647505577" },
	eclipse_pack_common = { primary = Color3.fromRGB(20, 16, 28), accent = Color3.fromRGB(220, 196, 120), secondary = Color3.fromRGB(70, 50, 80), image = "rbxassetid://128014838018276" },
	eclipse_pack_rare = { primary = Color3.fromRGB(20, 16, 28), accent = Color3.fromRGB(220, 196, 120), secondary = Color3.fromRGB(70, 50, 80), image = "rbxassetid://124662055907054" },
	eclipse_pack_legendary = { primary = Color3.fromRGB(20, 16, 28), accent = Color3.fromRGB(220, 196, 120), secondary = Color3.fromRGB(70, 50, 80), image = "rbxassetid://78178817737664" },
	riftmarch_currency_common = { primary = Color3.fromRGB(52, 28, 90), accent = Color3.fromRGB(168, 96, 255), secondary = Color3.fromRGB(90, 50, 140), image = "rbxassetid://115563277536496" },
	riftmarch_currency_rare = { primary = Color3.fromRGB(52, 28, 90), accent = Color3.fromRGB(168, 96, 255), secondary = Color3.fromRGB(90, 50, 140), image = "rbxassetid://76562804779290" },
	riftmarch_pack_common = { primary = Color3.fromRGB(52, 28, 90), accent = Color3.fromRGB(168, 96, 255), secondary = Color3.fromRGB(90, 50, 140), image = "rbxassetid://122815546739294" },
	riftmarch_pack_rare = { primary = Color3.fromRGB(52, 28, 90), accent = Color3.fromRGB(168, 96, 255), secondary = Color3.fromRGB(90, 50, 140), image = "rbxassetid://92276156258959" },
	riftmarch_pack_legendary = { primary = Color3.fromRGB(52, 28, 90), accent = Color3.fromRGB(168, 96, 255), secondary = Color3.fromRGB(90, 50, 140), image = "rbxassetid://120504306913387" },
	starfall_currency_common = { primary = Color3.fromRGB(18, 28, 72), accent = Color3.fromRGB(255, 214, 120), secondary = Color3.fromRGB(60, 80, 160), image = "rbxassetid://93495373155848" },
	starfall_currency_rare = { primary = Color3.fromRGB(18, 28, 72), accent = Color3.fromRGB(255, 214, 120), secondary = Color3.fromRGB(60, 80, 160), image = "rbxassetid://99927915825754" },
	starfall_pack_common = { primary = Color3.fromRGB(18, 28, 72), accent = Color3.fromRGB(255, 214, 120), secondary = Color3.fromRGB(60, 80, 160), image = "rbxassetid://136962111749991" },
	starfall_pack_rare = { primary = Color3.fromRGB(18, 28, 72), accent = Color3.fromRGB(255, 214, 120), secondary = Color3.fromRGB(60, 80, 160), image = "rbxassetid://109801513884308" },
	starfall_pack_legendary = { primary = Color3.fromRGB(18, 28, 72), accent = Color3.fromRGB(255, 214, 120), secondary = Color3.fromRGB(60, 80, 160), image = "rbxassetid://104615465734835" },
	mythral_currency_common = { primary = Color3.fromRGB(40, 70, 90), accent = Color3.fromRGB(160, 230, 255), secondary = Color3.fromRGB(80, 140, 170), image = "rbxassetid://104713438655319" },
	mythral_currency_rare = { primary = Color3.fromRGB(40, 70, 90), accent = Color3.fromRGB(160, 230, 255), secondary = Color3.fromRGB(80, 140, 170), image = "rbxassetid://79267152703294" },
	mythral_pack_common = { primary = Color3.fromRGB(40, 70, 90), accent = Color3.fromRGB(160, 230, 255), secondary = Color3.fromRGB(80, 140, 170), image = "rbxassetid://136669791478167" },
	mythral_pack_rare = { primary = Color3.fromRGB(40, 70, 90), accent = Color3.fromRGB(160, 230, 255), secondary = Color3.fromRGB(80, 140, 170), image = "rbxassetid://117986515175869" },
	mythral_pack_legendary = { primary = Color3.fromRGB(40, 70, 90), accent = Color3.fromRGB(160, 230, 255), secondary = Color3.fromRGB(80, 140, 170), image = "rbxassetid://84837674830914" },
	primordium_currency_common = { primary = Color3.fromRGB(90, 50, 28), accent = Color3.fromRGB(255, 170, 80), secondary = Color3.fromRGB(140, 80, 44), image = "rbxassetid://77385241301652" },
	primordium_currency_rare = { primary = Color3.fromRGB(90, 50, 28), accent = Color3.fromRGB(255, 170, 80), secondary = Color3.fromRGB(140, 80, 44), image = "rbxassetid://85785487774525" },
	primordium_pack_common = { primary = Color3.fromRGB(90, 50, 28), accent = Color3.fromRGB(255, 170, 80), secondary = Color3.fromRGB(140, 80, 44), image = "rbxassetid://108288283628741" },
	primordium_pack_rare = { primary = Color3.fromRGB(90, 50, 28), accent = Color3.fromRGB(255, 170, 80), secondary = Color3.fromRGB(140, 80, 44), image = "rbxassetid://95567758727193" },
	primordium_pack_legendary = { primary = Color3.fromRGB(90, 50, 28), accent = Color3.fromRGB(255, 170, 80), secondary = Color3.fromRGB(140, 80, 44), image = "rbxassetid://88274061341407" },
	bigbang_currency_common = { primary = Color3.fromRGB(28, 12, 48), accent = Color3.fromRGB(255, 120, 200), secondary = Color3.fromRGB(80, 40, 120), image = "rbxassetid://118826225501983" },
	bigbang_currency_rare = { primary = Color3.fromRGB(28, 12, 48), accent = Color3.fromRGB(255, 120, 200), secondary = Color3.fromRGB(80, 40, 120), image = "rbxassetid://118683412447260" },
	bigbang_pack_common = { primary = Color3.fromRGB(28, 12, 48), accent = Color3.fromRGB(255, 120, 200), secondary = Color3.fromRGB(80, 40, 120), image = "rbxassetid://96495657567278" },
	bigbang_pack_rare = { primary = Color3.fromRGB(28, 12, 48), accent = Color3.fromRGB(255, 120, 200), secondary = Color3.fromRGB(80, 40, 120), image = "rbxassetid://137459477403448" },
	bigbang_pack_legendary = { primary = Color3.fromRGB(28, 12, 48), accent = Color3.fromRGB(255, 120, 200), secondary = Color3.fromRGB(80, 40, 120), image = "rbxassetid://128589188130734" },
	lucky_block = { primary = Color3.fromRGB(255, 196, 64), accent = Color3.fromRGB(255, 220, 120), secondary = Color3.fromRGB(196, 122, 32), image = "rbxassetid://86826521518359" },
	super_lucky_block = { primary = Color3.fromRGB(64, 148, 255), accent = Color3.fromRGB(140, 190, 255), secondary = Color3.fromRGB(30, 90, 168), image = "rbxassetid://130589291505484" },
	godly_lucky_block = { primary = Color3.fromRGB(220, 48, 64), accent = Color3.fromRGB(255, 160, 80), secondary = Color3.fromRGB(122, 16, 32), image = "rbxassetid://75196830544563" },
}

-- Anything unrecognised gets the loam wrapper rather than no wrapper.
MinePackFX.DEFAULT = MinePackFX.ART.loam_pack

-- Ore packs have no dedicated face art — leave image empty so drawSealed /
-- playPackOpen use the same procedural colour wrapper (band + crest) as any
-- other pack without a wired face PNG.

local function clamp01(x)
	return math.clamp(x, 0, 1)
end

--[[
	Build a pack palette from an ore tip color.
	Same hue family, not a 1:1 copy: deep wrapper, mid body, lifted seal/accent.
]]
local function orePackArtFromColor(base)
	local h, s, v = Color3.toHSV(base)
	local primary = Color3.fromHSV(h, clamp01(s * 0.78 + 0.06), clamp01(v * 0.26 + 0.07))
	local secondary = Color3.fromHSV(h, clamp01(s * 0.68 + 0.08), clamp01(v * 0.42 + 0.12))
	local accent = Color3.fromHSV(
		(h + 0.02) % 1,
		clamp01(s * 0.88 + 0.06),
		clamp01(math.max(v, 0.4) * 1.14 + 0.1)
	)
	return {
		primary = primary,
		secondary = secondary,
		accent = accent,
		image = "",
	}
end

local function ensureOrePackArt()
	if MinePackFX._oreArtReady then
		return
	end
	local ok, C = pcall(function()
		return require(script.Parent:WaitForChild("MineConfig"))
	end)
	if not (ok and C and C.ORES) then
		return
	end
	for _, ore in ipairs(C.ORES) do
		local pid = ore.packId or (ore.id .. "_ore_pack")
		if ore.color then
			-- Always (re)build so a prior fossil-sack image does not stick.
			MinePackFX.ART[pid] = orePackArtFromColor(ore.color)
		end
	end
	MinePackFX._oreArtReady = true
end

function MinePackFX.art(packId)
	packId = tostring(packId or "")
	local row = MinePackFX.ART[packId]
	if row then
		return row
	end
	if string.sub(packId, -9) == "_ore_pack" then
		ensureOrePackArt()
		row = MinePackFX.ART[packId]
		if row then
			return row
		end
		-- Lazy single-ore resolve if the bulk pass missed this id.
		local oreId = string.sub(packId, 1, #packId - 9)
		local ok, C = pcall(function()
			return require(script.Parent:WaitForChild("MineConfig"))
		end)
		local ore = ok and C and C.oreById and C.oreById(oreId)
		if ore and ore.color then
			row = orePackArtFromColor(ore.color)
			MinePackFX.ART[packId] = row
			return row
		end
	end
	if string.find(packId, "_fossil_deep_pack", 1, true) then
		return MinePackFX.ART.fossil_deep_pack or MinePackFX.DEFAULT
	end
	if string.find(packId, "_fossil_pack", 1, true) then
		return MinePackFX.ART.fossil_pack or MinePackFX.DEFAULT
	end
	return MinePackFX.DEFAULT
end

-- Warm the ore palette at require-time when MineConfig is already up.
do
	ensureOrePackArt()
end

--------------------------------------------------------------------------------
local function mk(class, props, parent)
	local o = Instance.new(class)
	-- Roblox defaults every GuiObject to a 1px border, and that border is drawn
	-- OUTSIDE the UICorner radius -- so on a rounded dark panel it shows up as a
	-- pale hairline poking out at every corner. That is the "white borders", and
	-- there was no way to switch it off because nothing ever set it. Off by
	-- default now; a caller that genuinely wants one still passes it explicitly.
	if props and props.BorderSizePixel == nil and o:IsA("GuiObject") then
		o.BorderSizePixel = 0
	end
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function corner(o, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
	return o
end

local function pill(o)
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, o)
	return o
end

local function stroke(o, colour, thick, transparency)
	mk("UIStroke", {
		Color = colour,
		Thickness = thick or 1,
		Transparency = transparency or 0.3,
	}, o)
	return o
end

local function gradient(o, colours, rotation, transparency)
	local keys = {}
	local n = #colours
	for i, c in ipairs(colours) do
		table.insert(keys, ColorSequenceKeypoint.new(n == 1 and (i - 1) or ((i - 1) / (n - 1)), c))
	end
	if n == 1 then
		keys = { ColorSequenceKeypoint.new(0, colours[1]), ColorSequenceKeypoint.new(1, colours[1]) }
	end
	local g = mk("UIGradient", {
		Color = ColorSequence.new(keys),
		Rotation = rotation or 0,
	}, o)
	if transparency then
		g.Transparency = transparency
	end
	return g
end

local function waitTween(t)
	t:Play()
	t.Completed:Wait()
end

-- A four-armed spark: two crossed pills, which reads as a glint at any size.
local function sparkle(parent, colour, pos, size, z)
	local sp = mk("Frame", {
		Name = "Spark",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos,
		Size = UDim2.fromOffset(size, size),
		ZIndex = z,
	}, parent)
	for _, s in ipairs({ UDim2.fromScale(0.18, 1), UDim2.fromScale(1, 0.18) }) do
		pill(mk("Frame", {
			BackgroundColor3 = colour,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = s,
			ZIndex = z,
		}, sp))
	end
	return sp
end

--[[
	Play the open on `host`, which should be a full-screen frame the caller owns.
	`design` is { tier = 1..3, name = "Gilded Pack", setName = "Aurora Crown",
	crestImage = "rbxassetid://..." }. Yields for the length of the ceremony.
]]
--[[
	A still of the sealed pack, small enough to sit on an inventory tile.

	The reveal builds this shape at full size and then tears it open; the
	inventory used to show a blank rectangle with the name written on it, so a
	stack of packs looked like a spreadsheet. Same three colours, same band and
	crest, so the thing you click and the thing that tears open are recognisably
	one object.
]]
function MinePackFX.drawSealed(parent, packId, width, height)
	local art = MinePackFX.art(packId)
	local w = width or 44
	local h = height or 62
	local hasFace = art.image and art.image ~= ""
	local pack = mk("Frame", {
		Name = "MiniPack",
		-- Opaque primary behind Face washes out cutout silhouettes — clear when art is present.
		BackgroundColor3 = art.primary,
		BackgroundTransparency = hasFace and 1 or 0,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(w, h),
		ZIndex = 4,
	}, parent)
	corner(pack, math.max(3, math.floor(w / 12)))
	-- Real pack face art when wired; otherwise the old colour wrapper.
	if hasFace then
		mk("ImageLabel", {
			Name = "Face",
			BackgroundTransparency = 1,
			Image = art.image,
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			-- Slight inset so accent stroke does not crush the pouch silhouette.
			Size = UDim2.new(1, -4, 1, -4),
			ZIndex = 5,
		}, pack)
		stroke(pack, art.accent, 1, 0.55)
		return pack
	end
	gradient(pack, {
		art.secondary:Lerp(Color3.new(1, 1, 1), 0.25),
		art.primary,
		art.primary:Lerp(Color3.new(0, 0, 0), 0.45),
	}, 110)
	stroke(pack, art.accent, 1, 0.35)
	local band = mk("Frame", {
		Name = "Band",
		BackgroundColor3 = art.accent,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.1),
		Size = UDim2.new(1, 0, 0, math.max(4, math.floor(h / 8))),
		ZIndex = 5,
	}, pack)
	gradient(band, { art.secondary, art.accent, art.secondary }, 0)
	local crest = mk("Frame", {
		Name = "Crest",
		BackgroundColor3 = art.accent,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.54),
		Size = UDim2.fromOffset(math.floor(w * 0.46), math.floor(w * 0.46)),
		ZIndex = 5,
	}, pack)
	pill(crest)
	gradient(crest, { art.secondary, art.primary:Lerp(Color3.new(0, 0, 0), 0.35) }, 90)
	stroke(crest, art.secondary, 1, 0.25)
	return pack
end

function MinePackFX.playPackOpen(host, design)
	design = design or {}
	local art = MinePackFX.art(design.packId)
	local accent = design.accent or art.accent
	local primary = design.primary or art.primary
	local secondary = design.secondary or art.secondary

	for _, child in ipairs(host:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local glow = mk("Frame", {
		Name = "Glow",
		BackgroundColor3 = accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(360, 460),
		ZIndex = 3,
	}, host)
	corner(glow, 40)

	local packFace = design.crestImage or art.image
	local hasFace = packFace and packFace ~= ""
	local pack = mk("Frame", {
		Name = "SealedPack",
		BackgroundColor3 = primary,
		BackgroundTransparency = hasFace and 1 or 0,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.fromOffset(300, 420),
		ZIndex = 4,
	}, host)
	corner(pack, 14)
	local scale = mk("UIScale", { Scale = 0.78 }, pack)
	if hasFace then
		mk("ImageLabel", {
			Name = "Face",
			BackgroundTransparency = 1,
			Image = packFace,
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -8, 1, -8),
			ZIndex = 5,
		}, pack)
		stroke(pack, accent, 2, 0.45)
	else
		gradient(pack, {
			secondary:Lerp(Color3.new(1, 1, 1), 0.25),
			primary,
			primary:Lerp(Color3.new(0, 0, 0), 0.45),
		}, 110)
		stroke(pack, accent, 2, 0.25)

		local band = mk("Frame", {
			Name = "Band",
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.08),
			Size = UDim2.new(1, 0, 0, 42),
			ZIndex = 5,
		}, pack)
		gradient(band, { secondary, accent, secondary }, 0)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = FONT,
			TextSize = 21,
			TextColor3 = Color3.fromRGB(22, 20, 16),
			Text = design.name or "Booster Pack",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 6,
		}, band)

		local crest = mk("Frame", {
			Name = "Crest",
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.48),
			Size = UDim2.fromOffset(128, 128),
			ZIndex = 5,
		}, pack)
		pill(crest)
		gradient(crest, { secondary, primary:Lerp(Color3.new(0, 0, 0), 0.35) }, 90)
		stroke(crest, secondary, 2, 0.2)

		mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = FONT_M,
			TextSize = 16,
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 0.25,
			Text = string.upper(design.setName or "BOOSTER PACK"),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -18),
			Size = UDim2.new(1, -16, 0, 16),
			ZIndex = 5,
		}, pack)
	end

	-- The foil is a white sheen with a moving hole in its transparency; sweeping
	-- the gradient offset is what drags the highlight across the wrapper.
	local foil = mk("Frame", {
		Name = "Foil",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 6,
	}, pack)
	corner(foil, 14)
	local foilGrad = gradient(foil, { Color3.new(1, 1, 1) }, 55, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.6, 1),
		NumberSequenceKeypoint.new(1, 1),
	}))

	-- 1. Rise into frame.
	pcall(function()
		Audio.playPackCeremony()
	end)
	waitTween(TweenService:Create(pack, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5),
	}))
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(glow, TweenInfo.new(0.35), { BackgroundTransparency = 0.72 }):Play()
	task.wait(0.2)

	-- 2. Foil sweep.
	waitTween(TweenService:Create(foilGrad, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Offset = Vector2.new(1.2, 0),
	}))

	--[[
		3. TEAR IT IN HALF.

		This used to clone the pack twice and resize each copy to half width.
		That does not split a pack -- the band, the crest and the set name are
		all positioned by SCALE, so shrinking the frame re-centres them inside
		each half. What flew apart was two complete miniature packs, each with
		its own full crest, rather than one pack coming apart down the middle.

		A half has to be a WINDOW onto the whole pack, not a squashed copy of
		it. Each side is a 140-wide clipping frame holding a full 280-wide
		pack, positioned so the tear line sits on the window's edge: the left
		window puts the pack's centre at its right edge, the right window puts
		it at its left. Both show their true half of one crest, and because the
		windows start flush against each other the split is seamless.
	]]
	-- A beat of tension first: the pack tightens, then goes.
	waitTween(TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Scale = 1.05,
	}))

	local halves = {}
	for _, side in ipairs({
		-- name, anchor, how far it flies, where the pack's centre sits in the window
		{ "LeftHalf", Vector2.new(1, 0.5), -230, 140 },
		{ "RightHalf", Vector2.new(0, 0.5), 230, 0 },
	}) do
		local win = mk("CanvasGroup", {
			Name = side[1],
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AnchorPoint = side[2],
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(140, 400),
			ClipsDescendants = true,
			ZIndex = 4,
		}, host)
		local full = pack:Clone()
		local sc = full:FindFirstChildOfClass("UIScale")
		if sc then
			sc:Destroy()
		end
		full.AnchorPoint = Vector2.new(0.5, 0.5)
		full.Size = UDim2.fromOffset(280, 400)
		full.Position = UDim2.fromOffset(side[4], 200)
		full.Parent = win
		table.insert(halves, { frame = win, away = side[3] })
	end
	pack:Destroy()

	-- The tear line itself: a bright seam down the middle that fades as the
	-- halves pull away from it.
	local seam = mk("Frame", {
		Name = "Seam",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(6, 400),
		ZIndex = 8,
	}, host)
	TweenService:Create(seam, TweenInfo.new(0.34), {
		Size = UDim2.fromOffset(2, 440),
		BackgroundTransparency = 1,
	}):Play()
	Debris:AddItem(seam, 0.45)

	TweenService:Create(glow, TweenInfo.new(0.28), {
		BackgroundTransparency = 0.35,
		Size = UDim2.fromOffset(520, 580),
	}):Play()

	-- 4. Sparks out of the tear.
	local sparks = {}
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local sp = sparkle(host, (i % 2 == 0) and accent or Color3.new(1, 1, 1),
			UDim2.fromScale(0.5, 0.5), 10 + (i % 3) * 6, 7)
		table.insert(sparks, sp)
		local dist = 110 + math.random(30, 140)
		TweenService:Create(sp, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(angle) * dist, 0.5, math.sin(angle) * dist),
		}):Play()
		for _, part in ipairs(sp:GetChildren()) do
			if part:IsA("GuiObject") then
				TweenService:Create(part, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
			end
		end
	end

	-- 5. Halves away.
	for i, h in ipairs(halves) do
		-- GroupTransparency, not BackgroundTransparency: the half is a window
		-- and its own background is already invisible. The group fades the pack
		-- copy inside it, which is the part the player can see.
		local t = TweenService:Create(h.frame, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, h.away, 0.5, -20),
			GroupTransparency = 1,
			Rotation = (h.away < 0) and -14 or 14,
		})
		if i == 1 then
			t:Play()
		else
			waitTween(t)
		end
	end

	task.wait(0.12)
	for _, h in ipairs(halves) do
		if h.frame.Parent then
			h.frame:Destroy()
		end
	end
	for _, sp in ipairs(sparks) do
		if sp.Parent then
			sp:Destroy()
		end
	end
	if glow.Parent then
		TweenService:Create(glow, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		task.delay(0.25, function()
			if glow.Parent then
				glow:Destroy()
			end
		end)
	end
end


--[[
	Pack order lives in MinePackConfig.packTier now, not here.

	This file used to carry its own hand-written ORDER list. Two hand-written
	orders is one too many: they drifted apart the moment a pack was renamed,
	and nothing said which one won. MinePackConfig derives the order from the
	packs' own odds, so it cannot fall out of date, and this delegates to it.

	The require is deliberately INSIDE the function. MinePackConfig requires
	this module at load, so reaching for it at the top of this file would be a
	cycle; by the time anyone asks for a rank, both are loaded.
]]
function MinePackFX.rankOf(packId)
	local ok, Config = pcall(require, script.Parent:FindFirstChild("MinePackConfig"))
	if ok and Config and Config.packTier then
		local tier = Config.packTier(packId)
		-- 0 means "not a pack we know"; sort those last rather than first.
		return (tier > 0) and tier or math.huge
	end
	return math.huge
end
--[[
	PULL GRADE -- how disgusting was that card?

	The reveal needs one number to scale everything off, and it has to come from
	the game's own language: MineCards ranks the rarity, the variant adds on
	top, and shiny counts as at least a Shiny variant even when the variant
	field still says Normal.

	MinePackConfig also has a Void variant that VARIANT_RANK does not always
	carry; it is treated as Prism-or-better, because that is what it is worth.

	PRESENTATION ONLY. The card was rolled and banked on the server before this
	ran. This decides how loud the screen gets and nothing else -- it can never
	change what you got.
]]
local VARIANT_FALLBACK = { Normal = 1, Shiny = 2, Golden = 3, Prism = 4, Void = 4, Rainbow = 5 }

-- Loudness order of the bands, for anything that sorts pulls the way the
-- reveal celebrates them (MineServer.openPack, MinePackReveal bulk hits).
MinePackFX.BAND_ORDER = { DUD = 1, NICE = 2, HIT = 3, CHASE = 4, GOD = 5 }

function MinePackFX.pullScore(card, Cards)
	if not card then
		return 1, "DUD"
	end
	Cards = Cards or require(script.Parent:FindFirstChild("MineCards"))
	local base = (Cards and Cards.RARITY_RANK and Cards.RARITY_RANK[card.rarityId or ""]) or 1
	local variant = card.variant or "Normal"
	local var = (Cards and Cards.VARIANT_RANK and Cards.VARIANT_RANK[variant])
		or VARIANT_FALLBACK[variant] or 1
	if variant == "Void" then
		var = math.max(var, 4)
	end
	if card.shiny then
		var = math.max(var, 2)
	end
	local grade = base + (var - 1) * 0.75

	-- Read top-down: the loudest qualifying condition wins.
	local band
	local isVoid = (variant == "Void")
	if base >= 7 or var >= 5 or isVoid or (base >= 6 and card.shiny) then
		band = "GOD"        -- Divine / Exotic, Rainbow or Void, Mythic+ shiny
	elseif base >= 5 or (var >= 3 and base >= 3) then
		band = "CHASE"      -- Legendary / Mythic, or Golden+ on Rare+
	elseif base >= 3 then
		band = "HIT"        -- Rare / Epic
	elseif base >= 2 or card.shiny or var >= 2 then
		band = "NICE"       -- Uncommon, or a shiny Common
	else
		band = "DUD"        -- and the silence is the joke
	end
	-- A Common or Uncommon never gets the big screen, whatever its variant: a
	-- Golden or Rainbow Common is a nice pull, not a celebration.
	if base <= 2 and (band == "CHASE" or band == "GOD") then
		band = "HIT"
	end
	return grade, band
end

--[[
	The screen's reaction to a pull.

	FIRE AND FORGET -- this never yields. The player owns the tempo, and a hit
	that blocks the next click is a hit that got in the way.

	`host` is the overlay frame the effects live in, deliberately not the 3D
	world, so nothing here touches the game underneath. `shakeHost` is what gets
	jittered, usually the stage.
]]
local BAND_FX = {
	DUD   = { flash = 0,    sparks = 0,  shake = 0,  ring = 0 },
	NICE  = { flash = 0.88, sparks = 5,  shake = 0,  ring = 0 },
	HIT   = { flash = 0.72, sparks = 10, shake = 7,  ring = 1 },
	CHASE = { flash = 0.55, sparks = 18, shake = 11, ring = 2 },
	GOD   = { flash = 0.30, sparks = 28, shake = 18, ring = 3 },
}

function MinePackFX.playPullHit(host, band, colour, shakeHost)
	local fx = BAND_FX[band or "DUD"] or BAND_FX.DUD
	colour = colour or Color3.fromRGB(255, 220, 120)
	if not host or not host.Parent then
		return
	end
	if fx.flash <= 0 and fx.sparks <= 0 then
		return -- DUD: nothing happens. That is the point.
	end
	pcall(function()
		Audio.playPull(band)
	end)

	-- 1. Flash. GOD gets a second one on the way out, which is what makes it
	--    read as an impact rather than a fade.
	if fx.flash > 0 then
		local flash = mk("Frame", {
			Name = "PullFlash",
			BackgroundColor3 = (band == "GOD" or band == "CHASE") and colour or Color3.new(1, 1, 1),
			BackgroundTransparency = fx.flash,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 40,
		}, host)
		TweenService:Create(flash, TweenInfo.new(band == "GOD" and 0.34 or 0.18), {
			BackgroundTransparency = 1,
		}):Play()
		Debris:AddItem(flash, 0.5)
		if band == "GOD" then
			task.delay(0.1, function()
				if not host.Parent then
					return
				end
				local f2 = mk("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 0.5,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 41,
				}, host)
				TweenService:Create(f2, TweenInfo.new(0.26), { BackgroundTransparency = 1 }):Play()
				Debris:AddItem(f2, 0.4)
			end)
		end
	end

	-- 2. Chromatic ghosts: two offset translucent colour plates. The
	--    Roblox-native way to get the split-channel look without post FX.
	if band == "GOD" then
		for _, pair in ipairs({ { -9, Color3.fromRGB(255, 60, 90) }, { 9, Color3.fromRGB(60, 170, 255) } }) do
			local ghost = mk("Frame", {
				BackgroundColor3 = pair[2],
				BackgroundTransparency = 0.72,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(pair[1], 0),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 39,
			}, host)
			TweenService:Create(ghost, TweenInfo.new(0.3), {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(pair[1] * 3, 0),
			}):Play()
			Debris:AddItem(ghost, 0.45)
		end
	end

	-- 3. Sparks, thrown from the middle.
	for i = 1, fx.sparks do
		local angle = (i / fx.sparks) * math.pi * 2 + math.random() * 0.4
		local white = (i - math.floor(i / 3) * 3) == 0
		local sp = sparkle(host, white and Color3.new(1, 1, 1) or colour,
			UDim2.fromScale(0.5, 0.5), 12 + (i - math.floor(i / 4) * 4) * 7, 42)
		local dist = 130 + math.random(40, 60 + fx.sparks * 6)
		TweenService:Create(sp, TweenInfo.new(0.5 + math.random() * 0.2,
			Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(angle) * dist, 0.5, math.sin(angle) * dist),
			Rotation = math.random(-180, 180),
		}):Play()
		for _, part in ipairs(sp:GetChildren()) do
			if part:IsA("GuiObject") then
				TweenService:Create(part, TweenInfo.new(0.55), { BackgroundTransparency = 1 }):Play()
			end
		end
		Debris:AddItem(sp, 0.85)
	end

	-- 4. Expanding rings, one per grade step above HIT.
	for i = 1, fx.ring do
		local ring = mk("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(120, 120),
			ZIndex = 38,
		}, host)
		corner(ring, 999)
		local rs = stroke(ring, colour, 5, 0.1)
		TweenService:Create(ring, TweenInfo.new(0.45 + i * 0.1, Enum.EasingStyle.Quad), {
			Size = UDim2.fromOffset(620 + i * 200, 620 + i * 200),
		}):Play()
		TweenService:Create(rs, TweenInfo.new(0.45 + i * 0.1), { Transparency = 1 }):Play()
		Debris:AddItem(ring, 0.95)
	end

	-- 5. Shake. Jitters the stage, never the camera: the world behind the
	--    overlay is not part of this.
	if fx.shake > 0 and shakeHost then
		task.spawn(function()
			local home = shakeHost.Position
			local steps = (band == "GOD") and 10 or 6
			for s = 1, steps do
				if not shakeHost.Parent then
					return
				end
				local fall = math.max(1, math.floor(fx.shake * (1 - s / steps)))
				shakeHost.Position = home + UDim2.fromOffset(
					math.random(-fall, fall), math.random(-fall, fall))
				task.wait(0.022)
			end
			if shakeHost.Parent then
				shakeHost.Position = home
			end
		end)
	end
end

return MinePackFX
