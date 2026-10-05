-- MineDepth: three depth games + section HP from zone-layer-docs.
-- Bands: surface/shallow 1-500, deeprock/mid 501-1500, shadowzone/deep 1501-2500, abyss 2501+.
-- Player-facing names: Surface · Deeprock · Shadowzone (ids stay shallow/mid/deep).
-- Island HP = meadowHp * 6^(zoneIndex-1).

local MineDepth = {}

MineDepth.ZONE_HP_MULT = 5 -- x5 per zone. Ten zones is a bounded set, so a
-- geometric zone term is safe; depth is unbounded, so its term is linear.
-- Outposts every 500 to 3000, then every 1000 to 10000. The widening is
-- deliberate: 500 layers is a shorter and shorter stretch of progress the deeper
-- you go, so past 3000 the same effort buys one outpost instead of two.
--
-- 10000 is the LAST seam, not the bottom of the mine. gateForLayer returns the
-- deepest seam at or below a layer, so buying 10000 opens everything beneath it
-- and depth carries on by the same formula with no further gate or outpost.
MineDepth.SEAMS = { 500, 1000, 1500, 2000, 2500, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000 }
MineDepth.AIR_GAP = 5 -- layers of air ending at seam (e.g. 496-500)
MineDepth.DEPTH_SELL_FRAC = 0.78
MineDepth.COMING_SOON_SEAM = 99999
MineDepth.COMING_SOON_PLAYERS = 50
MineDepth.DIG_LEAD = 8
-- Prestige to use depth plazas / dig past seams, by zone:
--   band B (500 / Deeprock):  10, 20, 30… = 10 * zoneIndex
--   band C (1500 / Shadowzone): 70, 80, 90… = 60 + 10 * zoneIndex
MineDepth.REBIRTH_PER_ZONE_B = 10
MineDepth.REBIRTH_BAND_C_BASE = 60

-- COIN-PRICED DEPTH GATES.
--
-- These gate SEAMS -- the same 500-layer ladder that MineDepthPlazas,
-- MineDepthShop, MineDigAuth and world gen already read for desks, sell pads and
-- air gaps. One ladder, not two. A separate doubling ladder
-- (100/200/400...12800) was written first and dropped: a second set of depths to
-- reason about is a dial this game does not need, and its top rung sat below no
-- outpost at all. Gating on SEAMS also lands every gate on an air gap that is
-- already generated there.
--
-- Fixed widths do mean the PRICE step decays -- 2.64x at the first gate, 1.10x
-- at the last. That is the shrinking relative growth of a linear curve and no
-- multiplier fixes it. It costs nothing in fairness: price is derived from the
-- band's own income, so every gate is SEAM_MINUTES of play no matter how wide
-- the band is. What it costs is signposting, and markers are a display concern.
--
-- Why this exists: rebirthForSeam and rebirthForLayer both return 0, so depth is
-- gated by nothing at all and the only brake on a new player reaching layer 5000
-- is the anti-teleport position check in MineDigAuth. Ore tool power follows
-- depth, so an ungated depth axis is an ungated POWER axis -- that is the
-- bootstrap loop, and this is its brake.

-- Price is stored as MINUTES of the income available just above the seam, and the
-- coin figure is derived. A hardcoded coin number goes stale the moment the block
-- rate or the coin curve moves, and both are still being tuned.
MineDepth.SEAM_MINUTES = 30
-- Measured, not assumed: a fresh account at Meadow layer 1 breaks 2,016 blocks an
-- hour (wood pick power 4 x rate 2.8 against 20 HP dirt). Rounded to 2,000.
MineDepth.GATE_BLOCKS_PER_HOUR = 2000
-- coinValue(Z,L) = 5^(Z-1) * (1 + COIN_DEPTH*L)^COIN_POW. Zone term is factored
-- out of seamPrice so the ladder costs the same number of minutes in every zone.
MineDepth.GATE_COIN_ZONE = 5
MineDepth.GATE_COIN_DEPTH = 0.075
MineDepth.GATE_COIN_POW = 0.9

