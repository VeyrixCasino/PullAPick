-- MineHats: real Roblox catalog helmets for gear head slot.
-- Print rarities Common->Exotic map to gear grades F->SSS.
-- Face / Neck / Back leftovers are coded but OFF the drop table (faces/acc soon).

local MineHats = {}

-- Gear letter grade for each print rarity.
MineHats.GRADE_OF = {
	Common = "F",
	Uncommon = "D",
	Rare = "C",
	Epic = "B",
	Legendary = "A",
	Mythic = "S",
	Divine = "SS",
	Exotic = "SSS",
}

MineHats.PRINT_OF = {
	F = "Common", D = "Uncommon", C = "Rare", B = "Epic",
	A = "Legendary", S = "Mythic", SS = "Divine", SSS = "Exotic",
}

-- Each droppable hat:
--   id, name, catalogId, rarity (print), rap, setId (MineGear set -> buff verb)
-- setId picks which predetermined head buff the piece carries.
local function H(id, name, catalogId, rarity, rap, setId)
	return {
		id = id,
		name = name,
		catalogId = catalogId,
		rarity = rarity,
		grade = MineHats.GRADE_OF[rarity],
		rap = rap,
		setId = setId,
		kind = "Hat",
		drop = true,
	}
end

local function L(id, name, catalogId, rarity, rap, kind, setId)
	return {
		id = id,
		name = name,
		catalogId = catalogId,
		rarity = rarity,
		grade = MineHats.GRADE_OF[rarity],
		rap = rap,
		setId = setId or "umbra",
		kind = kind,
		drop = false,
	}
end