-- 20 authored sections (midpoint dirt HP). Exclusive spawn sits inside a band.
-- Shallow band = the design curve (zone-layer-docs, PROGRESSION_AUDIT: Loam 10 -> Crimson
-- 5,500). It had been raised ~3.75x (Loam 15, Ashen 83...), which made the first
-- twenty minutes a slog with nothing one-shot; restored 2026-09-19. Mid/deep keep
-- the values their desk tools are sized for.
MineDepth.SECTIONS = {
	{ id = "loam_1", name = "Loam", layers = { 1, 40 }, dirtHp = 10, band = "shallow" },
	{ id = "topsoil_2", name = "Topsoil", layers = { 41, 80 }, dirtHp = 22, band = "shallow" },
	{ id = "sod_3", name = "Sod", layers = { 81, 120 }, dirtHp = 47, band = "shallow" },
	{ id = "clay_4", name = "Clay", layers = { 121, 160 }, dirtHp = 101, band = "shallow" },
	{ id = "marl_5", name = "Marl", layers = { 161, 200 }, dirtHp = 217, band = "shallow" },
	{ id = "peat_6", name = "Peat", layers = { 201, 240 }, dirtHp = 467, band = "shallow" },
	{ id = "silt_7", name = "Silt", layers = { 241, 280 }, dirtHp = 1004, band = "shallow" },
	{ id = "ochre_8", name = "Ochre", layers = { 281, 320 }, dirtHp = 2159, band = "shallow" },
	{ id = "humus_9", name = "Humus", layers = { 321, 360 }, dirtHp = 4642, band = "shallow" },
	{ id = "mudflat_10", name = "Mudflat", layers = { 361, 400 }, dirtHp = 9980, band = "shallow" },
	{ id = "ashsoil_11", name = "Ashsoil", layers = { 401, 440 }, dirtHp = 15469, band = "shallow" },
	{ id = "redclay_12", name = "Redclay", layers = { 441, 480 }, dirtHp = 23977, band = "shallow" },
	{ id = "blackearth_13", name = "Blackearth", layers = { 481, 520 }, dirtHp = 37164, band = "mid" },
	{ id = "meadowdirt_14", name = "Meadowdirt", layers = { 521, 560 }, dirtHp = 57604, band = "mid" },
	{ id = "fernsoil_15", name = "Fernsoil", layers = { 561, 600 }, dirtHp = 89286, band = "mid" },
	{ id = "rootbed_16", name = "Rootbed", layers = { 601, 640 }, dirtHp = 138393, band = "mid" },
	{ id = "compost_17", name = "Compost", layers = { 641, 680 }, dirtHp = 214509, band = "mid" },
	{ id = "softmarl_18", name = "Softmarl", layers = { 681, 720 }, dirtHp = 332489, band = "mid" },
	{ id = "wetclay_19", name = "Wetclay", layers = { 721, 760 }, dirtHp = 515358, band = "mid" },
	{ id = "leafmold_20", name = "Leafmold", layers = { 761, 800 }, dirtHp = 798805, band = "mid" },
	{ id = "ironsoil_21", name = "Ironsoil", layers = { 801, 840 }, dirtHp = 1238148, band = "mid" },
	{ id = "nightclay_22", name = "Nightclay", layers = { 841, 880 }, dirtHp = 1919129, band = "mid" },
	{ id = "embersoil_23", name = "Embersoil", layers = { 881, 920 }, dirtHp = 2974650, band = "mid" },
	{ id = "gloomdirt_24", name = "Gloomdirt", layers = { 921, 960 }, dirtHp = 4610708, band = "mid" },
	{ id = "mossbed_25", name = "Mossbed", layers = { 961, 1000 }, dirtHp = 7146597, band = "mid" },
	{ id = "hollowchalk_26", name = "Hollowchalk", layers = { 1001, 1080 }, dirtHp = 9147645, band = "mid" },
	{ id = "shaleflint_27", name = "Shaleflint", layers = { 1081, 1160 }, dirtHp = 11708986, band = "mid" },
	{ id = "duskslate_28", name = "Duskslate", layers = { 1161, 1240 }, dirtHp = 14987503, band = "mid" },
	{ id = "gravestone_29", name = "Gravestone", layers = { 1241, 1320 }, dirtHp = 19184004, band = "mid" },
	{ id = "pitchshale_30", name = "Pitchshale", layers = { 1321, 1400 }, dirtHp = 24555526, band = "mid" },
	{ id = "widowrock_31", name = "Widowrock", layers = { 1401, 1480 }, dirtHp = 31431074, band = "mid" },
	{ id = "bonestone_32", name = "Bonestone", layers = { 1481, 1560 }, dirtHp = 40231775, band = "mid" },
	{ id = "cinderrock_33", name = "Cinderrock", layers = { 1561, 1640 }, dirtHp = 51496672, band = "mid" },
	{ id = "blackslate_34", name = "Blackslate", layers = { 1641, 1720 }, dirtHp = 65915741, band = "mid" },
	{ id = "veinrock_35", name = "Veinrock", layers = { 1721, 1800 }, dirtHp = 84372149, band = "mid" },
	{ id = "quarryrock_36", name = "Quarryrock", layers = { 1801, 1880 }, dirtHp = 107996351, band = "mid" },
	{ id = "ironstone_37", name = "Ironstone", layers = { 1881, 1960 }, dirtHp = 138235330, band = "mid" },
	{ id = "deeprock_38", name = "Deeprock", layers = { 1961, 2040 }, dirtHp = 176941223, band = "mid" },
	{ id = "nightstone_39", name = "Nightstone", layers = { 2041, 2120 }, dirtHp = 226484766, band = "mid" },
	{ id = "emberflint_40", name = "Emberflint", layers = { 2121, 2200 }, dirtHp = 289900501, band = "mid" },
	{ id = "gloomstone_41", name = "Gloomstone", layers = { 2201, 2280 }, dirtHp = 371072642, band = "mid" },
	{ id = "aetherrock_42", name = "Aetherrock", layers = { 2281, 2360 }, dirtHp = 474972982, band = "mid" },
	{ id = "voidstone_43", name = "Voidstone", layers = { 2361, 2440 }, dirtHp = 607965417, band = "mid" },
	{ id = "starite_44", name = "Starite", layers = { 2441, 2520 }, dirtHp = 778195734, band = "mid" },
	{ id = "mythrock_45", name = "Mythrock", layers = { 2521, 2600 }, dirtHp = 996090540, band = "mid" },
	{ id = "endstone_46", name = "Endstone", layers = { 2601, 2680 }, dirtHp = 1274995892, band = "mid" },
	{ id = "abyssrock_47", name = "Abyssrock", layers = { 2681, 2760 }, dirtHp = 1631994742, band = "mid" },
	{ id = "cryptstone_48", name = "Cryptstone", layers = { 2761, 2840 }, dirtHp = 2088953270, band = "mid" },
	{ id = "nullrock_49", name = "Nullrock", layers = { 2841, 2920 }, dirtHp = 2673860186, band = "mid" },
	{ id = "obsidian_50", name = "Obsidian", layers = { 2921, 3000 }, dirtHp = 3422541039, band = "mid" },
	{ id = "riftstone_51", name = "Riftstone", layers = { 3001, 3080 }, dirtHp = 4380852530, band = "deep" },
	{ id = "scarrock_52", name = "Scarrock", layers = { 3081, 3160 }, dirtHp = 5607491239, band = "deep" },
	{ id = "moonstone_53", name = "Moonstone", layers = { 3161, 3240 }, dirtHp = 7177588786, band = "deep" },
	{ id = "eclipseite_54", name = "Eclipseite", layers = { 3241, 3320 }, dirtHp = 9187313647, band = "deep" },
	{ id = "sollite_55", name = "Sollite", layers = { 3321, 3400 }, dirtHp = 11759761469, band = "deep" },
	{ id = "asterrock_56", name = "Asterrock", layers = { 3401, 3480 }, dirtHp = 15052494681, band = "deep" },
	{ id = "nebulite_57", name = "Nebulite", layers = { 3481, 3560 }, dirtHp = 19267193192, band = "deep" },
	{ id = "cosmorock_58", name = "Cosmorock", layers = { 3561, 3640 }, dirtHp = 24662007286, band = "deep" },
	{ id = "singulite_59", name = "Singulite", layers = { 3641, 3720 }, dirtHp = 31567369327, band = "deep" },
	{ id = "eventite_60", name = "Eventite", layers = { 3721, 3800 }, dirtHp = 40406232739, band = "deep" },
	{ id = "darkstone_61", name = "Darkstone", layers = { 3801, 3880 }, dirtHp = 51719977906, band = "deep" },
	{ id = "horizonite_62", name = "Horizonite", layers = { 3881, 3960 }, dirtHp = 66201571720, band = "deep" },
	{ id = "corestone_63", name = "Corestone", layers = { 3961, 4040 }, dirtHp = 84738011802, band = "deep" },
	{ id = "primordite_64", name = "Primordite", layers = { 4041, 4120 }, dirtHp = 108464655107, band = "deep" },
	{ id = "mantlerock_65", name = "Mantlerock", layers = { 4121, 4200 }, dirtHp = 138834758537, band = "deep" },
	{ id = "crustite_66", name = "Crustite", layers = { 4201, 4280 }, dirtHp = 177708490928, band = "deep" },
	{ id = "magmarock_67", name = "Magmarock", layers = { 4281, 4360 }, dirtHp = 227466868388, band = "deep" },
	{ id = "pressureite_68", name = "Pressureite", layers = { 4361, 4440 }, dirtHp = 291157591537, band = "deep" },
	{ id = "fathomstone_69", name = "Fathomstone", layers = { 4441, 4520 }, dirtHp = 372681717168, band = "deep" },
	{ id = "leviathanite_70", name = "Leviathanite", layers = { 4521, 4600 }, dirtHp = 477032597976, band = "deep" },
	{ id = "krakenstone_71", name = "Krakenstone", layers = { 4601, 4680 }, dirtHp = 610601725410, band = "deep" },
	{ id = "trenchite_72", name = "Trenchite", layers = { 4681, 4760 }, dirtHp = 781570208525, band = "deep" },
	{ id = "hadalrock_73", name = "Hadalrock", layers = { 4761, 4840 }, dirtHp = 1000409866912, band = "deep" },
	{ id = "inkstone_74", name = "Inkstone", layers = { 4841, 4920 }, dirtHp = 1280524629648, band = "deep" },
	{ id = "finalite_75", name = "Finalite", layers = { 4921, 5000 }, dirtHp = 1639071525950, band = "deep" },
	-- The curve used to stop here. sectionFor returned Finalite for every
	-- layer past 4921, so L5000, L10000 and L50000 were identical rock --
	-- five thousand layers of digging for no increase in anything. These
	-- continue the deep band's own 1.28x step, so NOTHING above 5000 moves.
	{ id = "aftermath_76", name = "Aftermath", layers = { 5001, 5080 }, dirtHp = 2.09801e+12, band = "deep" },
	{ id = "nullshelf_77", name = "Nullshelf", layers = { 5081, 5160 }, dirtHp = 2.68545e+12, band = "deep" },
	{ id = "voidcrust_78", name = "Voidcrust", layers = { 5161, 5240 }, dirtHp = 3.43738e+12, band = "deep" },
	{ id = "hollowdeep_79", name = "Hollowdeep", layers = { 5241, 5320 }, dirtHp = 4.39985e+12, band = "deep" },
	{ id = "blackreach_80", name = "Blackreach", layers = { 5321, 5400 }, dirtHp = 5.63181e+12, band = "deep" },
	{ id = "sunkstone_81", name = "Sunkstone", layers = { 5401, 5480 }, dirtHp = 7.20871e+12, band = "deep" },
	{ id = "dreadrock_82", name = "Dreadrock", layers = { 5481, 5560 }, dirtHp = 9.22715e+12, band = "deep" },
	{ id = "mournstone_83", name = "Mournstone", layers = { 5561, 5640 }, dirtHp = 1.18108e+13, band = "deep" },
	{ id = "gravewell_84", name = "Gravewell", layers = { 5641, 5720 }, dirtHp = 1.51178e+13, band = "deep" },
	{ id = "lastlight_85", name = "Lastlight", layers = { 5721, 5800 }, dirtHp = 1.93507e+13, band = "deep" },
	{ id = "duskfall_86", name = "Duskfall", layers = { 5801, 5880 }, dirtHp = 2.47689e+13, band = "deep" },
	{ id = "nethercrust_87", name = "Nethercrust", layers = { 5881, 5960 }, dirtHp = 3.17043e+13, band = "deep" },
	{ id = "umbralrock_88", name = "Umbralrock", layers = { 5961, 6040 }, dirtHp = 4.05814e+13, band = "deep" },
	{ id = "silentstone_89", name = "Silentstone", layers = { 6041, 6120 }, dirtHp = 5.19443e+13, band = "deep" },
	{ id = "coldforge_90", name = "Coldforge", layers = { 6121, 6200 }, dirtHp = 6.64886e+13, band = "deep" },
	{ id = "deadvein_91", name = "Deadvein", layers = { 6201, 6280 }, dirtHp = 8.51055e+13, band = "deep" },
	{ id = "ashenfall_92", name = "Ashenfall", layers = { 6281, 6360 }, dirtHp = 1.08935e+14, band = "deep" },
	{ id = "ruinstone_93", name = "Ruinstone", layers = { 6361, 6440 }, dirtHp = 1.39437e+14, band = "deep" },
	{ id = "sorrowrock_94", name = "Sorrowrock", layers = { 6441, 6520 }, dirtHp = 1.78479e+14, band = "deep" },
	{ id = "fadestone_95", name = "Fadestone", layers = { 6521, 6600 }, dirtHp = 2.28453e+14, band = "deep" },
	{ id = "wraithrock_96", name = "Wraithrock", layers = { 6601, 6680 }, dirtHp = 2.9242e+14, band = "deep" },
	{ id = "palefall_97", name = "Palefall", layers = { 6681, 6760 }, dirtHp = 3.74298e+14, band = "deep" },
	{ id = "grimstone_98", name = "Grimstone", layers = { 6761, 6840 }, dirtHp = 4.79101e+14, band = "deep" },
	{ id = "hushrock_99", name = "Hushrock", layers = { 6841, 6920 }, dirtHp = 6.13249e+14, band = "deep" },
	{ id = "veilstone_100", name = "Veilstone", layers = { 6921, 7000 }, dirtHp = 7.84959e+14, band = "deep" },
	{ id = "chasmrock_101", name = "Chasmrock", layers = { 7001, 7080 }, dirtHp = 1.00475e+15, band = "deep" },
	{ id = "abyssfall_102", name = "Abyssfall", layers = { 7081, 7160 }, dirtHp = 1.28608e+15, band = "deep" },
	{ id = "deepnull_103", name = "Deepnull", layers = { 7161, 7240 }, dirtHp = 1.64618e+15, band = "deep" },
	{ id = "farstone_104", name = "Farstone", layers = { 7241, 7320 }, dirtHp = 2.10711e+15, band = "deep" },
	{ id = "endreach_105", name = "Endreach", layers = { 7321, 7400 }, dirtHp = 2.6971e+15, band = "deep" },
	{ id = "lostvein_106", name = "Lostvein", layers = { 7401, 7480 }, dirtHp = 3.45229e+15, band = "deep" },
	{ id = "bleakrock_107", name = "Bleakrock", layers = { 7481, 7560 }, dirtHp = 4.41893e+15, band = "deep" },
	{ id = "frostnull_108", name = "Frostnull", layers = { 7561, 7640 }, dirtHp = 5.65623e+15, band = "deep" },
	{ id = "ironnight_109", name = "Ironnight", layers = { 7641, 7720 }, dirtHp = 7.23997e+15, band = "deep" },
	{ id = "shardrock_110", name = "Shardrock", layers = { 7721, 7800 }, dirtHp = 9.26716e+15, band = "deep" },
	{ id = "glasscrust_111", name = "Glasscrust", layers = { 7801, 7880 }, dirtHp = 1.1862e+16, band = "deep" },
	{ id = "riftfall_112", name = "Riftfall", layers = { 7881, 7960 }, dirtHp = 1.51833e+16, band = "deep" },
	{ id = "tearstone_113", name = "Tearstone", layers = { 7961, 8040 }, dirtHp = 1.94347e+16, band = "deep" },
	{ id = "scarnull_114", name = "Scarnull", layers = { 8041, 8120 }, dirtHp = 2.48764e+16, band = "deep" },
	{ id = "breakstone_115", name = "Breakstone", layers = { 8121, 8200 }, dirtHp = 3.18417e+16, band = "deep" },
	{ id = "cleftrock_116", name = "Cleftrock", layers = { 8201, 8280 }, dirtHp = 4.07574e+16, band = "deep" },
	{ id = "fracturite_117", name = "Fracturite", layers = { 8281, 8360 }, dirtHp = 5.21695e+16, band = "deep" },
	{ id = "splitstone_118", name = "Splitstone", layers = { 8361, 8440 }, dirtHp = 6.6777e+16, band = "deep" },
	{ id = "shearrock_119", name = "Shearrock", layers = { 8441, 8520 }, dirtHp = 8.54745e+16, band = "deep" },
	{ id = "crushstone_120", name = "Crushstone", layers = { 8521, 8600 }, dirtHp = 1.09407e+17, band = "deep" },
	{ id = "pressfall_121", name = "Pressfall", layers = { 8601, 8680 }, dirtHp = 1.40041e+17, band = "deep" },
	{ id = "weightstone_122", name = "Weightstone", layers = { 8681, 8760 }, dirtHp = 1.79253e+17, band = "deep" },
	{ id = "densecore_123", name = "Densecore", layers = { 8761, 8840 }, dirtHp = 2.29444e+17, band = "deep" },
	{ id = "leadenrock_124", name = "Leadenrock", layers = { 8841, 8920 }, dirtHp = 2.93688e+17, band = "deep" },
	{ id = "heavystone_125", name = "Heavystone", layers = { 8921, 9000 }, dirtHp = 3.75921e+17, band = "deep" },
	{ id = "massrock_126", name = "Massrock", layers = { 9001, 9080 }, dirtHp = 4.81179e+17, band = "deep" },
	{ id = "gravitite_127", name = "Gravitite", layers = { 9081, 9160 }, dirtHp = 6.15909e+17, band = "deep" },
	{ id = "collapsite_128", name = "Collapsite", layers = { 9161, 9240 }, dirtHp = 7.88363e+17, band = "deep" },
	{ id = "implodite_129", name = "Implodite", layers = { 9241, 9320 }, dirtHp = 1.0091e+18, band = "deep" },
	{ id = "singulstone_130", name = "Singulstone", layers = { 9321, 9400 }, dirtHp = 1.29165e+18, band = "deep" },
	{ id = "eventfall_131", name = "Eventfall", layers = { 9401, 9480 }, dirtHp = 1.65332e+18, band = "deep" },
	{ id = "horizonfall_132", name = "Horizonfall", layers = { 9481, 9560 }, dirtHp = 2.11625e+18, band = "deep" },
	{ id = "lightless_133", name = "Lightless", layers = { 9561, 9640 }, dirtHp = 2.7088e+18, band = "deep" },
	{ id = "nullcore_134", name = "Nullcore", layers = { 9641, 9720 }, dirtHp = 3.46726e+18, band = "deep" },
	{ id = "voidheart_135", name = "Voidheart", layers = { 9721, 9800 }, dirtHp = 4.43809e+18, band = "deep" },
	{ id = "endcore_136", name = "Endcore", layers = { 9801, 9880 }, dirtHp = 5.68075e+18, band = "deep" },
	{ id = "finality_137", name = "Finality", layers = { 9881, 9960 }, dirtHp = 7.27137e+18, band = "deep" },
	{ id = "terminus_138", name = "Terminus", layers = { 9961, 10040 }, dirtHp = 9.30735e+18, band = "deep" },
}