-- Droppable helmets only (Hat). Buffs assigned by theme -> set verb.
MineHats.LIST = {
	-- Tier 1 Common (F)
	H("spider_antlers", "Spider Antlers", 2470988022, "Common", 292, "umbra"),
	H("snow_leopard_fedora", "Snow Leopard Fedora", 128159229, "Common", 295, "umbra"),
	H("zipper_cap", "Zipper Cap", 51245998, "Common", 312, "foundry"),
	H("party_fedora", "Party Fedora", 3798243238, "Common", 270, "glacier"),
	H("brass_top_hat", "Brass Top Hat", 35685137, "Common", 883, "glacier"),
	H("antenna_antlers", "Antenna Antlers", 148791559, "Common", 1034, "canopy"),
	H("dark_horns", "Dark Horns", 71499623, "Common", 1206, "glacier"),
	H("sk9r_boi", "Sk9r Boi", 16412796, "Common", 1290, "glacier"),
	H("purple_banded_top_hat", "Purple Banded Top Hat", 1028715, "Common", 1345, "umbra"),
	H("scare_mayor_top_hat", "Scare Mayor Top Hat", 131592484, "Common", 1437, "umbra"),
	H("bloxy_cola_hat", "Bloxy Cola Hat", 24114402, "Common", 1622, "tide"),
	H("santa_hat", "Santa Hat", 1098277, "Common", 1628, "glacier"),
	H("universal_fedora", "Universal Fedora", 259424300, "Common", 3124, "foundry"),
	H("black_iron_horns", "Black Iron Horns", 628771505, "Common", 1666, "bedrock"),
	H("sinister_branches", "Sinister Branches", 71484026, "Common", 2089, "umbra"),
	H("omega_rainbow_fedora", "Omega Rainbow Fedora", 302281542, "Common", 2278, "umbra"),
	H("adurite_antlers", "Adurite Antlers", 162066057, "Common", 3299, "canopy"),

	-- Tier 2 Uncommon (D)
	H("halloween_santa_hat", "Halloween Santa Hat", 1173851, "Uncommon", 3301, "umbra"),
	H("icy_depths_fedora", "Icy Depths Fedora", 115300940, "Uncommon", 3672, "glacier"),
	H("perfectly_legitimate_business_hat", "Perfectly Legitimate Business Hat", 19027209, "Uncommon", 3843, "foundry"),
	H("friendly_fedora", "Friendly Fedora", 241542424, "Uncommon", 3860, "tide"),
	H("o_canada", "O Canada", 24487396, "Uncommon", 4013, "bedrock"),
	H("orange_banded_top_hat", "Orange Banded Top Hat", 134683641, "Uncommon", 4381, "foundry"),
	H("silverthorn_antlers", "Silverthorn Antlers", 9255011, "Uncommon", 6166, "glacier"),
	H("black_iron_antlers", "Black Iron Antlers", 398674411, "Uncommon", 9832, "bedrock"),
	H("yachting_fedora", "Yachting Fedora", 69938512, "Uncommon", 5947, "tide"),
	H("eight_bit_fedora", "8-Bit Fedora", 67995931, "Uncommon", 6529, "umbra"),
	H("green_banded_top_hat", "Green Banded Top Hat", 1563352, "Uncommon", 6573, "canopy"),
	H("inaugural_top_hat", "Inaugural Top Hat", 7248672, "Uncommon", 7047, "foundry"),
	H("kilty_mcjig_8bit_fedora", "Kilty McJig's 8-Bit Fedora", 96079349, "Uncommon", 9127, "umbra"),
	H("blue_banded_top_hat", "Blue Banded Top Hat", 46357082, "Uncommon", 12364, "bedrock"),

	-- Tier 3 Rare (C)
	H("mr_fancy_top_hat", "Mr. Fancy Top Hat", 125378389, "Rare", 12615, "foundry"),
	H("mathemagician", "Mathemagician", 32278846, "Rare", 14254, "umbra"),
	H("atomic_neon_top_hat", "Atomic Neon Top Hat", 100928653, "Rare", 15147, "glacier"),
	H("psychedelic_top_hat", "Psychedelic Top Hat", 80293983, "Rare", 15828, "foundry"),
	H("pinstripe_fedora", "Pinstripe Fedora", 14463095, "Rare", 18743, "foundry"),
	H("eight_bit_royal_crown", "8-Bit Royal Crown", 10159600649, "Rare", 22563, "bedrock"),
	H("blue_top_hat_white_band", "Blue Top Hat with White Band", 327318670, "Rare", 23349, "umbra"),
	H("ws_top_hat", "W's Top Hat", 12313531, "Rare", 24448, "umbra"),
	H("black_banded_orange_top_hat", "Black Banded Orange Top Hat", 2445212495, "Rare", 28084, "bedrock"),
	H("striped_red_fedora", "Striped Red Fedora", 119095672, "Rare", 28223, "foundry"),
	H("neon_pink_top_hat", "Neon Pink Top Hat", 376806474, "Rare", 29428, "glacier"),
	H("yellow_banded_top_hat", "Yellow Banded Top Hat", 124746065, "Rare", 29833, "umbra"),
	H("green_top_hat_white_band", "Green Top Hat with White Band", 1609394530, "Rare", 25546, "tide"),
	H("copper_crown_of_bronze", "Copper Crown of Bronze", 1483719462, "Rare", 31957, "glacier"),

	-- Tier 4 Epic (B)
	H("golden_top_hat_of_bling_bling", "Golden Top Hat of Bling Bling", 6552812, "Epic", 21817, "umbra"),
	H("big_purple_banded_top_hat", "BIG: Purple Banded Top Hat", 477859537, "Epic", 43014, "umbra"),
	H("azure_pinstripe_fedora", "Azure Pinstripe Fedora", 65417235, "Epic", 43299, "tide"),
	H("the_maker_fedora", "The Maker Fedora", 115363212, "Epic", 45769, "foundry"),
	H("sinister_top_hat", "Sinister Top Hat", 26380828, "Epic", 46137, "umbra"),
	H("st_patricks_fedora", "St Patrick's Fedora", 48039287, "Epic", 46916, "canopy"),
	H("brighteyes_top_hat", "Brighteyes' Top Hat", 169454280, "Epic", 48882, "umbra"),
	H("teddy_bear_hat", "Teddy Bear Hat", 1861997, "Epic", 50246, "canopy"),
	H("adurite_fedora", "Adurite Fedora", 162066176, "Epic", 59267, "umbra"),
	H("fancy_st_patricks_fedora", "Fancy St. Patrick's Fedora", 149594212, "Epic", 64216, "canopy"),
	H("the_devils_cowboy", "The Devil's Cowboy", 70437291, "Epic", 70941, "foundry"),
	H("sinister_king", "Sinister King", 40497339, "Epic", 77679, "umbra"),
	H("big_silverthorn_antlers", "BIG: Silverthorn Antlers", 477860473, "Epic", 79493, "glacier"),
	H("rainbow_fedora", "Rainbow Fedora", 82332012, "Epic", 92817, "glacier"),
	H("bunny_ear_fedora", "Bunny Ear Fedora", 108147416, "Epic", 95714, "canopy"),

	-- Tier 5 Legendary (A)
	H("sorcus_lightning_fedora", "Sorcus' Lightning Fedora", 169444030, "Legendary", 90201, "glacier"),
	H("viridian_domino_crown", "Viridian Domino Crown", 4390890198, "Legendary", 130363, "bedrock"),
	H("golden_crown", "Golden Crown", 1081300, "Legendary", 102886, "bedrock"),
	H("happy_time_magic_flower_hat", "Happy Time Magic Flower Hat", 5162497, "Legendary", 116651, "canopy"),
	H("washingtons_hat", "Washington's Hat", 12565866, "Legendary", 143729, "foundry"),
	H("pretty_pretty_princess", "Pretty Pretty Princess", 53039427, "Legendary", 160160, "umbra"),
	H("jj5x5_white_top_hat", "JJ5x5's White Top Hat", 1073690, "Legendary", 154884, "umbra"),
	H("wanwood_antlers", "Wanwood Antlers", 1272714, "Legendary", 329421, "canopy"),
	H("neon_pink_banded_top_hat", "Neon Pink Banded Top Hat", 493491411, "Legendary", 230907, "foundry"),
	H("classic_roblox_fedora", "The Classic ROBLOX Fedora", 1029025, "Legendary", 459251, "glacier"),
	H("sparkle_time_happy_time_magic_flower_hat", "Sparkle Time Happy Time Magic Flower Hat", 439985494, "Legendary", 262371, "canopy"),
	H("breakfast_top_hat", "Breakfast Top Hat", 158066152, "Legendary", 307591, "canopy"),

	-- Tier 6 Mythic (S)
	H("golden_antlers", "Golden Antlers", 193659065, "Mythic", 401954, "foundry"),
	H("adurite_crown", "Adurite Crown", 2163545468, "Mythic", 523054, "storm"),
	H("dominus_praefectus", "Dominus Praefectus", 527365852, "Mythic", 870853, "void"),
	H("new_years_2010_top_hat", "2010 New Year's Top Hat", 20044845, "Mythic", 1296575, "glacier"),
	H("the_crown_of_roses", "The Crown of Roses", 17449820, "Mythic", 2119359, "canopy"),
	H("red_void_star", "Red Void Star", 1191135761, "Mythic", 2879848, "inferno"),
	H("sparkle_time_fedora", "Sparkle Time Fedora", 1285307, "Mythic", 3284573, "prism"),
	H("the_void_star", "The Void Star", 1125510, "Mythic", 3425870, "void"),
	H("dominus_messor", "Dominus Messor", 64444871, "Mythic", 3824094, "umbra"),
	H("dominus_rex", "Dominus Rex", 250395631, "Mythic", 3857588, "bedrock"),

	-- Tier 7 Divine (SS)
	H("black_iron_crown_of_pwnage", "Black Iron Crown of Pwnage", 1078202, "Divine", 825132, "foundry"),
	H("dominus_vespertilio", "Dominus Vespertilio", 96103379, "Divine", 1836761, "umbra"),
	H("bluesteel_domino_crown", "Bluesteel Domino Crown", 68258723, "Divine", 1086250, "foundry"),
	H("frozen_horns_of_the_frigid_planes", "Frozen Horns of the Frigid Planes", 74891470, "Divine", 2047939, "glacier"),
	H("countess_of_the_federation", "Countess of the Federation", 188003914, "Divine", 2200000, "void"),
	H("poisoned_horns_toxic_wasteland", "Poisoned Horns of the Toxic Wasteland", 1744060292, "Divine", 1593337, "umbra"),
	H("fiery_horns_of_the_netherworld", "Fiery Horns of the Netherworld", 215718515, "Divine", 2285495, "inferno"),
	H("the_wanwood_crown", "The Wanwood Crown", 9910070, "Divine", 2442902, "canopy"),
	H("neon_party_top_hat", "Neon Party Top Hat", 430063272, "Divine", 1250671, "umbra"),
	H("black_iron_domino_crown_of_interns", "Black Iron Domino Crown of Interns", 264611665, "Divine", 2580879, "prism"),
	H("red_domino_crown", "Red Domino Crown", 42211680, "Divine", 2653087, "inferno"),
	H("duke_of_the_federation", "Duke of the Federation", 128158708, "Divine", 3469832, "storm"),
	H("white_sparkle_time_fedora", "White Sparkle Time Fedora", 1016143686, "Divine", 3958209, "glacier"),
	H("archduke_of_the_federation", "Archduke of the Federation", 293316452, "Divine", 4307413, "prism"),
	H("lady_of_the_federation", "Lady of the Federation", 207207782, "Divine", 5950184, "tide"),

	-- Tier 8 Exotic (SSS)
	H("dominus_infernus", "Dominus Infernus", 31101391, "Exotic", 1973087, "inferno"),
	H("blue_top_hat", "Blue Top Hat", 1016145591, "Exotic", 4336949, "canopy"),
	H("red_sparkle_time_fedora", "Red Sparkle Time Fedora", 72082328, "Exotic", 4871499, "inferno"),
	H("sky_blue_sparkle_time_fedora", "Sky Blue Sparkle Time Fedora", 493476042, "Exotic", 5504176, "tide"),
	H("domino_crown", "Domino Crown", 1031429, "Exotic", 5726071, "foundry"),
	H("black_sparkle_time_fedora", "Black Sparkle Time Fedora", 259423244, "Exotic", 5814995, "void"),
	H("pink_sparkle_time_fedora", "Pink Sparkle Time Fedora", 334663683, "Exotic", 6053763, "prism"),
	H("teal_sparkle_time_fedora", "Teal Sparkle Time Fedora", 147180077, "Exotic", 6212590, "tide"),
	H("green_sparkle_time_fedora", "Green Sparkle Time Fedora", 100929604, "Exotic", 6384970, "canopy"),
	H("dominus_pittacium", "Dominus Pittacium", 335080779, "Exotic", 6936989, "foundry"),
	H("dominus_aureus", "Dominus Aureus", 138932314, "Exotic", 7620311, "foundry"),
	H("omega_rainbow_top_hat", "Omega Rainbow Top Hat", 489176525, "Exotic", 7733715, "void"),
	H("orange_sparkle_time_fedora", "Orange Sparkle Time Fedora", 215751161, "Exotic", 9118953, "inferno"),
	H("purple_sparkle_time_fedora", "Purple Sparkle Time Fedora", 63043890, "Exotic", 10888103, "prism"),
	H("midnight_blue_sparkle_time_fedora", "Midnight Blue Sparkle Time Fedora", 119916949, "Exotic", 11328842, "umbra"),
	H("bluesteel_sparkle_time_fedora", "Bluesteel Sparkle Time Fedora", 98346834, "Exotic", 5100000, "tide"),
	H("dominus_empyreus", "Dominus Empyreus", 21070012, "Exotic", 13577229, "void"),
	H("dominus_astra", "Dominus Astra", 162067148, "Exotic", 14321557, "void"),
	H("dominus_frigidus", "Dominus Frigidus", 48545806, "Exotic", 28059680, "glacier"),
}