local COLORS = {
	loam = Color3.fromRGB(150, 110, 72), ashen = Color3.fromRGB(120, 120, 124),
	clay = Color3.fromRGB(168, 98, 72), ochre = Color3.fromRGB(180, 140, 70),
	slate = Color3.fromRGB(90, 102, 118), umber = Color3.fromRGB(86, 58, 42),
	verdant = Color3.fromRGB(70, 96, 64), cinder = Color3.fromRGB(78, 54, 44),
	rime = Color3.fromRGB(170, 190, 210), crimson = Color3.fromRGB(140, 48, 48),
	basalt = Color3.fromRGB(60, 60, 68), ironsoil = Color3.fromRGB(90, 78, 70),
	nightclay = Color3.fromRGB(48, 52, 72), pyre = Color3.fromRGB(160, 70, 40),
	gloomar = Color3.fromRGB(40, 48, 70), aether = Color3.fromRGB(90, 120, 160),
	voidloam = Color3.fromRGB(40, 30, 55), starash = Color3.fromRGB(180, 170, 140),
	mythril_dirt = Color3.fromRGB(120, 140, 180), endsoil = Color3.fromRGB(30, 28, 36),
}
for i, sec in ipairs(MineDepth.SECTIONS) do
	if not COLORS[sec.id] then
		local t = (i - 1) / math.max(1, #MineDepth.SECTIONS - 1)
		COLORS[sec.id] = Color3.fromRGB(math.floor(40 + 80 * (1 - t)), math.floor(35 + 50 * (1 - t)), math.floor(45 + 70 * t))
	end
	sec.color = COLORS[sec.id]
end

function MineDepth.bandForLayer(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	if layer <= 500 then
		return "shallow"
	elseif layer <= 1500 then
		return "mid"
	end
	return "deep"
end

-- Player-facing band labels (c = Shadowzone).
MineDepth.BAND_LABEL = {
	shallow = "Surface",
	surface = "Surface",
	mid = "Deeprock",
	deeprock = "Deeprock",
	deep = "Shadowzone",
	shadowzone = "Shadowzone",
}

function MineDepth.bandLabel(band)
	return MineDepth.BAND_LABEL[tostring(band or "")] or tostring(band or "")
end

function MineDepth.normalizeBand(band)
	band = tostring(band or "")
	if band == "surface" then return "shallow" end
	if band == "deeprock" then return "mid" end
	if band == "shadowzone" then return "deep" end
	return band
end

function MineDepth.sectionFor(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	for _, s in ipairs(MineDepth.SECTIONS) do
		if layer >= s.layers[1] and layer <= s.layers[2] then
			return s
		end
	end
	return MineDepth.SECTIONS[#MineDepth.SECTIONS]
end

function MineDepth.sectionIndex(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local s = MineDepth.sectionFor(layer)
	for i, row in ipairs(MineDepth.SECTIONS) do
		if row == s then
			return i - 1
		end
	end
	return 0
end

function MineDepth.sectionNumber(layer)
	return MineDepth.sectionIndex(layer) + 1
end

--[[
	BLOCK HP IS A STRAIGHT LINE.

	    dirtHp(Z, L) = (HP_BASE + HP_PER_LAYER * L) * ZONE_HP_MULT^(Z-1)

	It used to be read off SECTIONS, which multiplied by 2.1495 every 40 layers
	-- x432 across 320 layers and roughly 1e80 by layer 10,000. SECTIONS still
	authors Terminus at 9.3e18, which is 1,033x past 2^53, so damage arithmetic
	was losing precision inside the reachable game. Linear tops out at 29.3
	billion in Primordium at layer 10,000, leaving 307,000x of headroom under
	2^53 and needing no big-number type.

	Depth is unbounded, so nothing indexed by it may be geometric. Zones are a
	fixed set of ten, so x5 per zone is safe.

	SECTIONS IS NOT DELETED. Its 138 rows keep their names, layer ranges and
	bands, which is what the depth UI, the desks and the plaza signs read. The
	bands stay a SIGN CONVENTION -- what the marker at the zone mouth quotes --
	and stop being the mechanic. Only `dirtHp` moved.
]]
MineDepth.HP_BASE = 20
MineDepth.HP_PER_LAYER = 1.5

function MineDepth.meadowDirtHp(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	return MineDepth.HP_BASE + MineDepth.HP_PER_LAYER * layer
end

function MineDepth.zoneMult(zoneIndex)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	return MineDepth.ZONE_HP_MULT ^ (zoneIndex - 1)
end

function MineDepth.dirtHp(zoneIndex, layer)
	--[[
		No abbreviation snapping, and no x2.

		The x2 belonged to the old SECTIONS numbers; the linear curve is already
		stated in final units, so doubling it would just be a fifth constant
		doing nothing the other four do not.

		The snap is the more important removal. MineAbbrev.ceil rounds to one
		decimal of the magnitude above 1,000, so HP would sit FLAT for about
		sixty layers and then jump ten percent. Coin value is smooth per layer,
		so a stepped HP makes coins-per-HP sawtooth, and the best place in the
		game becomes the layer just before a step. Smooth per layer is an
		invariant; matching the on-screen label is a nicety, and the label is
		still abbreviated for display -- it just rounds the number rather than
		the number rounding itself to suit the label.
	]]
	local raw = MineDepth.meadowDirtHp(layer) * MineDepth.zoneMult(zoneIndex)
	return math.max(1, math.floor(raw + 0.5))
end

function MineDepth.toolsPerBand(zoneIndex)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	if zoneIndex % 2 == 1 then
		return 2
	end
	return 1
end

function MineDepth.isAirGap(layer)
	layer = math.floor(tonumber(layer) or 0)
	local gap = MineDepth.AIR_GAP or 5
	for _, seam in ipairs(MineDepth.SEAMS) do
		if layer >= (seam - gap + 1) and layer <= seam then
			return true
		end
	end
	return false
end

function MineDepth.seamForLayer(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local best = nil
	for _, seam in ipairs(MineDepth.SEAMS) do
		if layer >= seam then
			best = seam
		end
	end
	return best
end

function MineDepth.equivZoneIndex(zoneIndex, seam)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	seam = tonumber(seam) or 0
	if seam == 500 then
		return zoneIndex + 4
	elseif seam == 1500 then
		return zoneIndex + 6
	end
	return zoneIndex
end

function MineDepth.depthSellMult(zoneIndex, seam)
	-- Surface / missing seam: full payout. Depth desks only take the frac haircut.
	if seam == false or seam == nil or seam == 0 then
		return 1
	end
	local equiv = MineDepth.equivZoneIndex(zoneIndex, seam)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	local steps = math.max(0, equiv - zoneIndex)
	return (MineDepth.ZONE_HP_MULT ^ steps) * (MineDepth.DEPTH_SELL_FRAC or 0.78)
end

function MineDepth.bandUnlockKey(seam)
	seam = tonumber(seam) or 0
	if seam == 500 then
		return "deeprock" -- was mid
	elseif seam == 1000 then
		return "thousand"
	elseif seam == 1500 then
		return "shadowzone" -- was deep / band c
	elseif seam == 2000 then
		return "twothou"
	elseif seam >= 2500 and seam <= 10000 and (seam % 500 == 0) then
		-- Own outpost desk per depth. Shops past 2500 show no tools.
		-- Upper bound follows the last entry in SEAMS. Old profiles may still
		-- carry outpost_3500 / outpost_4500 keys from when the ladder ran every
		-- 500 the whole way; those simply go unread rather than breaking.
		return "outpost_" .. tostring(seam)
	end
	return nil
end

-- Prestige needed for this seam's sell pad, shop, mineshaft, or digging past it.
-- zoneIndex is 1-based (Dirt Meadow = 1).
function MineDepth.rebirthForSeam(seam, zoneIndex)
	-- Rebirth is not a dig cap. Depth shops open when you reach them.
	-- Planet gem prices stay on the zone itself.
	return 0
end

function MineDepth.rebirthForLayer(layer, zoneIndex)
	return 0
end

-- ---------------------------------------------------------------------------
-- Coin-priced depth gates (SEAMS). Depth is bought, not rebirthed for.
-- ---------------------------------------------------------------------------

-- Coin value of one block at (zone, layer), zone term included.
function MineDepth.gateCoinValue(zoneIndex, layer)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local zone = MineDepth.GATE_COIN_ZONE ^ (zoneIndex - 1)
	return zone * (1 + MineDepth.GATE_COIN_DEPTH * layer) ^ MineDepth.GATE_COIN_POW
end

-- The band a seam gates: from the previous seam up to seam-1. This is the stretch
-- the player is already allowed to mine, so its income is what they can actually
-- earn while saving for the next seam -- which is what makes 30 minutes honest.
function MineDepth.gateBand(seam)
	seam = math.floor(tonumber(seam) or 0)
	local lo = 1
	for _, s in ipairs(MineDepth.SEAMS) do
		if s == seam then
			return lo, seam - 1
		end
		lo = s
	end
	return nil
end

-- SEAM_MINUTES of the band's average income. Minutes stored, coins derived.
function MineDepth.seamPrice(seam, zoneIndex)
	local lo, hi = MineDepth.gateBand(seam)
	if not lo then
		return nil
	end
	--[[
		SEAMS ARE FREE. Owner, 2026-10-05: "buy seams shouldnt cost anything".

		They used to cost SEAM_MINUTES of the band's income, priced off
		gateCoinValue. Two things were wrong with that and the owner's call
		settles both:

		  * Depth is ALREADY gated, by breaking power. MineBreaking refuses any
		    block whose strength beats your tool, one rung per 50 layers. A coin
		    price on top was a second gate on the same axis -- pay AND be strong
		    enough -- and the coin half is the one that just makes you wait.
		  * The price was computed on gateCoinValue while digging pays one coin
		    per point of dirtHp, a different curve. Seam 500 was priced as 30
		    minutes and cost 2.4 hours; seam 5000 cost 31.5. Nobody was getting
		    the 30 minutes the constant promised.

		Zero, not "removed": every caller already handles a number, the client
		panel is still the moment you break through, and the ORDER check in
		Verbs.buySeam still makes you open seams one at a time. What is gone is
		the bill.

		SEAM_MINUTES and GATE_BLOCKS_PER_HOUR are left alone -- gateCoinValue
		still has other readers, and deleting a constant this one no longer uses
		is a separate change.
	]]
	return 0
end

-- The deepest gate a layer sits at or below, or nil if it is above the first one.
function MineDepth.gateForLayer(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local need = nil
	for _, s in ipairs(MineDepth.SEAMS) do
		if layer >= s then
			need = s
		end
	end
	return need
end

local function seamKey(zoneIndex, seam)
	return tostring(zoneIndex) .. ":" .. tostring(seam)
end
MineDepth.gateSeamKey = seamKey

function MineDepth.ownsSeam(p, seam, zoneIndex)
	if type(p) ~= "table" or not seam then
		return false
	end
	return (p.seams or {})[seamKey(zoneIndex or 1, seam)] == true
end

function MineDepth.grantSeam(p, seam, zoneIndex)
	if type(p) ~= "table" or not seam then
		return false
	end
	p.seams = p.seams or {}
	p.seams[seamKey(zoneIndex or 1, seam)] = true
	return true
end

-- Grandfather: a player keeps every gate at or below the depth they already
-- reached. p.deepest has been tracked all along (MineDigAuth.creditDeepest), so
-- this needs no migration flag -- it is derived from data already on the profile.
--
-- Add-only and therefore idempotent: creditDeepest keeps pushing deepest down as
-- they mine, and re-running must never take a seam away. Must run on load BEFORE
-- the first gate check, or a returning player eats a refusal on their first swing.
function MineDepth.grantReachedSeams(p)
	if type(p) ~= "table" then
		return 0
	end
	p.seams = p.seams or {}
	local granted = 0
	for zoneId, reached in pairs(p.deepest or {}) do
		local zi = 1
		local okZone, C = pcall(function()
			return require(script.Parent:WaitForChild("MineConfig"))
		end)
		if okZone and C and C.zoneIndex then
			zi = C.zoneIndex(tostring(zoneId)) or 1
		end
		local deepest = math.floor(tonumber(reached) or 0)
		for _, s in ipairs(MineDepth.SEAMS) do
			if deepest >= s and not MineDepth.ownsSeam(p, s, zi) then
				MineDepth.grantSeam(p, s, zi)
				granted += 1
			end
		end
	end
	return granted
end

function MineDepth.meetsRebirth(p, need)
	need = math.max(0, math.floor(tonumber(need) or 0))
	if need <= 0 then
		return true
	end
	return (tonumber(p and p.prestige) or 0) >= need
end

function MineDepth.rebirthToast(need, zoneIndex, seam)
	need = math.max(1, math.floor(tonumber(need) or 1))
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	seam = tonumber(seam) or 0
	local letter = (seam >= 1500 or need >= ((MineDepth.REBIRTH_BAND_C_BASE or 60) + (MineDepth.REBIRTH_PER_ZONE_B or 10))) and "C" or "B"
	local band = letter == "C" and "Shadowzone" or "Deeprock"
	return string.format("Rebirth %d to unlock %d%s (%s)", need, zoneIndex, letter, band)
end

MineDepth.BAND_LOOT = {
	shallow = { foreverTool = true, persistBag = false, reliq = false, temper = false, tinySack = true },
	mid = { foreverTool = true, persistBag = true, reliq = false, temper = true, tinySack = false },
	deep = { foreverTool = true, persistBag = true, reliq = true, temper = true, tinySack = false },
}

return MineDepth