-- Face / Neck / Back from the RAP sheet -- coded, not rolled onto head.
MineHats.LEFTOVERS = {
	L("lucky_clover_necklace", "Lucky Clover Necklace", 96680926, "Common", 1674, "Neck", "canopy"),
	L("deluxe_ninja_swordpack", "Deluxe Ninja Swordpack", 67996263, "Common", 1789, "Back", "bedrock"),
	L("robling", "RoBLING", 49763745, "Common", 1989, "Neck", "foundry"),
	L("ninja_necktie", "Ninja Necktie", 71429414, "Uncommon", 2919, "Neck", "umbra"),
	L("ninja_smoke_screen_bandolier", "Ninja Smoke Screen Bandolier", 2544538622, "Uncommon", 3922, "Back", "umbra"),
	L("friendly_trusting_smile", "Friendly Trusting Smile", 402304145, "Uncommon", 5470, "Face", "tide"),
	L("camoface", "Camoface", 24441888, "Uncommon", 7593, "Face", "canopy"),
	L("snowman_face", "Snowman Face", 19396550, "Uncommon", 11463, "Face", "glacier"),
	L("pumpkin_necklace", "Pumpkin Necklace", 37820239, "Uncommon", 23882, "Neck", "umbra"),
	L("green_eyed_awesome_face", "Green-eyed Awesome Face", 66330144, "Rare", 18141, "Face", "canopy"),
	L("infernal_undead_immortal_sword", "Infernal Undead Immortal Sword", 2470750640, "Rare", 18963, "Back", "inferno"),
	L("purple_super_happy_joy", "Purple Super Happy Joy", 376812961, "Rare", 19973, "Face", "umbra"),
	L("snowflake_necklace", "Snowflake Necklace", 42847638, "Rare", 27955, "Neck", "glacier"),
	L("bejeweled_necklace", "Bejeweled Necklace", 40893248, "Rare", 32036, "Neck", "foundry"),
	L("bling_clock", "Bling Clock", 30380922, "Rare", 37499, "Neck", "foundry"),
	L("super_super_happy_face", "Super Super Happy Face", 494291269, "Epic", 51147, "Face", "glacier"),
	L("immortal_sword_vlads_lament", "Immortal Sword: Vlad's Lament", 1076571965, "Epic", 56834, "Back", "umbra"),
	L("lock_n_key_necklace", "Lock N Key Necklace", 53524217, "Epic", 57660, "Neck", "foundry"),
	L("immortal_sword_shameless_scimitar", "Immortal Sword: Shameless Scimitar", 1402447683, "Epic", 64802, "Back", "canopy"),
	L("immortal_sword_shattered_earth", "Immortal Sword: Shattered Earth", 2830451846, "Epic", 73287, "Back", "bedrock"),
	L("mr_bubbles", "Mr. Bubbles", 31616411, "Legendary", 96795, "Face", "tide"),
	L("bling_boys_raiment", "Bling Boy's Raiment", 52458643, "Legendary", 100398, "Neck", "foundry"),
	L("optimist", "Optimist", 21024661, "Legendary", 107010, "Face", "glacier"),
	L("wings_of_liberty", "Wings of Liberty", 416832622, "Legendary", 107875, "Back", "umbra"),
	L("immortal_sword_burning_embrace", "Immortal Sword: Burning Embrace", 835066252, "Legendary", 147271, "Back", "inferno"),
	L("umadbro", "Umadbro?", 51352983, "Legendary", 191142, "Neck", "umbra"),
	L("nerdy_computer_necklace", "Nerdy Computer Necklace", 34818884, "Legendary", 191521, "Neck", "storm"),
	L("eyes_of_azurewrath", "Eyes of Azurewrath", 17999992, "Legendary", 508637, "Face", "tide"),
	L("bluesteel_bling_necklace", "Bluesteel Bling $$ Necklace", 489196035, "Mythic", 377053, "Neck", "tide"),
	L("green_bow_tie", "Green Bow Tie", 16598513, "Mythic", 472013, "Neck", "canopy"),
	L("eyes_of_emeraldwrath", "Eyes of Emeraldwrath", 209994352, "Mythic", 548856, "Face", "canopy"),
	L("immortal_sword_the_piece_maker", "Immortal Sword: The Piece Maker", 416828455, "Mythic", 554374, "Back", "foundry"),
	L("defklace", "Defklace", 32567578, "Mythic", 640600, "Neck", "void"),
	L("green_glowing_eyes", "Green Glowing Eyes", 398676450, "Mythic", 702334, "Face", "canopy"),
	L("eyes_of_crimsonwrath", "Eyes of Crimsonwrath", 49493376, "Mythic", 769744, "Face", "inferno"),
	L("interstellar_wings", "Interstellar Wings", 557057917, "Mythic", 854236, "Back", "void"),
	L("yellow_glowing_eyes", "Yellow Glowing Eyes", 416846000, "Mythic", 1053018, "Face", "storm"),
	L("transient_harmonica", "Transient Harmonica", 33070696, "Mythic", 1466308, "Neck", "prism"),
	L("old_glory_wings", "Old Glory Wings", 2015363653, "Divine", 176536, "Back", "storm"),
	L("immortal_sword_wicked_heart", "Immortal Sword - Wicked Heart", 2222720521, "Divine", 276512, "Back", "umbra"),
	L("living_art_starry_night", "Living Art: Starry Night", 97078419, "Divine", 350000, "Neck", "void"),
	L("goldlika_patriot", "Goldlika: Patriot", 445115703, "Divine", 364568, "Neck", "foundry"),
	L("immortal_sword_endless_ice_slasher", "Immortal Sword: Endless Ice Slasher", 568920951, "Divine", 429604, "Back", "glacier"),
	L("bling_dollar_necklace", "Bling $$ Necklace", 33171947, "Exotic", 4045444, "Neck", "foundry"),
	L("red_tango", "Red Tango", 16652251, "Exotic", 4588638, "Face", "inferno"),
	L("epic_face", "Epic Face", 42070576, "Legendary", 250000, "Face", "storm"),
	L("beast_mode", "Beast Mode", 128992838, "Mythic", 51837, "Face", "inferno"),
	L("blizzard_beast_mode", "Blizzard Beast Mode", 209995252, "Mythic", 120000, "Face", "glacier"),
	L("radioactive_beast_mode", "Radioactive Beast Mode", 2225761296, "Mythic", 180000, "Face", "canopy"),
	L("poisonous_beast_mode", "Poisonous Beast Mode", 2606177838, "Mythic", 200000, "Face", "umbra"),
	L("red_glowing_eyes", "Red Glowing Eyes", 180660043, "Mythic", 400000, "Face", "inferno"),
	L("red_rawr", "Red RAWR", 66330295, "Rare", 15000, "Face", "inferno"),
	L("man_face", "Man Face", 86487700, "Uncommon", 8000, "Face", "bedrock"),
	L("woman_face", "Woman Face", 86487766, "Uncommon", 8000, "Face", "prism"),
}

MineHats.BY_ID = {}
MineHats.BY_GRADE = {}
MineHats.DROP_BY_GRADE = {}

local function index(row)
	MineHats.BY_ID[row.id] = row
	local g = row.grade
	MineHats.BY_GRADE[g] = MineHats.BY_GRADE[g] or {}
	table.insert(MineHats.BY_GRADE[g], row)
	if row.drop then
		MineHats.DROP_BY_GRADE[g] = MineHats.DROP_BY_GRADE[g] or {}
		table.insert(MineHats.DROP_BY_GRADE[g], row)
	end
end

for _, row in ipairs(MineHats.LIST) do
	index(row)
end
for _, row in ipairs(MineHats.LEFTOVERS) do
	index(row)
end

--[[
	Faces are the player's own piece, so they get their own pool. Every Face in
	LEFTOVERS is droppable as a face now; Neck and Back stay out of the game
	because there is no slot for them.
]]
MineHats.FACE_BY_GRADE = {}
for _, row in ipairs(MineHats.LEFTOVERS) do
	if row.kind == "Face" then
		MineHats.FACE_BY_GRADE[row.grade] = MineHats.FACE_BY_GRADE[row.grade] or {}
		table.insert(MineHats.FACE_BY_GRADE[row.grade], row)
	end
end

function MineHats.def(id)
	return MineHats.BY_ID[tostring(id or "")]
end

function MineHats.thumb(catalogId)
	catalogId = tonumber(catalogId)
	if not catalogId then
		return nil
	end
	return string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", catalogId)
end

function MineHats.image(rowOrPiece)
	if type(rowOrPiece) ~= "table" then
		return nil
	end
	local id = rowOrPiece.catalogId
	if not id and rowOrPiece.hatId then
		local def = MineHats.def(rowOrPiece.hatId)
		id = def and def.catalogId
	end
	return MineHats.thumb(id)
end

function MineHats.rollDrop(gradeOrPrint, rng)
	rng = rng or Random.new()
	local grade = MineHats.GRADE_OF[gradeOrPrint] or gradeOrPrint
	local pool = MineHats.DROP_BY_GRADE[grade]
	if not pool or #pool == 0 then
		return nil
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- Prefer a droppable hat whose setId matches (keeps buff verb aligned with identity).
function MineHats.rollForSet(gradeOrPrint, setId, rng)
	rng = rng or Random.new()
	local grade = MineHats.GRADE_OF[gradeOrPrint] or gradeOrPrint
	local pool = MineHats.DROP_BY_GRADE[grade]
	if not pool or #pool == 0 then
		return nil
	end
	if setId and setId ~= "" then
		local matched = {}
		for _, h in ipairs(pool) do
			if h.setId == setId then
				table.insert(matched, h)
			end
		end
		if #matched > 0 then
			return matched[rng:NextInteger(1, #matched)]
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

--[[
	The face pools have holes: the RAP sheet's cheapest face is an Uncommon, and
	some bands have none at all. nearestFaceGrade is what keeps that honest --
	the ROLL is moved to a grade that actually has a face in it, rather than
	handing out an Uncommon face wearing an SS label.
]]
MineHats.GRADE_LADDER = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }

function MineHats.nearestFaceGrade(gradeOrPrint)
	local grade = MineHats.GRADE_OF[gradeOrPrint] or gradeOrPrint
	local at
	for i, g in ipairs(MineHats.GRADE_LADDER) do
		if g == grade then
			at = i
			break
		end
	end
	if not at then
		return grade
	end
	local pool = MineHats.FACE_BY_GRADE[grade]
	if pool and #pool > 0 then
		return grade
	end
	-- Down first (never hand out a grade nobody earned), then up.
	for step = 1, #MineHats.GRADE_LADDER do
		local lower = MineHats.GRADE_LADDER[at - step]
		if lower and MineHats.FACE_BY_GRADE[lower] and #MineHats.FACE_BY_GRADE[lower] > 0 then
			return lower
		end
		local upper = MineHats.GRADE_LADDER[at + step]
		if upper and MineHats.FACE_BY_GRADE[upper] and #MineHats.FACE_BY_GRADE[upper] > 0 then
			return upper
		end
	end
	return grade
end

-- The cheapest face on the RAP sheet is an Uncommon, so an F roll is served the
-- nearest pool that exists rather than nothing at all.
function MineHats.rollFace(gradeOrPrint, setId, rng)
	rng = rng or Random.new()
	local grade = MineHats.GRADE_OF[gradeOrPrint] or gradeOrPrint
	local pool = MineHats.FACE_BY_GRADE[grade]
	if not pool or #pool == 0 then
		for _, g in ipairs({ "D", "C", "B", "A", "S", "SS", "SSS" }) do
			pool = MineHats.FACE_BY_GRADE[g]
			if pool and #pool > 0 then
				break
			end
		end
	end
	if not pool or #pool == 0 then
		return nil
	end
	if setId and setId ~= "" then
		local matched = {}
		for _, f in ipairs(pool) do
			if f.setId == setId then
				table.insert(matched, f)
			end
		end
		if #matched > 0 then
			return matched[rng:NextInteger(1, #matched)]
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- One door for gear rolls: give it a slot and a grade, get a catalog item.
function MineHats.rollFor(slot, gradeOrPrint, setId, rng)
	if slot == "face" then
		return MineHats.rollFace(gradeOrPrint, setId, rng)
	end
	return MineHats.rollForSet(gradeOrPrint, setId, rng)
end

function MineHats.counts()
	local drop, leftovers = 0, 0
	for _, r in ipairs(MineHats.LIST) do
		if r.drop then
			drop += 1
		end
	end
	leftovers = #MineHats.LEFTOVERS
	local byGrade = {}
	for g, list in pairs(MineHats.DROP_BY_GRADE) do
		byGrade[g] = #list
	end
	return { drop = drop, leftovers = leftovers, byGrade = byGrade }
end

return MineHats

-- synced 1789981225
