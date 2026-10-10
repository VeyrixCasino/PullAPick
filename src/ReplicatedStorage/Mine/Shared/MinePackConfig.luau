-- MinePackConfig: every chest, its loot, and the odds it rolls on.
--
-- Design rules this file encodes, so nobody has to rediscover them:
--
--  1. NO PITY, NO GUARANTEES. Every roll is independent. The top end is rare
--     because it is rare, not because a counter is holding it back.
--  2. Packs are NOT purchasable with coins or gems. Coins and gems buy POWER
--     (pickaxes, bags, slots, zone unlocks). Cards come out of chests, and
--     dupes recycle into stardust to buy the one card you are missing. This
--     firewall stops mine -> coins -> packs -> better pets -> mine faster from
--     compounding.
--  3. THE CHEST IS THE IDENTITY. There is no ladder of generic packs. A chest
--     carries its own rarity curve, its own variant curve, its own card count
--     and its own spawn location. Opening a Void Chest is a different activity
--     from opening an Apex Capsule, not a bigger version of it.
--  4. Over-levelled players get fewer chests in shallow zones (RELEVANCE), so a
--     maxed player cannot farm Zone 1. No daily caps anywhere.
--
-- Every card a chest yields rolls that chest's own `odds`. There is no
-- filler/hit split: a chest's curve already says what shape it is, and the
-- drama comes from WHICH CHEST YOU FOUND.
local MinePackConfig = {}

MinePackConfig.TIERS = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic" }

MinePackConfig.TIER_COLOR = {
	Common = Color3.fromRGB(170, 170, 170),
	Uncommon = Color3.fromRGB(85, 255, 127),
	Rare = Color3.fromRGB(85, 170, 255),
	Epic = Color3.fromRGB(170, 85, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(85, 220, 255),
	Divine = Color3.fromRGB(255, 245, 160),
	Exotic = Color3.fromRGB(255, 55, 55),
}

-- A card's shiny chance: a pack's own `shiny` %, or this. Variant odds are
-- MinePackConfig.variantOdds, never a pack row.
MinePackConfig.SHINY_CHANCE = 4.00

-- Power multipliers, matching MineConfig.VARIANT_MULT. Shiny stacks on a base.
MinePackConfig.VARIANT_MULT = {
	Normal = 1.0, Shiny = 1.5, Golden = 2.25, Prism = 3.5, Rainbow = 5.5, Void = 4.0,
}

-- A card type's colour (MineCards and the client read it).
MinePackConfig.TYPE_COLOR = {
	Fire = Color3.fromRGB(244, 108, 48),
	Frost = Color3.fromRGB(168, 224, 248),
	Water = Color3.fromRGB(70, 150, 250),
	Grass = Color3.fromRGB(96, 190, 104),
	Ground = Color3.fromRGB(168, 128, 84),
	Metal = Color3.fromRGB(176, 186, 200),
	Electric = Color3.fromRGB(250, 216, 72),
	Crystal = Color3.fromRGB(214, 128, 246),
	Shadow = Color3.fromRGB(110, 84, 150),
	Space = Color3.fromRGB(130, 110, 235),
}

--------------------------------------------------------------------------------
-- CHESTS
--
-- A chest is not a rung on a ladder, it is a LENS. Each one skews the outcome
-- on a different axis, so choosing which chest to farm is a real decision:
--
--   native    the baseline for its zone
--   variant   trades top RARITY for top VARIANT (Void Chest: Void 0.3% -> 12.5%,
--             but Exotic drops to 0.01%). Chase a finish, not a card.
--   shape     same cards, very different curve -- volume, mid-heavy, or one
--             single excellent card
--   set       leans hard toward Set X or Set Y
--   risk      deep-only, often empty, big when it lands
--   currency  no cards at all, pure gems or stardust
--
-- `spawn.zone = 0` means any zone -- those are gated purely by layer depth.
-- `spawn.weight` is relative within a (zone, layer) band; natives sit at 100,
-- so a weight of 9 is roughly a 1-in-12 find where it can appear at all.
-- That is the grind: go to a specific zone, at a specific depth, for a
-- specific chest.
--
-- Every odds and variant row below is generated normalised and sums to 100.
--------------------------------------------------------------------------------

MinePackConfig.CHESTS = {
	{
		id = "sunken_cache", name = "Sunken Cache", kind = "native",
		flavour = "Waterlogged and half-buried. The first thing anyone digs up.",
		spawn = { zone = 1, layers = { 1, 50 }, weight = 100, luckScale = 0 },
		packChance = 35, cards = 3,
		odds = { Common = 34.000, Uncommon = 31.000, Rare = 20.000, Epic = 10.000, Legendary = 4.000, Mythic = 0.850, Divine = 0.130, Exotic = 0.020 },
		shiny = 4.0,
		loot = {
			{ kind = "coins", weight = 34, min = 60, max = 140 },
			{ kind = "gems", weight = 22, min = 2, max = 6 },
			{ kind = "stardust", weight = 24, min = 15, max = 40 },
			{ kind = "oreCache", weight = 16, min = 6, max = 14, ore = "coal" },
			{ kind = "powerCharge", weight = 4, min = 1, max = 1 },
		},
	},
	{
		id = "kiln_crate", name = "Kiln Crate", kind = "native",
		flavour = "Fire-hardened clay. Cracks open warm.",
		spawn = { zone = 2, layers = { 1, 50 }, weight = 100, luckScale = 0 },
		packChance = 39, cards = 3,
		odds = { Common = 30.866, Uncommon = 30.866, Rare = 20.909, Epic = 11.450, Legendary = 4.580, Mythic = 1.095, Divine = 0.199, Exotic = 0.035 },
		shiny = 4.0,
		loot = {
			{ kind = "coins", weight = 32, min = 140, max = 320 },
			{ kind = "gems", weight = 23, min = 5, max = 14 },
			{ kind = "stardust", weight = 24, min = 35, max = 85 },
			{ kind = "oreCache", weight = 16, min = 8, max = 18, ore = "copper" },
			{ kind = "powerCharge", weight = 5, min = 1, max = 2 },
		},
	},
	{
		id = "tidelocked_coffer", name = "Tidelocked Coffer", kind = "native",
		flavour = "Sealed by pressure. Hisses when the lid gives.",
		spawn = { zone = 3, layers = { 1, 50 }, weight = 100, luckScale = 0 },
		packChance = 43, cards = 3,
		odds = { Common = 27.957, Uncommon = 29.954, Rare = 21.966, Epic = 12.980, Legendary = 5.392, Mythic = 1.398, Divine = 0.300, Exotic = 0.055 },
		shiny = 4.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "live_wire_box", name = "Live Wire Box", kind = "native",
		flavour = "Still humming. Mind the contacts.",
		spawn = { zone = 4, layers = { 1, 50 }, weight = 100, luckScale = 0 },
		packChance = 47, cards = 3,
		odds = { Common = 24.944, Uncommon = 28.935, Rare = 22.948, Epic = 14.467, Legendary = 6.386, Mythic = 1.796, Divine = 0.439, Exotic = 0.085 },
		shiny = 4.0,
		loot = {
			{ kind = "coins", weight = 28, min = 700, max = 1500 },
			{ kind = "gems", weight = 25, min = 26, max = 62 },
			{ kind = "stardust", weight = 24, min = 170, max = 380 },
			{ kind = "oreCache", weight = 16, min = 6, max = 16, ore = "gold" },
			{ kind = "powerCharge", weight = 7, min = 1, max = 3 },
		},
	},
	{
		id = "carrion_reliquary", name = "Carrion Reliquary", kind = "native",
		flavour = "Someone left an offering. It has been a while.",
		spawn = { zone = 5, layers = { 1, 50 }, weight = 100, luckScale = 0 },
		packChance = 51, cards = 3,
		odds = { Common = 22.049, Uncommon = 27.060, Rare = 24.053, Epic = 16.035, Legendary = 7.617, Mythic = 2.405, Divine = 0.651, Exotic = 0.130 },
		shiny = 4.0,
		loot = {
			{ kind = "coins", weight = 26, min = 1500, max = 3200 },
			{ kind = "gems", weight = 26, min = 55, max = 130 },
			{ kind = "stardust", weight = 24, min = 360, max = 800 },
			{ kind = "oreCache", weight = 16, min = 12, max = 30, ore = "gold" },
			{ kind = "powerCharge", weight = 8, min = 2, max = 4 },
		},
	},
	{
		id = "eclipse_vault", name = "Eclipse Vault", kind = "native",
		flavour = "Cold to the touch, even down here.",
		spawn = { zone = 6, layers = { 1, 50 }, weight = 100, luckScale = 0 },
		packChance = 55, cards = 3,
		odds = { Common = 18.016, Uncommon = 25.023, Rare = 25.023, Epic = 18.016, Legendary = 9.408, Mythic = 3.303, Divine = 1.001, Exotic = 0.210 },
		shiny = 4.0,
		loot = {
			{ kind = "coins", weight = 24, min = 3200, max = 7000 },
			{ kind = "gems", weight = 27, min = 120, max = 280 },
			{ kind = "stardust", weight = 24, min = 750, max = 1700 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "crystal" },
			{ kind = "powerCharge", weight = 9, min = 2, max = 5 },
		},
	},
	{
		id = "void_chest", name = "Void Chest", kind = "variant",
		flavour = "Void variants pour out of it. The rarest cards will not.",
		spawn = { zone = 0, layers = { 40, 50 }, weight = 9, favZone = 6, favMult = 4, luckScale = 1.2 },
		packChance = 70, cards = 3,
		odds = { Common = 16.000, Uncommon = 24.000, Rare = 26.000, Epic = 22.000, Legendary = 11.200, Mythic = 0.700, Divine = 0.090, Exotic = 0.010 },
		shiny = 5.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "gilded_strongbox", name = "Gilded Strongbox", kind = "variant",
		flavour = "Everything inside has been dipped. Not everything inside is good.",
		spawn = { zone = 0, layers = { 18, 38 }, weight = 14, favZone = 4, favMult = 3, luckScale = 1.2 },
		packChance = 66, cards = 3,
		odds = { Common = 22.000, Uncommon = 28.000, Rare = 25.000, Epic = 16.000, Legendary = 8.000, Mythic = 0.850, Divine = 0.140, Exotic = 0.010 },
		shiny = 6.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "prism_geode", name = "Prism Geode", kind = "variant",
		flavour = "Splits along a facet. Throws colour everywhere.",
		spawn = { zone = 0, layers = { 24, 44 }, weight = 12, favZone = 3, favMult = 3, luckScale = 1.2 },
		packChance = 64, cards = 3,
		odds = { Common = 24.000, Uncommon = 29.000, Rare = 25.000, Epic = 15.000, Legendary = 6.400, Mythic = 0.500, Divine = 0.090, Exotic = 0.010 },
		shiny = 6.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "chroma_drum", name = "Chroma Drum", kind = "variant",
		flavour = "Rainbow prints, and not much else worth having.",
		spawn = { zone = 0, layers = { 34, 50 }, weight = 5, favZone = 5, favMult = 4, luckScale = 1.2 },
		packChance = 68, cards = 3,
		odds = { Common = 20.000, Uncommon = 27.000, Rare = 26.000, Epic = 19.000, Legendary = 7.200, Mythic = 0.600, Divine = 0.190, Exotic = 0.010 },
		shiny = 7.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "mirrorpolish_case", name = "Mirrorpolish Case", kind = "variant",
		flavour = "Buffed to a shine. Nearly everything comes out Shiny.",
		spawn = { zone = 0, layers = { 12, 30 }, weight = 16, favZone = 2, favMult = 3, luckScale = 1.2 },
		packChance = 60, cards = 3,
		odds = { Common = 28.000, Uncommon = 31.000, Rare = 23.000, Epic = 13.000, Legendary = 4.400, Mythic = 0.500, Divine = 0.090, Exotic = 0.010 },
		shiny = 38.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "broadseam_hopper", name = "Broadseam Hopper", kind = "shape",
		flavour = "Six cards, almost all of them junk. Fills a binder fast.",
		spawn = { zone = 0, layers = { 1, 14 }, weight = 40, favZone = 1, favMult = 3, luckScale = 0.8 },
		packChance = 58, cards = 6,
		odds = { Common = 52.000, Uncommon = 34.000, Rare = 11.000, Epic = 2.600, Legendary = 0.350, Mythic = 0.040, Divine = 0.005, Exotic = 0.005 },
		shiny = 3.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "magpie_nest", name = "Magpie Nest", kind = "shape",
		flavour = "Eight cards. It took whatever was shiny, not whatever was good.",
		spawn = { zone = 0, layers = { 1, 18 }, weight = 26, favZone = 2, favMult = 3, luckScale = 0.8 },
		packChance = 62, cards = 8,
		odds = { Common = 60.000, Uncommon = 31.000, Rare = 8.000, Epic = 0.900, Legendary = 0.090, Mythic = 0.009, Divine = 0.001, Exotic = 0.000 },
		shiny = 3.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "keystone_coffer", name = "Keystone Coffer", kind = "shape",
		flavour = "No filler. Nothing spectacular either — just solid, every time.",
		spawn = { zone = 0, layers = { 20, 40 }, weight = 18, favZone = 4, favMult = 3, luckScale = 0.8 },
		packChance = 60, cards = 3,
		odds = { Common = 2.000, Uncommon = 12.000, Rare = 32.000, Epic = 34.000, Legendary = 17.000, Mythic = 2.400, Divine = 0.550, Exotic = 0.050 },
		shiny = 4.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "apex_capsule", name = "Apex Capsule", kind = "shape",
		flavour = "One card. It is worth opening.",
		spawn = { zone = 0, layers = { 42, 50 }, weight = 7, favZone = 6, favMult = 3, luckScale = 0.8 },
		packChance = 78, cards = 1,
		odds = { Common = 0.000, Uncommon = 4.000, Rare = 16.000, Epic = 30.000, Legendary = 32.000, Mythic = 13.000, Divine = 4.200, Exotic = 0.800 },
		shiny = 6.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "hollowpoint_case", name = "Hollowpoint Case", kind = "shape",
		flavour = "Almost always nothing. Twenty times the Exotic rate when it is not.",
		spawn = { zone = 0, layers = { 30, 50 }, weight = 8, favZone = 5, favMult = 3, luckScale = 0.8 },
		packChance = 56, cards = 2,
		odds = { Common = 58.000, Uncommon = 24.000, Rare = 10.000, Epic = 4.000, Legendary = 2.400, Mythic = 0.800, Divine = 0.400, Exotic = 0.400 },
		shiny = 4.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		-- id kept: saves carry it as a packId. Only the label changed, because
		-- nothing in the game is a fossil any more (§0.12).
		id = "fossil_bed", name = "Pressed Bed", kind = "shape",
		flavour = "Pressed flat between the strata. No commons survive down here.",
		spawn = { zone = 0, layers = { 30, 46 }, weight = 15, favZone = 3, favMult = 3, luckScale = 0.8 },
		packChance = 57, cards = 3,
		odds = { Common = 0.000, Uncommon = 22.000, Rare = 40.000, Epic = 26.000, Legendary = 10.000, Mythic = 1.600, Divine = 0.350, Exotic = 0.050 },
		shiny = 4.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "umbral_ledger", name = "Umbral Ledger", kind = "set",
		flavour = "Pages of nothing but the dark half of the season.",
		spawn = { zone = 5, layers = { 26, 50 }, weight = 13, luckScale = 1 },
		packChance = 54, cards = 3,
		odds = { Common = 22.049, Uncommon = 27.060, Rare = 24.053, Epic = 16.035, Legendary = 7.617, Mythic = 2.405, Divine = 0.651, Exotic = 0.130 },
		shiny = 4.0,
		loot = {
			{ kind = "coins", weight = 26, min = 1500, max = 3200 },
			{ kind = "gems", weight = 26, min = 55, max = 130 },
			{ kind = "stardust", weight = 24, min = 360, max = 800 },
			{ kind = "oreCache", weight = 16, min = 12, max = 30, ore = "gold" },
			{ kind = "powerCharge", weight = 8, min = 2, max = 4 },
		},
	},
	{
		id = "sunlit_ledger", name = "Sunlit Ledger", kind = "set",
		flavour = "The bright half, and it will not shut up about it.",
		spawn = { zone = 2, layers = { 4, 22 }, weight = 13, luckScale = 1 },
		packChance = 54, cards = 3,
		odds = { Common = 27.957, Uncommon = 29.954, Rare = 21.966, Epic = 12.980, Legendary = 5.392, Mythic = 1.398, Divine = 0.300, Exotic = 0.055 },
		shiny = 8.0,
		loot = {
			{ kind = "coins", weight = 32, min = 140, max = 320 },
			{ kind = "gems", weight = 23, min = 5, max = 14 },
			{ kind = "stardust", weight = 24, min = 35, max = 85 },
			{ kind = "oreCache", weight = 16, min = 8, max = 18, ore = "copper" },
			{ kind = "powerCharge", weight = 5, min = 1, max = 2 },
		},
	},
	{
		id = "pressure_seal", name = "Pressure Seal", kind = "risk",
		flavour = "Only forms at crushing depth. Any zone, if you go far enough down.",
		spawn = { zone = 0, layers = { 44, 50 }, weight = 20, luckScale = 1.5 },
		packChance = 64, cards = 3,
		odds = { Common = 14.000, Uncommon = 22.000, Rare = 26.000, Epic = 21.000, Legendary = 13.400, Mythic = 2.900, Divine = 0.620, Exotic = 0.080 },
		shiny = 5.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "faultline_drop", name = "Faultline Drop", kind = "risk",
		flavour = "Bedrock only. Rare, and worth the walk down.",
		spawn = { zone = 0, layers = { 49, 50 }, weight = 4, luckScale = 1.5 },
		packChance = 82, cards = 4,
		odds = { Common = 8.000, Uncommon = 18.000, Rare = 25.000, Epic = 24.000, Legendary = 18.000, Mythic = 5.400, Divine = 1.400, Exotic = 0.200 },
		shiny = 7.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "deadfall_crate", name = "Deadfall Crate", kind = "risk",
		flavour = "More than half of them are empty. The rest are excellent.",
		spawn = { zone = 0, layers = { 28, 48 }, weight = 11, favZone = 4, favMult = 3, luckScale = 1.5 },
		packChance = 42, cards = 4,
		odds = { Common = 10.000, Uncommon = 20.000, Rare = 26.000, Epic = 24.000, Legendary = 15.400, Mythic = 3.600, Divine = 0.900, Exotic = 0.100 },
		shiny = 5.0,
		loot = {
			{ kind = "coins", weight = 30, min = 320, max = 700 },
			{ kind = "gems", weight = 24, min = 12, max = 30 },
			{ kind = "stardust", weight = 24, min = 80, max = 180 },
			{ kind = "oreCache", weight = 16, min = 8, max = 20, ore = "iron" },
			{ kind = "powerCharge", weight = 6, min = 1, max = 2 },
		},
	},
	{
		id = "quartz_piggybank", name = "Quartz Piggybank", kind = "currency",
		flavour = "No cards. A frankly rude amount of gems.",
		spawn = { zone = 0, layers = { 8, 34 }, weight = 22, favZone = 3, favMult = 3, luckScale = 0.6 },
		packChance = 0, cards = 0,
		loot = {
			{ kind = "gems", weight = 78, min = 240, max = 900 },
			{ kind = "coins", weight = 18, min = 900, max = 2600 },
			{ kind = "powerCharge", weight = 4, min = 1, max = 3 },
		},
	},
	{
		id = "tithe_urn", name = "Tithe Urn", kind = "currency",
		flavour = "No cards. Enough stardust to buy the one you actually wanted.",
		spawn = { zone = 0, layers = { 16, 50 }, weight = 17, favZone = 5, favMult = 3, luckScale = 0.6 },
		packChance = 0, cards = 0,
		loot = {
			{ kind = "stardust", weight = 80, min = 900, max = 3400 },
			{ kind = "gems", weight = 15, min = 40, max = 140 },
			{ kind = "powerCharge", weight = 5, min = 1, max = 3 },
		},
	},
}

--------------------------------------------------------------------------------
-- CHEST FREQUENCY
--
-- Chests spawn per block broken, NOT on a timer and NOT on a daily quota --
-- there are no hard caps anywhere in this design. What stops a maxed player
-- farming Zone 1 is RELEVANCE: chest rate decays the further a player is above
-- the zone they are standing in.
--
--   rate = 1 / BLOCKS_PER_CHEST * RELEVANCE_DECAY ^ (highestZoneUnlocked - zoneTier)
--
-- SWING_SEC already caps Zone 1 throughput at ~2.4 blocks/sec, so a maxed
-- player is only ~4x faster there than a new one. A decay of 0.7^5 = 0.17
-- more than cancels that: farming Zone 1 at max level is strictly worse than
-- playing the zone you belong in.
--
-- IMPORTANT: base the exponent on HIGHEST ZONE EVER UNLOCKED, not on current
-- prestige. Using current prestige lets a player rebirth to reset the decay and
-- farm Zone 1 at full rate again.
--------------------------------------------------------------------------------

MinePackConfig.BLOCKS_PER_CHEST = 400
MinePackConfig.RELEVANCE_DECAY = 0.70

MinePackConfig.RELEVANCE_TABLE = {
	[0] = 1.000, [1] = 0.700, [2] = 0.490, [3] = 0.343, [4] = 0.240, [5] = 0.168,
}

function MinePackConfig.relevance(highestZoneUnlocked, zoneTier)
	local over = math.max(0, (highestZoneUnlocked or 1) - (zoneTier or 1))
	return MinePackConfig.RELEVANCE_TABLE[math.min(over, 5)] or MinePackConfig.RELEVANCE_DECAY ^ over
end

--------------------------------------------------------------------------------
-- ORE YIELD
--
-- Every ore now pays gems as well as coins. Coins buy power; gems buy zone
-- unlocks, which persist through rebirth. Neither buys packs.
-- `sell` mirrors MineConfig.BLOCKS so the two cannot drift apart unnoticed.
--------------------------------------------------------------------------------

MinePackConfig.ORE_YIELD = {
	dirt = { sell = 0, coins = 1, gems = 0 },
	coal = { sell = 6, coins = 6, gems = 1 },
	copper = { sell = 10, coins = 10, gems = 2 },
	iron = { sell = 18, coins = 18, gems = 5 },
	gold = { sell = 40, coins = 40, gems = 12 },
	crystal = { sell = 90, coins = 90, gems = 30 },
}

--------------------------------------------------------------------------------
-- STARDUST
--
-- Recycling dupes into stardust, and stardust into a SPECIFIC card. This is the
-- anti-frustration valve: the last card of a set becomes a grind you control.
--
-- Safety constraint: if each pack returns R packs' worth of stardust, one pack
-- eventually yields 1/(1-R) packs. Keep R under ~0.30 or packs self-replicate.
-- At ~1.2 dupes/pack averaging ~14 stardust, and a Salvage Pack at 250, R is
-- about 0.07. Comfortable. Recheck this if either side is retuned.
--------------------------------------------------------------------------------

MinePackConfig.RECYCLE_STARDUST = {
	-- Lockstep with MineConfig.RARITY_DUST: junk scrap is low, chase scrap is high.
	Common = 6, Uncommon = 12, Rare = 28, Epic = 90,
	Legendary = 1600, Mythic = 4000, Divine = 11200, Exotic = 32000,
}

-- Reference tier values only. Individual cards are NOT sold — shop sells packs.
MinePackConfig.CARD_STARDUST_COST = {
	Common = 60, Uncommon = 140, Rare = 320, Epic = 800,
	Legendary = 2000, Mythic = 5000, Divine = 14000, Exotic = 40000,
}

-- Unopened pack scrap RTP vs expected open-and-scrap EV.
-- Soft packs sit near 50%; chase packs climb toward 70%.
MinePackConfig.SCRAP_RTP_MIN = 0.5
MinePackConfig.SCRAP_RTP_MAX = 0.7

-- Recycling a variant pays its power multiplier back in stardust.
function MinePackConfig.recycleValue(tier, variant, shiny)
	local base = MinePackConfig.RECYCLE_STARDUST[tier] or 6
	local mult = MinePackConfig.VARIANT_MULT[variant or "Normal"] or 1
	if shiny then
		mult *= MinePackConfig.VARIANT_MULT.Shiny
	end
	return math.floor(base * mult)
end

function MinePackConfig.expectedVariantMult(variants)
	variants = variants or MinePackConfig.variantOdds()
	local total = 0
	for _, w in pairs(variants) do
		total += w
	end
	if total <= 0 then
		return 1
	end
	local ev = 0
	for id, w in pairs(variants) do
		ev += (w / total) * (MinePackConfig.VARIANT_MULT[id] or 1)
	end
	return ev
end

--[[
	VARIANT RATES ARE DECIDED HERE, NOT IN THE PACK TABLES.

	Every pack in MinePackConfig and Mine1PacksData used to carry its own
	variants row (removed 2026-10-10), and they disagreed wildly -- base packs paid 12% specials, one card in eight.
	Set against what a variant is actually WORTH that was absurd: merging up to a
	Void pet costs 81 normal pets, and a Void falling one card in 333 was nowhere
	near 81x as hard to come by as a normal one.

	So the pack rows no longer decide. This does, in absolute percentages:

	  every pack         Golden 1%, and nothing else. Prism, Rainbow and Void do
	                     not drop from ordinary packs at all any more.
	  a variant product  only the variant it is named for, at its own rate.

	Normal absorbs whatever is left over, so every table still sums to exactly
	what it summed to before and no caller has to renormalise. Rates read as
	percentages of a 100-point row, scaled if a row does not total 100.
]]
MinePackConfig.VARIANT_BASE = { Golden = 1, Prism = 0, Rainbow = 0, Void = 0 }

-- The variant products. Each names its own variant and its own rate; anything
-- not listed here gets VARIANT_BASE. To make a pack a variant product, add it.
MinePackConfig.VARIANT_HEADLINE = {
	gilded_strongbox = { Golden = 100 },
	prism_geode = { Prism = 8 },
	chroma_drum = { Rainbow = 3 },
	void_chest = { Void = 2 },
	void_pack = { Void = 2 },
}

-- Percent per variant for a pack, summing to 100. The first argument is a
-- pack's old variants row; it is ignored (kept so old callers still work).
function MinePackConfig.variantOdds(_variants, packId)
	local rates = (packId and MinePackConfig.VARIANT_HEADLINE[packId]) or MinePackConfig.VARIANT_BASE
	local out, spent = {}, 0
	for id in pairs(MinePackConfig.VARIANT_BASE) do
		local v = math.max(0, tonumber(rates[id]) or 0)
		out[id] = v
		spent += v
	end
	out.Normal = math.max(0, 100 - spent)
	return out
end

-- Expected stardust if you open the pack and scrap every card (power 1).
function MinePackConfig.expectedOpenScrap(packDef)
	if type(packDef) ~= "table" or type(packDef.odds) ~= "table" then
		return 0
	end
	local cards = tonumber(packDef.cards) or 0
	if cards <= 0 then
		return 0
	end
	local total, dustEv = 0, 0
	for _, w in pairs(packDef.odds) do
		total += w
	end
	if total <= 0 then
		return 0
	end
	for rarity, w in pairs(packDef.odds) do
		dustEv += (w / total) * (MinePackConfig.RECYCLE_STARDUST[rarity] or 6)
	end
	local varEv = MinePackConfig.expectedVariantMult(MinePackConfig.variantOdds(packDef.variants, packDef.id))
	local shinyPct = tonumber(packDef.shiny) or MinePackConfig.SHINY_CHANCE or 0
	local shinyEv = 1 + (shinyPct / 100) * ((MinePackConfig.VARIANT_MULT.Shiny or 1.5) - 1)
	return cards * dustEv * varEv * shinyEv
end

-- Unopened pack scrap payout (~50–70% of expected open-and-scrap EV).
-- Pack scrap RTP: 50% on soft packs → 70% on chase packs. Each pack's EV differs,
-- so scrap payouts stay distinct.
function MinePackConfig.packScrapRtp(packDef)
	local lo = MinePackConfig.SCRAP_RTP_MIN or 0.5
	local hi = MinePackConfig.SCRAP_RTP_MAX or 0.7
	if type(packDef) ~= "table" then
		return lo
	end
	local price = MinePackConfig.PACK_PRICE[packDef.id or ""]
	if type(price) == "number" then
		-- hopper 35 → 50%, apex 220 → 80%
		local t = math.clamp((price - 35) / (220 - 35), 0, 1)
		return lo + (hi - lo) * t
	end
	-- Zone packs: later zones + hotter slots scrap better.
	local z = math.max(1, tonumber(packDef.zoneIndex) or 1)
	local heat = (packDef.slot == "pack_legendary" and 2)
		or (packDef.slot == "pack_rare" and 1)
		or 0
	local t = math.clamp(((z - 1) / 9) * 0.7 + (heat / 2) * 0.3, 0, 1)
	return lo + (hi - lo) * t
end

-- Unopened pack scrap payout (50–80% of expected open-and-scrap EV).
function MinePackConfig.packScrapDust(packIdOrDef)
	local def = packIdOrDef
	if type(def) == "string" then
		def = MinePackConfig.PACK_BY_ID[def]
		if not def then
			local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Mine")
				and game:GetService("ReplicatedStorage").Mine:FindFirstChild("Shared")
			local zpMod = shared and shared:FindFirstChild("MineZonePacks")
			if zpMod then
				local ok, ZP = pcall(require, zpMod)
				if ok and ZP and ZP.get then
					def = ZP.get(packIdOrDef)
				end
			end
		end
	end
	if type(def) ~= "table" then
		return 0
	end
	local kind = def.kind or "card"
	if kind ~= "card" and kind ~= "cards" then
		return tonumber(def.scrapDust) or 0
	end
	local ev = MinePackConfig.expectedOpenScrap(def)
	if ev <= 0 then
		return 0
	end
	local rtp = MinePackConfig.packScrapRtp(def)
	return math.max(1, math.floor(ev * rtp + 0.5))
end

--------------------------------------------------------------------------------
-- ZONES
--
-- The six live zones, then the specialty zones to come. Specialty zones are
-- gem-gated rather than prestige-gated, and STAY UNLOCKED THROUGH REBIRTH --
-- that is the point of them, a permanent reward for a huge gem spend.
--
-- `mods` multiply the named quantity while the player is in that zone.
--------------------------------------------------------------------------------

MinePackConfig.ZONES = {
	{ id = "meadow", name = "Dirt Meadow", tier = 1, unlockPrestige = 0, unlockGems = 0, permanent = false, mods = {} },
	{ id = "sunscar", name = "Sunscar Quarry", tier = 2, unlockPrestige = 1, unlockGems = 0, permanent = false, mods = {} },
	{ id = "mistreef", name = "Mistreef Depths", tier = 3, unlockPrestige = 2, unlockGems = 0, permanent = false, mods = {} },
	{ id = "arcwork", name = "Arcwork Veins", tier = 4, unlockPrestige = 3, unlockGems = 0, permanent = false, mods = {} },
	{ id = "bloodmoon", name = "Bloodmoon Hollow", tier = 5, unlockPrestige = 4, unlockGems = 0, permanent = false, mods = {} },
	{ id = "eclipse", name = "Eclipse Core", tier = 6, unlockPrestige = 5, unlockGems = 0, permanent = false, mods = {} },

	-- Specialty zones. Planned, not live. Each does ONE thing much better than
	-- the core zones, so the choice of where to mine stays interesting at cap.
	{
		id = "gemvault", name = "The Gem Vault", tier = 5, unlockPrestige = 3, unlockGems = 2500000,
		permanent = true, planned = true,
		mods = { gems = 4.0, coins = 0.5, chestRate = 0.7 },
		note = "Gem farm. Poor for coins and chests on purpose.",
	},
	{
		id = "warren", name = "Chest Warren", tier = 4, unlockPrestige = 3, unlockGems = 4000000,
		permanent = true, planned = true,
		mods = { chestRate = 2.5, gems = 0.4, coins = 0.6 },
		note = "Pack farm. Uses Zone 4 odds, so volume up, quality flat.",
	},
	{
		id = "fastcut", name = "Fastcut Seam", tier = 5, unlockPrestige = 4, unlockGems = 6000000,
		permanent = true, planned = true,
		mods = { layerSpeed = 3.0, blockHp = 0.4, gems = 0.8, chestRate = 1.2 },
		note = "Layers clear fast. Good for prestige runs.",
	},
	{
		id = "arena", name = "Warden Arena", tier = 6, unlockPrestige = 5, unlockGems = 10000000,
		permanent = true, planned = true,
		mods = { chestRate = 0.3, bossRate = 1.0 },
		note = "Boss fights drop Warden Caches. Ordinary chests are rare here.",
	},
}

-- PET KITS live in MinePetBoosts (one table: MineZonePets.KITS). Mirrored here
-- for the callers that ask MinePackConfig.
do
	local ok, Boosts = pcall(require, script.Parent:FindFirstChild("MinePetBoosts"))
	if ok and type(Boosts) == "table" then
		MinePackConfig.PET_BOOSTS = Boosts.PET_BOOSTS
		MinePackConfig.NAME_ALIASES = Boosts.NAME_ALIASES
		MinePackConfig.resolveName = Boosts.resolveName
		MinePackConfig.boostsFor = Boosts.boostsFor
	end
end

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function rollWeighted(rows, rng, weightKey)
	local total = 0
	for _, row in ipairs(rows) do
		total += (weightKey and row[weightKey] or row.weight) or 0
	end
	if total <= 0 then
		return rows[1]
	end
	local t = (rng and rng:NextNumber() or math.random()) * total
	for _, row in ipairs(rows) do
		t -= (weightKey and row[weightKey] or row.weight) or 0
		if t <= 0 then
			return row
		end
	end
	return rows[#rows]
end

-- The baseline chest for a zone. Use chestsAt / rollChest for actual spawning;
-- this is only for UI that needs a representative chest per zone.
function MinePackConfig.nativeChest(zoneTier)
	for _, chest in ipairs(MinePackConfig.CHESTS) do
		if chest.kind == "native" and chest.spawn.zone == zoneTier then
			return chest
		end
	end
	return MinePackConfig.CHESTS[1]
end

local function fromPercentTable(t)
	local rows = {}
	for k, pct in pairs(t) do
		table.insert(rows, { id = k, weight = pct })
	end
	table.sort(rows, function(a, b)
		return a.id < b.id
	end)
	return rows
end

MinePackConfig.CHEST_BY_ID = {}
for _, chest in ipairs(MinePackConfig.CHESTS) do
	MinePackConfig.CHEST_BY_ID[chest.id] = chest
end

-- Which chests can appear at a given zone and layer. `spawn.zone == 0` means
-- any zone, gated purely by depth.
function MinePackConfig.chestsAt(zoneTier, layer)
	local out = {}
	for _, chest in ipairs(MinePackConfig.CHESTS) do
		local s = chest.spawn
		local zoneOk = s.zone == 0 or s.zone == zoneTier
		local layerOk = layer >= s.layers[1] and layer <= s.layers[2]
		if zoneOk and layerOk then
			table.insert(out, chest)
		end
	end
	return out
end

--[[
	Which chest a broken chest-block turns out to be.

	CALL THIS AT BREAK TIME, not at world generation. The block only knows it is
	"a chest"; which chest it is gets decided when someone breaks it, using THAT
	player's boosts. That is the only way the luck stat can matter -- if the
	variety were baked in at spawn, luck would have nothing to act on, and two
	players breaking the same block would get the same thing.

	`boosts` is the table from MineServer.boosts(profile); only `luck` is read.
	Natives have luckScale 0, so luck never makes the fallback more common --
	it pulls you off the fallback and onto the specials.
]]
function MinePackConfig.rollChest(zoneTier, layer, rng, boosts)
	local candidates = MinePackConfig.chestsAt(zoneTier, layer)
	if #candidates == 0 then
		return MinePackConfig.CHESTS[1]
	end
	local luck = (boosts and boosts.luck) or 1
	local rows = {}
	for _, chest in ipairs(candidates) do
		local w = chest.spawn.weight
		-- Favoured zone: the same chest is several times more likely in its home
		-- zone, which is what makes "go to Arcwork and dig to 30" the right play
		-- without leaving other zones barren.
		if chest.spawn.favZone and chest.spawn.favZone == zoneTier then
			w *= chest.spawn.favMult or 1
		end
		local scale = chest.spawn.luckScale or 0
		if scale > 0 then
			w *= math.max(0, 1 + (luck - 1) * scale)
		end
		table.insert(rows, { chest = chest, weight = w })
	end
	return rollWeighted(rows, rng).chest
end

--------------------------------------------------------------------------------
-- Mine 1 PACKS + CHESTS (depth rebuild). Separate tables; spawn rate is global.
--------------------------------------------------------------------------------
MinePackConfig.PACKS = require(script.Parent:WaitForChild("Mine1PacksData"))
MinePackConfig.PACK_BY_ID = {}
for _, p in ipairs(MinePackConfig.PACKS) do
	MinePackConfig.PACK_BY_ID[p.id] = p
end

MinePackConfig.MINE1_CHESTS = require(script.Parent:WaitForChild("Mine1ChestsData"))
for _, chest in ipairs(MinePackConfig.MINE1_CHESTS) do
	MinePackConfig.CHEST_BY_ID[chest.id] = chest
end

function MinePackConfig.chestsAtMine(mineId, layer)
	local out = {}
	local src = (mineId == 1) and MinePackConfig.MINE1_CHESTS or MinePackConfig.CHESTS
	for _, chest in ipairs(src or {}) do
		local mine = chest.mine or (chest.spawn and chest.spawn.zone) or 0
		local layers = chest.layers or (chest.spawn and chest.spawn.layers)
		if layers and (mine == mineId or mine == 0) and layer >= layers[1] and layer <= layers[2] then
			table.insert(out, chest)
		end
	end
	return out
end

function MinePackConfig.rollChestAt(mineId, layer, rng, luck)
	luck = luck or 1
	local candidates = MinePackConfig.chestsAtMine(mineId, layer)
	if #candidates == 0 then
		return (MinePackConfig.MINE1_CHESTS and MinePackConfig.MINE1_CHESTS[1]) or MinePackConfig.CHESTS[1]
	end
	local rows = {}
	for _, chest in ipairs(candidates) do
		local w = chest.weight or 1
		local scale = chest.luckScale or 0
		if scale > 0 then
			w *= math.max(0, 1 + (luck - 1) * scale)
		end
		table.insert(rows, { chest = chest, weight = w })
	end
	return rollWeighted(rows, rng).chest
end

--[[
	ONE CARD, ROLLED FROM THE PACK'S OWN TABLES.

	There were two roll points in the game and they disagreed. A pack found in
	the meadow had its contents decided HERE, at chest-break, from the pack's
	`odds`; every other pack (the starter, crate, quest and pass rewards) was
	rolled at OPEN time from MineCards' set-tier table. Two different tables, and
	the pack inspector could only print one of them -- so for the most common
	source of packs in the game it was printing numbers that did not govern.

	The pack's own table is the one that has to win, because it is the one that
	distinguishes packs: a Heirloom and a Loam from the same set have very
	different odds here and identical odds in the set-tier table. Collapsing onto
	the set tier would have flattened the entire pack ladder.

	So this is the single roll, and both callers use it.
]]

--[[
	Depth rarity ladder for every card/loot pack.

	Surface (layer 1): Mythic / Divine / Exotic are effectively never.
	Floor of the mine: Mythic ~1 in 100, Exotic ~1 in 1000, Divine between them.
	`heat` nudges chase rates for hotter pack slots without warming the surface
	(chase is multiplied by depth^2, so heat * 0 is still 0).
]]
function MinePackConfig.depthCardOdds(layer, maxLayers, heat)
	heat = math.max(0, tonumber(heat) or 0)
	maxLayers = math.max(2, math.floor(tonumber(maxLayers) or 2500))
	layer = math.clamp(math.floor(tonumber(layer) or 1), 1, maxLayers)
	local t = (layer - 1) / (maxLayers - 1)
	local u = t * t
	local exotic = 0.10 * u * (1 + 0.25 * heat)
	local divine = 0.33 * u * (1 + 0.20 * heat)
	local mythic = 1.00 * u * (1 + 0.15 * heat)
	local legendary = (0.12 + 7.5 * t) * (1 + 0.12 * heat)
	local epic = 1.8 + 14.0 * t
	local rare = 9.0 + 13.0 * t
	local uncommon = 28.0 - 8.0 * t
	local used = exotic + divine + mythic + legendary + epic + rare + uncommon
	local common = math.max(4, 100 - used)
	-- Renormalize so authored rows always sum to 100.
	local total = common + uncommon + rare + epic + legendary + mythic + divine + exotic
	local scale = 100 / total
	return {
		Common = common * scale,
		Uncommon = uncommon * scale,
		Rare = rare * scale,
		Epic = epic * scale,
		Legendary = legendary * scale,
		Mythic = mythic * scale,
		Divine = divine * scale,
		Exotic = exotic * scale,
	}
end

--[[
	Rarity ladder for inspector rows. Declared before oddsRowsFrom so the local
	is in scope (a later `local RARITY_ORDER` left the early function reading nil).
]]
local RARITY_ORDER = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic",
}

function MinePackConfig.oddsRowsFrom(oddsMap)
	if type(oddsMap) ~= "table" then
		return {}
	end
	local order = RARITY_ORDER or {
		"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic",
	}
	local total = 0
	for _, pct in pairs(oddsMap) do
		total += tonumber(pct) or 0
	end
	if total <= 0 then
		return {}
	end
	local rows = {}
	for _, rarity in ipairs(order) do
		local pct = oddsMap[rarity]
		if pct then
			table.insert(rows, { rarity = rarity, weight = pct / total * 100 })
		end
	end
	-- Include any odd keys not in the ladder so inspect never goes blank.
	if #rows == 0 then
		for rarity, pct in pairs(oddsMap) do
			table.insert(rows, { rarity = tostring(rarity), weight = (tonumber(pct) or 0) / total * 100 })
		end
	end
	return rows
end

--[[
	Luck siphon: same card count. need = HIGH × (luck-1). Steal Epic first,
	then Rare, Uncommon, Common. Pour stolen mass onto Legendary/Mythic/Divine/
	Exotic in proportion to their current weights. Never extra cards.
]]
function MinePackConfig.siphonOdds(oddsMap, luckMult)
	if type(oddsMap) ~= "table" then
		return oddsMap
	end
	local luck = tonumber(luckMult) or 1
	if luck <= 1 then
		return oddsMap
	end
	local HIGH = { "Legendary", "Mythic", "Divine", "Exotic" }
	local PAY = { "Epic", "Rare", "Uncommon", "Common" }
	local out = {}
	for k, v in pairs(oddsMap) do
		out[k] = tonumber(v) or 0
	end
	local highSum = 0
	for _, k in ipairs(HIGH) do
		highSum += out[k] or 0
	end
	if highSum <= 0 then
		return out
	end
	local need = highSum * (luck - 1)
	local stolen = 0
	for _, k in ipairs(PAY) do
		if need <= 0 then
			break
		end
		local have = out[k] or 0
		local take = math.min(have, need)
		out[k] = have - take
		stolen += take
		need -= take
	end
	if stolen > 0 then
		for _, k in ipairs(HIGH) do
			out[k] = (out[k] or 0) + stolen * ((oddsMap[k] or 0) / highSum)
		end
	end
	return out
end

--[[
	NOT EVERY PACK SPAWNS EVERY PET (TODO 6.2).

	A pack picks a RARITY from its own odds, then the card is drawn from every
	card of that rarity in the set -- so two packs of the same set are the same
	pack wearing a different wrapper, and "which pack do I open for this pet"
	has no answer.

	This narrows each pack to a WINDOW of the eligible pool. Generated, not
	authored: a hand-written subset per pack across the whole roster is a table
	that goes stale the first time a card is added, and nobody would notice
	which pet had quietly become unobtainable.

	How it behaves, and why these choices:

	  * The window is a contiguous slice of the rarity pool, offset by a hash of
	    the pack id. Deterministic, so a pack's pet list is a fact a player can
	    learn rather than a thing that rerolls per open.
	  * It WRAPS and snaps to a tile, so two packs cover the whole pool between
	    them. A subset scheme that can orphan a card is worse than none, and with
	    a free offset a thin set could. See cardPoolFor for the detail.
	  * A pool of 1 or 2 is left alone. Narrowing two cards to one makes the
	    other unobtainable from that pack for no gain.
	  * The share is deliberately generous (0.6). The point is that packs differ,
	    not that they are collections to grind -- too narrow and a player hunting
	    one pet is funnelled into one pack, which is the opposite of choice.
]]
MinePackConfig.CARD_SUBSET_SHARE = 0.6
MinePackConfig.CARD_SUBSET_MIN_POOL = 3

-- FNV-1a, via bit32: Luau has no infix bitwise operators, so `h ~ byte` (Lua
-- 5.3 syntax) does not parse here.
local function packHash(id)
	local h = 2166136261
	for i = 1, #id do
		h = bit32.bxor(h, string.byte(id, i))
		h = (h * 16777619) % 4294967296
	end
	return h
end

--[[
	The slice of `pool` this pack draws from. Returns `pool` itself when there is
	nothing to gain by narrowing, so callers can use the result unconditionally.
]]
function MinePackConfig.cardPoolFor(pack, pool)
	if type(pool) ~= "table" or #pool < (MinePackConfig.CARD_SUBSET_MIN_POOL or 3) then
		return pool
	end
	local id = pack and tostring(pack.id or "")
	if not id or id == "" then
		return pool
	end
	local n = #pool
	local take = math.max(2, math.ceil(n * (MinePackConfig.CARD_SUBSET_SHARE or 0.6)))
	if take >= n then
		return pool
	end
	--[[
		THE WINDOW SNAPS TO A TILE, and that is what makes coverage cheap.

		A free offset (hash % n) gives n possible windows, so covering the pool
		needs enough packs to land on enough of them -- and with a thin set some
		card is orphaned, which a test caught at a pool of 4.

		Snapped to multiples of `take` there are only ceil(n / take) windows, and
		with a share above one half that is TWO. So any set holding two packs
		whose hashes differ in the low bit shows every card between them. That is
		a property worth having over a prettier distribution: a pet no pack can
		produce is strictly worse than two packs sharing some pets.

		Coverage is still a property of the SET, not of this function -- one pack
		alone cannot show everything, by definition. tools/verify/packs.js checks
		it against the real roster.
	]]
	local tiles = math.ceil(n / take)
	local start = (packHash(id) % tiles) * take
	local out = {}
	for i = 0, take - 1 do
		out[#out + 1] = pool[((start + i) % n) + 1]
	end
	return out
end

function MinePackConfig.rollCard(pack, rng)
	rng = rng or Random.new()
	if not pack then
		return nil
	end
	local odds = pack.odds or {}
	if pack.depthLayer then
		odds = MinePackConfig.depthCardOdds(pack.depthLayer, pack.depthMax or 2500, pack.depthHeat or 0)
	end
	local luck = tonumber(pack.luck) or 1
	if luck > 1 then
		odds = MinePackConfig.siphonOdds(odds, luck)
	end
	local tier = rollWeighted(fromPercentTable(odds), rng)
	local variant = rollWeighted(fromPercentTable(MinePackConfig.variantOdds(pack.variants, pack.id)), rng)
	return {
		tier = tier and tier.id or "Common",
		variant = variant and variant.id or "Normal",
		shiny = rng:NextNumber() * 100 < (pack.shiny or MinePackConfig.SHINY_CHANCE),
	}
end

--[[
	God Pack: any card pack can upgrade into one. Rate is half that pack's Exotic
	rate (twice as rare as hitting Exotic). Every card inside is Mythic+.
]]
function MinePackConfig.godPackOdds(odds)
	odds = odds or {}
	local m = tonumber(odds.Mythic) or 0
	local d = tonumber(odds.Divine) or 0
	local e = tonumber(odds.Exotic) or 0
	local t = m + d + e
	if t <= 0 then
		return { Mythic = 70, Divine = 25, Exotic = 5 }
	end
	local s = 100 / t
	return { Mythic = m * s, Divine = d * s, Exotic = e * s }
end

function MinePackConfig.godPackChancePercent(odds)
	if type(odds) ~= "table" then
		return 0
	end
	return (tonumber(odds.Exotic) or 0) * 0.5
end

function MinePackConfig.rollIsGodPack(pack, rng)
	rng = rng or Random.new()
	if not pack or type(pack.odds) ~= "table" then
		return false
	end
	local kind = pack.kind
	if kind and kind ~= "cards" then
		return false
	end
	local odds = pack.odds
	if pack.depthLayer then
		odds = MinePackConfig.depthCardOdds(pack.depthLayer, pack.depthMax or 2500, pack.depthHeat or 0)
	end
	local pct = MinePackConfig.godPackChancePercent(odds)
	if pct <= 0 then
		return false
	end
	return rng:NextNumber() * 100 < pct
end

function MinePackConfig.rollGodCard(pack, rng)
	rng = rng or Random.new()
	if not pack then
		return nil
	end
	local odds = pack.odds or {}
	if pack.depthLayer then
		odds = MinePackConfig.depthCardOdds(pack.depthLayer, pack.depthMax or 2500, pack.depthHeat or 0)
	end
	local temp = table.clone(pack)
	temp.odds = MinePackConfig.godPackOdds(odds)
	temp.depthLayer = nil
	return MinePackConfig.rollCard(temp, rng)
end

--[[
	The same odds, as an ordered list for the pack inspector.
	(RARITY_ORDER lives above oddsRowsFrom.)
]]
function MinePackConfig.oddsFor(packId, opts)
	opts = opts or {}
	local pack = packId and MinePackConfig.PACK_BY_ID[packId]
	if not pack and type(packId) == "table" then
		pack = packId
	end
	local oddsMap = pack and pack.odds
	if opts.layer then
		oddsMap = MinePackConfig.depthCardOdds(opts.layer, opts.maxLayers, opts.heat)
	elseif pack and pack.depthLayer then
		oddsMap = MinePackConfig.depthCardOdds(pack.depthLayer, pack.depthMax, pack.depthHeat)
	end
	if type(oddsMap) ~= "table" then
		-- Zone packs live outside PACK_BY_ID; resolve by id string.
		if type(packId) == "string" then
			local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Mine")
				and game:GetService("ReplicatedStorage").Mine:FindFirstChild("Shared")
			local zpMod = shared and shared:FindFirstChild("MineZonePacks")
			if zpMod then
				local ok, ZP = pcall(require, zpMod)
				local zdef = ok and ZP and ZP.get and ZP.get(packId)
				if zdef and zdef.odds then
					oddsMap = zdef.odds
				end
			end
		end
	end
	return MinePackConfig.oddsRowsFrom(oddsMap) or {}
end

function MinePackConfig.openChestV2(chest, rng)
	rng = rng or Random.new()
	local packs = chest.packs or {}
	for i = #packs, 1, -1 do
		local row = packs[i]
		if rng:NextNumber() * 100 < (row.chance or 0) then
			local pack = MinePackConfig.PACK_BY_ID[row.packId]
			if pack and (pack.cards or 0) > 0 then
				local cards = {}
				for n = 1, pack.cards do
					local c = MinePackConfig.rollCard(pack, rng)
					cards[n] = { tier = c.tier, variant = c.variant, shiny = c.shiny, set = "X" }
				end
				return { chest = chest.id, packId = pack.id, packName = pack.name, cards = cards }
			end
		end
	end
	local coins = chest.coins or { 0, 0 }
	local gems = chest.gems or { 0, 0 }
	local coinAmt = coins[1]
	if coins[2] > coins[1] then
		coinAmt = rng:NextInteger(coins[1], coins[2])
	end
	local gemAmt = gems[1]
	if gems[2] > gems[1] then
		gemAmt = rng:NextInteger(gems[1], gems[2])
	end
	if #(chest.packs or {}) == 0 and gemAmt >= coinAmt then
		return { chest = chest.id, kind = "gems", amount = gemAmt }
	end
	if rng:NextNumber() < 0.45 then
		return { chest = chest.id, kind = "gems", amount = math.max(1, gemAmt) }
	end
	return { chest = chest.id, kind = "coins", amount = math.max(1, coinAmt) }
end

--[[
	WHAT A PACK COSTS, IN CREDITS.

	Packs were not sold at all -- the shop said so in plain text and offered
	nothing. These are the list prices for a single pack; the ten-pack is
	derived rather than typed, so a price change cannot leave a stale bundle
	behind it.

	The ladder is by DESIRABILITY, not by the silent tier. Apex is the most
	expensive pack in the game at 220 despite sorting near the bottom of
	PACK_TIER, because one guaranteed good card is what people actually want to
	buy; Hopper is the cheapest at 35 despite paying six cards, because they are
	six bad ones.
]]
MinePackConfig.PACK_PRICE = {
	-- Launch ladder: a 10-pack of the top SKU should feel impulse-reachable
	-- (~200–280 R$ via mid credit packs), not a 700 R$ whale gate.
	hopper_pack = 12,
	loam_pack = 14,
	ashen_pack = 16,
	clay_pack = 18,
	magma_pack = 20,
	slate_pack = 22,
	cinder_pack = 24,
	crimson_pack = 26,
	iron_pack = 28,
	night_pack = 32,
	-- The top of the shop. Every card comes out shiny, so it prices above
	-- apex_pack (60) rather than below it -- it was 36, cheaper than a
	-- Gear Vault, for the single best pack in the game.
	shiny_pack = 95,
	void_pack = 36,
	end_pack = 40,
	cobalt_pack = 42,
	omen_pack = 46,
	anomaly_pack = 50,
	heirloom_pack = 55,
	apex_pack = 60,

	rune_pack = 18,
	gear_pack = 24,
	rune_heavy_pack = 40,
	gear_case_pack = 45,
	rune_sealed_pack = 52,
	gear_vault_pack = 60,
}
-- Retired ids that still appear in old saves and chest rows.
MinePackConfig.PACK_PRICE.chrome_pack = MinePackConfig.PACK_PRICE.magma_pack
MinePackConfig.PACK_PRICE.magpie_pack = MinePackConfig.PACK_PRICE.magma_pack

-- Buying ten costs seven. Lead with the warehouse pack, not the single.
MinePackConfig.BUNDLE_QTY = 10
MinePackConfig.BUNDLE_RATE = 0.70

function MinePackConfig.priceOf(packId)
	return MinePackConfig.PACK_PRICE[tostring(packId)]
end

-- Shop credit list prices (≈Robux). Wide disparity: filler impulse vs whale chase.
-- Chests still drop packs — these prices are for buying sealed packs with credits,
-- so mid/high packs must feel premium vs grinding a chest.
MinePackConfig.CREDIT_PRICE = {
	hopper_pack = 12,
	loam_pack = 14,
	ashen_pack = 16,
	clay_pack = 18,
	magma_pack = 20,
	slate_pack = 22,
	cinder_pack = 24,
	crimson_pack = 26,
	iron_pack = 28,
	night_pack = 32,
	shiny_pack = 95,
	void_pack = 36,
	end_pack = 40,
	cobalt_pack = 42,
	omen_pack = 46,
	anomaly_pack = 50,
	heirloom_pack = 55,
	apex_pack = 60,

	rune_pack = 18,
	gear_pack = 24,
	rune_heavy_pack = 40,
	gear_case_pack = 45,
	rune_sealed_pack = 52,
	gear_vault_pack = 60,
}
MinePackConfig.CREDIT_PRICE.chrome_pack = MinePackConfig.CREDIT_PRICE.magma_pack
MinePackConfig.CREDIT_PRICE.magpie_pack = MinePackConfig.CREDIT_PRICE.magma_pack

function MinePackConfig.creditPriceOf(packId)
	return MinePackConfig.CREDIT_PRICE[tostring(packId)]
end


--[[
	Derived, never typed: bundle = unit x 10 x 0.70.

	Rounded, not floored. 35 * 10 * 0.70 is 244.99999999999997 in floating point,
	so a plain floor prices the Hopper bundle at 244 instead of 245 -- and the
	same one-credit slip shows up on any unit price whose product lands just
	under an integer. Storefront numbers that are wrong by one for no visible
	reason are the kind of thing players screenshot.
]]
function MinePackConfig.bundlePrice(packId)
	local unit = MinePackConfig.priceOf(packId)
	if not unit then
		return nil
	end
	return math.floor(unit * MinePackConfig.BUNDLE_QTY * MinePackConfig.BUNDLE_RATE + 0.5)
end

--[[
	What a subtotal actually costs when paid in Credits.

	Floored, because the discount should never round in the house's favour.

	Everyone gets 10% for paying in Credits. The Warehouse Pass doubles it --
	that is the whole membership pitch, and it is deliberately the same
	mechanic rather than a separate one, so a member is not learning a new rule,
	just a better number on a line they already read.
]]
MinePackConfig.CREDIT_DISCOUNT = 0.10
-- Founders no longer stacks a second checkout cut. Same 10% as everyone.
MinePackConfig.VIP_DISCOUNT = 0.10
-- Founders Pack face: 799 credits / R$799.
-- Vault is 1200 credits for R$749 — buy Vault, spend 799 on Founders, keep ~401
-- credits of buying power.
MinePackConfig.VIP_PRICE = 799
MinePackConfig.VIP_ROBUX = 799
MinePackConfig.VIP_SEATS = 500

function MinePackConfig.discountFor(isVip)
	return isVip and MinePackConfig.VIP_DISCOUNT or MinePackConfig.CREDIT_DISCOUNT
end

function MinePackConfig.creditPrice(subtotal, isVip)
	local s = math.max(0, math.floor(tonumber(subtotal) or 0))
	return math.floor(s * (1 - MinePackConfig.discountFor(isVip)))
end

--[[
	SILENT TIERS.

	A quality order for every pack, worst to best. Never shown to the player --
	it exists so lists sort sensibly and a run of opens works up from the junk
	instead of spending your best pack first.

	DERIVED, NOT HAND-WRITTEN. This used to be a literal id -> number list and
	it rotted the moment PACKS changed: the entry that was `chrome_pack` became
	`magma_pack` and the hardcoded list still ranked a pack that had stopped
	existing. The order is computed from the packs' own `odds` tables at load,
	so a new pack is ranked the moment it is added to Mine1PacksData and there
	is nothing here to keep in sync.

	The score is EXPECTED RARITY FOR THE WHOLE PACK: the average rarity of one
	card times how many cards the pack pays. That is what the player actually
	walks away holding, so a six-card pack of junk can outrank a three-card pack
	of decent cards, and a one-card pack has to be very good to place at all.
	Ties break alphabetically so the order is stable between sessions.

	The one hand-placed pack is shiny_pack, pinned to the front on request. It
	is the game's only elevated shiny source and it sorts first on purpose.

	Note this is NOT the price ladder -- PACK_PRICE above is ordered by what
	people will pay, which is a different question and deliberately disagrees.
]]
local TIER_RANK = {
	Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
	Legendary = 5, Mythic = 6, Divine = 7, Exotic = 8,
}

local PINNED_FIRST = { shiny_pack = true }

local function packScore(pack)
	local sum, total = 0, 0
	for tier, pct in pairs(pack.odds or {}) do
		sum += (TIER_RANK[tier] or 0) * pct
		total += pct
	end
	if total <= 0 then
		return 0
	end
	return (sum / total) * (tonumber(pack.cards) or 0)
end

MinePackConfig.PACK_TIER = {}
do
	local ranked = {}
	for _, pack in ipairs(MinePackConfig.PACKS or {}) do
		table.insert(ranked, {
			id = pack.id,
			score = packScore(pack),
			pinned = PINNED_FIRST[pack.id] and 0 or 1,
		})
	end
	table.sort(ranked, function(x, y)
		if x.pinned ~= y.pinned then
			return x.pinned < y.pinned
		end
		if math.abs(x.score - y.score) > 1e-6 then
			return x.score < y.score
		end
		return x.id < y.id
	end)
	for i, row in ipairs(ranked) do
		MinePackConfig.PACK_TIER[row.id] = i
	end
	-- Retired ids that still sit in old save files, pointed at their successor
	-- so an inventory written before the rename still sorts.
	for old, current in pairs({ chrome_pack = "magma_pack", magpie_pack = "magma_pack" }) do
		MinePackConfig.PACK_TIER[old] = MinePackConfig.PACK_TIER[current]
	end
end

function MinePackConfig.packTier(id)
	return (id and MinePackConfig.PACK_TIER[id]) or 0
end

--[[
	HOW GOOD IS THIS PACK, OUT OF FIVE.

	The old rating was the credit price band for anything with a price on it,
	which made the stars a second price tag: they said what the shop charges,
	not what the pack pays. This scores what is actually in it, from the same
	`odds` table the roller draws from:

	  odds    the chance of each rarity, valued on a curve (an Exotic is worth
	          hundreds of Commons, not eight)
	  cards   how many units the pack pays
	  shiny   the per-card shiny rate, which is the other chase

	The score is then placed on a log scale between the weakest and the
	strongest pack in the game, so the range always spans one to five stars and
	a new pack rates itself. Halves are real: 3.5 is between, not rounded.
]]
local RARITY_VALUE = {
	Common = 1, Uncommon = 2, Rare = 5, Epic = 12,
	Legendary = 30, Mythic = 80, Divine = 220, Exotic = 600,
}

function MinePackConfig.packScore(id)
	local row = MinePackConfig.PACK_BY_ID and MinePackConfig.PACK_BY_ID[tostring(id or "")]
	if not row then
		return 0
	end
	local per, total = 0, 0
	for tier, pct in pairs(row.odds or {}) do
		local w = tonumber(pct) or 0
		per += (RARITY_VALUE[tier] or 1) * w
		total += w
	end
	per = (total > 0) and (per / total) or 1
	-- A shiny copy is worth about three of the same card.
	per *= 1 + (tonumber(row.shiny) or 0) / 100 * 3
	return per * math.max(1, tonumber(row.cards) or 1)
end

local starBandCache
local function starBand()
	if starBandCache then
		return starBandCache
	end
	local lo, hi = math.huge, 0
	for _, row in ipairs(MinePackConfig.PACKS or {}) do
		local score = MinePackConfig.packScore(row.id)
		if score > 0 then
			lo = math.min(lo, score)
			hi = math.max(hi, score)
		end
	end
	if lo == math.huge then
		lo, hi = 1, 2
	end
	starBandCache = { lo = lo, hi = math.max(hi, lo * 1.01) }
	return starBandCache
end

-- Nearest half, never below half a star.
function MinePackConfig.halfStars(value)
	return math.clamp(math.floor((tonumber(value) or 0) * 2 + 0.5) / 2, 0.5, 5)
end

-- Whether a pack is rated at all. Only real packs are; zone packs carry no
-- stars (owner, docs/PETS-AND-SETS.md: "Zone packs get no stars").
function MinePackConfig.isRated(id)
	return MinePackConfig.PACK_BY_ID ~= nil and MinePackConfig.PACK_BY_ID[tostring(id or "")] ~= nil
end

function MinePackConfig.packStars(id)
	-- A hand rating wins. The new set packs are rated by the owner (1 to 5 in
	-- halves), and a hand rating must not drift when another pack is added.
	local row = MinePackConfig.PACK_BY_ID and MinePackConfig.PACK_BY_ID[tostring(id or "")]
	if row and tonumber(row.stars) then
		return MinePackConfig.halfStars(row.stars)
	end
	local score = MinePackConfig.packScore(id)
	if score <= 0 then
		return 1
	end
	local band = starBand()
	local t = (math.log(score) - math.log(band.lo)) / (math.log(band.hi) - math.log(band.lo))
	return MinePackConfig.halfStars(1 + math.clamp(t, 0, 1) * 4)
end

-- "4.5★", for lines of text that cannot draw a row of glyphs.
function MinePackConfig.starLabel(id)
	local n = MinePackConfig.packStars(id)
	return string.format("%s★", (n % 1 == 0) and string.format("%d", n) or string.format("%.1f", n))
end

function MinePackConfig.starText(id)
	local n = math.floor(MinePackConfig.packStars(id) + 0.5)
	return string.rep("★", n) .. string.rep("☆", 5 - n)
end

--[[
	Which roller fills a pack: "card" (the default and the overwhelming
	majority), or "rune" / "gear".

	Read from the pack row rather than from an id prefix. A list keyed on
	`id:find("rune")` looks fine until a card pack is called Runebound.
]]
--[[
	What one unit out of this pack is called, singular or plural.

	The store, the dex and the inspector all print a count next to a noun, and
	"3 cards" on a rune pouch is the sort of wrong that makes a player distrust
	the odds printed underneath it. One place to ask, so a new family only ever
	needs a row here.
]]
local PACK_UNIT = {
	card = { "card", "cards" },
	rune = { "rune", "runes" },
	gear = { "piece", "pieces" },
}

function MinePackConfig.unitWord(packId, n)
	local u = PACK_UNIT[MinePackConfig.packKind(packId)] or PACK_UNIT.card
	return (tonumber(n) == 1) and u[1] or u[2]
end

--[[
	What share of a pack's shinies come out Shadow instead.

	One in a hundred everywhere (MineConfig.SHADOW_OF_SHINY), and one in
	twenty-five in the Shiny Pack -- the single place the share moves, which is
	what makes that pack the one you open hunting a shadow rather than just more
	foil.

	Note what one-in-twenty-five means HERE: the Universal Shiny Pack is 100%
	shiny (`shiny = 100`), so every card it pays rolls this share. A share of the
	shinies and a share of the cards are the same number in this pack and only in
	this pack -- three cards an open, so a shadow every eight or nine packs.
]]
MinePackConfig.SHADOW_OF_SHINY = {
	-- Every shiny in the Shadow Pack IS a shadow. That is the whole product.
	shadow_pack = 1.0,
	shiny_pack = 1 / 25,
}

function MinePackConfig.shadowOfShiny(packId, fallback)
	return MinePackConfig.SHADOW_OF_SHINY[tostring(packId or "")]
		or tonumber(fallback)
		or (1 / 100)
end

-- Shiny is a card finish. A rune or a gear piece cannot roll one, so the
-- inspector asks before it prints a rate rather than printing 0.00%.
function MinePackConfig.hasShiny(packId)
	return MinePackConfig.packKind(packId) == "card"
end

function MinePackConfig.packKind(id)
	local row = id and MinePackConfig.PACK_BY_ID[id]
	return (row and row.kind) or "card"
end

-- How many cards a pack pays: one source of truth for the number the inventory
-- prints and the number openPack actually mints.
function MinePackConfig.packCards(id)
	local row = id and MinePackConfig.PACK_BY_ID[id]
	return (row and tonumber(row.cards)) or 0
end

--------------------------------------------------------------------------------
-- DAILY STARDUST SHOP
-- Six mid-tier packs, shared global stock (10 each), re-roll every UTC day.
-- High-end / shiny stay credits-only forever.
--------------------------------------------------------------------------------
MinePackConfig.DUST_STOCK_MAX = 2
MinePackConfig.DUST_OFFER_COUNT = 5
-- Mid packs are the usual shelf. Awesome / shiny inject rarely in dustRotation.
MinePackConfig.DUST_EXCLUDE = {
	rune_heavy_pack = true,
	gear_case_pack = true,
	rune_sealed_pack = true,
	gear_vault_pack = true,
}
MinePackConfig.DUST_AWESOME = {
	shiny_pack = true, heirloom_pack = true, apex_pack = true,
	omen_pack = true, anomaly_pack = true, void_pack = true, end_pack = true,
}

function MinePackConfig.dustEligibleIds()
	local out = {}
	for id, price in pairs(MinePackConfig.PACK_PRICE or {}) do
		if not MinePackConfig.DUST_EXCLUDE[id] and (tonumber(price) or 0) > 0 then
			table.insert(out, id)
		end
	end
	table.sort(out)
	return out
end

function MinePackConfig.expectedDust(packId)
	local row = MinePackConfig.PACK_BY_ID and MinePackConfig.PACK_BY_ID[tostring(packId or "")]
	if not row then
		return 0
	end
	local rec = MinePackConfig.RECYCLE_STARDUST or {}
	local sum, total = 0, 0
	for tier, pct in pairs(row.odds or {}) do
		local w = tonumber(pct) or 0
		sum += (tonumber(rec[tier]) or 6) * w
		total += w
	end
	local per = (total > 0) and (sum / total) or 6
	per *= 1 + (tonumber(row.shiny) or 0) / 100 * 2
	return per * math.max(1, tonumber(row.cards) or 1)
end

-- 65% RTP: price is expected scrap / 0.65. Shiny is forced above every other pack later.
function MinePackConfig.dustPriceOf(packId)
	local ev = MinePackConfig.expectedDust(packId)
	if ev <= 0 then
		local credits = MinePackConfig.priceOf and MinePackConfig.priceOf(packId)
			or (MinePackConfig.PACK_PRICE and MinePackConfig.PACK_PRICE[packId])
			or 0
		ev = (tonumber(credits) or 0) * 8
	end
	return math.max(20, math.ceil(ev / 0.65))
end

-- Deterministic daily pick from UTC day key "YYYYMMDD".
function MinePackConfig.dailyDustOffers(dayKey)
	dayKey = tostring(dayKey or "")
	local pool = MinePackConfig.dustEligibleIds()
	if #pool == 0 then
		return {}
	end
	local seed = 0
	for i = 1, #dayKey do
		seed = (seed * 33 + string.byte(dayKey, i)) % 2147483647
	end
	if seed <= 0 then seed = 1 end
	local rng = Random.new(seed)
	-- Fisher-Yates shuffle copy
	local bag = table.clone(pool)
	for i = #bag, 2, -1 do
		local j = rng:NextInteger(1, i)
		bag[i], bag[j] = bag[j], bag[i]
	end
	local n = math.min(MinePackConfig.DUST_OFFER_COUNT, #bag)
	local offers = {}
	for i = 1, n do
		local id = bag[i]
		table.insert(offers, {
			id = id,
			price = MinePackConfig.dustPriceOf(id),
			stockMax = MinePackConfig.DUST_STOCK_MAX,
		})
	end
	return offers
end

--------------------------------------------------------------------------------
-- THE STARDUST SHOP -- a six-hour rotation.
--
-- Every six hours (00:00, 06:00, 12:00, 18:00 UTC) the shelf is re-dealt from
-- the dust-eligible packs, the same deal on every server. Each listing rolls
-- two limits for that rotation:
--   personalMax  10-30   how many of it any one player may buy
--   globalMax    0-10000 how many may be bought by everyone, on every server,
--                        combined (a 0 is a listing that is already gone)
-- The global count lives in a DataStore keyed by the rotation, so it is shared
-- and it resets itself when the key changes.
--------------------------------------------------------------------------------
MinePackConfig.DUST_ROTATION_HOURS = 6
MinePackConfig.DUST_ROTATION_OFFERS = 4
MinePackConfig.DUST_POTION_OFFERS = 4
MinePackConfig.DUST_PERSONAL_MIN, MinePackConfig.DUST_PERSONAL_MAX = 1, 2
MinePackConfig.DUST_GLOBAL_MIN, MinePackConfig.DUST_GLOBAL_MAX = 6, 24

function MinePackConfig.dustRotationKey(t)
	local d = os.date("!*t", t or os.time())
	local slot = math.floor(d.hour / MinePackConfig.DUST_ROTATION_HOURS)
	return string.format("%04d%02d%02d-%d", d.year, d.month, d.day, slot)
end

-- When the current rotation ends (os.time).
function MinePackConfig.dustRotationEnds(t)
	t = t or os.time()
	local step = MinePackConfig.DUST_ROTATION_HOURS * 3600
	return (math.floor(t / step) + 1) * step
end

function MinePackConfig.dustRotation(key)
	key = tostring(key or "")
	local seed = 7
	for i = 1, #key do
		seed = (seed * 131 + string.byte(key, i)) % 2147483647
	end
	local rng = Random.new(math.max(1, seed))

	local mid, awesome, shinyId = {}, {}, nil
	for _, id in ipairs(MinePackConfig.dustEligibleIds()) do
		local def = MinePackConfig.PACK_BY_ID and MinePackConfig.PACK_BY_ID[id]
		if def and MinePackConfig.packKind(id) == "card" and (tonumber(def.cards) or 0) > 0 then
			if id == "shiny_pack" then
				shinyId = id
			elseif MinePackConfig.DUST_AWESOME[id] then
				table.insert(awesome, id)
			else
				table.insert(mid, id)
			end
		end
	end
	local function shuffle(bag)
		for i = #bag, 2, -1 do
			local j = rng:NextInteger(1, i)
			bag[i], bag[j] = bag[j], bag[i]
		end
	end
	shuffle(mid)
	shuffle(awesome)

	local function packOffer(id)
		local def = MinePackConfig.PACK_BY_ID and MinePackConfig.PACK_BY_ID[id]
		return {
			id = id,
			kind = "pack",
			name = (def and def.name) or id,
			stars = MinePackConfig.packStars and MinePackConfig.packStars(id) or 1,
			price = MinePackConfig.dustPriceOf(id),
			personalMax = rng:NextInteger(MinePackConfig.DUST_PERSONAL_MIN, MinePackConfig.DUST_PERSONAL_MAX),
			globalMax = rng:NextInteger(MinePackConfig.DUST_GLOBAL_MIN, MinePackConfig.DUST_GLOBAL_MAX),
		}
	end

	local offers = {}
	for i = 1, math.min(MinePackConfig.DUST_ROTATION_OFFERS, #mid) do
		table.insert(offers, packOffer(mid[i]))
	end
	-- Rare awesome: swap the last mid for something loud.
	if #awesome > 0 and #offers > 0 and rng:NextNumber() < 0.15 then
		offers[#offers] = packOffer(awesome[1])
	end
	-- Rare shiny, always the priciest row once it lands.
	if shinyId and rng:NextNumber() < 0.10 then
		table.insert(offers, packOffer(shinyId))
	end

	local okPot, Potions = pcall(function()
		return require(script.Parent:WaitForChild("MinePotions"))
	end)
	if okPot and Potions and Potions.shopPool then
		local pots = Potions.shopPool(rng)
		for i = 1, math.min(MinePackConfig.DUST_POTION_OFFERS, #pots) do
			local def = pots[i]
			table.insert(offers, {
				id = def.id,
				kind = "potion",
				name = def.name,
				stars = def.tier or 1,
				price = def.dust or Potions.dustPrice(def.id),
				personalMax = rng:NextInteger(1, 2),
				globalMax = rng:NextInteger(8, 20),
			})
		end
	end

	local maxP = 0
	for _, o in ipairs(offers) do
		if o.id ~= "shiny_pack" then
			maxP = math.max(maxP, tonumber(o.price) or 0)
		end
	end
	for _, o in ipairs(offers) do
		if o.id == "shiny_pack" then
			o.price = math.max(tonumber(o.price) or 0, maxP + 50)
		end
	end
	table.sort(offers, function(x, y)
		return (tonumber(x.price) or 0) < (tonumber(y.price) or 0)
	end)
	return offers
end

--[[
	"1 IN X" FOR A PULLED CARD -- from the odds that actually rolled it.

	Reads the pack exactly the way rollCard, rollIsGodPack and rollGodCard do:
	the pack's own tier table (or its depth table), luck siphoned the same way,
	the variant table, the shiny roll with its one-in-twenty Shadow split, and
	the god-pack chance mixed in. It reads the same fields the roller reads, so
	the number cannot drift from what the roller does.

	Returns two "1 in X" numbers:
	  exact  THIS card, in THIS form, from ONE of these packs: the form's chance
	         split across every card of that rarity in the set, and across
	         every slot in the pack.
	  form   this rarity + variant + finish in one slot. The reveal ranks and
	         reacts by it, so a Rainbow Legendary (rarer) comes out after a
	         plain Mythic (commoner) and gets the louder screen.
]]
function MinePackConfig.pullOdds(pack, card, poolSize, slots, shadowOfShiny)
	if type(pack) ~= "table" or type(pack.odds) ~= "table" or type(card) ~= "table" then
		return nil, nil
	end
	local odds = pack.odds
	if pack.depthLayer then
		odds = MinePackConfig.depthCardOdds(pack.depthLayer, pack.depthMax or 2500, pack.depthHeat or 0)
	end
	local luck = tonumber(pack.luck) or 1
	local rolled = (luck > 1) and MinePackConfig.siphonOdds(odds, luck) or odds
	local function share(t, key)
		local total, hit = 0, 0
		for k, w in pairs(t or {}) do
			w = tonumber(w) or 0
			if w > 0 then
				total += w
				if k == key then
					hit = w
				end
			end
		end
		return (total > 0) and (hit / total) or 0
	end
	local tier = card.rarityId or "Common"
	local s = math.clamp((tonumber(pack.shiny) or MinePackConfig.SHINY_CHANCE or 0) / 100, 0, 1)
	local sh = tonumber(shadowOfShiny) or 0.05
	local finish = (card.shadow and s * sh) or (card.shiny and s * (1 - sh)) or (1 - s)
	local form = share(MinePackConfig.variantOdds(pack.variants, pack.id), card.variant or "Normal") * finish
	local god = 0
	if not pack.kind or pack.kind == "cards" then
		god = math.clamp(MinePackConfig.godPackChancePercent(odds) / 100, 0, 1)
	end
	local qNormal = share(rolled, tier) * form
	local qGod = (god > 0) and share(MinePackConfig.godPackOdds(odds), tier) * form or 0
	local n = math.max(1, math.floor(tonumber(slots) or 1))
	local cards = math.max(1, math.floor(tonumber(poolSize) or 1))
	local perSlot = (1 - god) * qNormal + god * qGod
	local perPack = (1 - god) * (1 - (1 - qNormal / cards) ^ n) + god * (1 - (1 - qGod / cards) ^ n)
	return (perPack > 0) and (1 / perPack) or nil, (perSlot > 0) and (1 / perSlot) or nil
end

--[[
	THE 19 SETS' PACKS (MineSetPacks) answer every pack lookup like any other
	pack: the bag tile, the inspector, the admin grant and the opener all read
	PACK_BY_ID. They stay OUT of PACKS, the universal list, so no shop, star
	band or rotation that walks it starts selling or re-rating them.

	Their sort rank sits among the universal packs by the same score, so a
	five-star set pack sorts with the best packs and a one-star with the worst.
]]
do
	local mod = script.Parent:FindFirstChild("MineSetPacks")
	local ok, SetPacks = pcall(function()
		return mod and require(mod)
	end)
	if ok and type(SetPacks) == "table" then
		local scores = {}
		for _, row in ipairs(MinePackConfig.PACKS or {}) do
			table.insert(scores, packScore(row))
		end
		for _, def in ipairs(SetPacks.PACKS or {}) do
			if MinePackConfig.PACK_BY_ID[def.id] == nil then
				MinePackConfig.PACK_BY_ID[def.id] = def
				local mine, below = packScore(def), 0
				for _, sc in ipairs(scores) do
					if sc <= mine then
						below += 1
					end
				end
				MinePackConfig.PACK_TIER[def.id] = below + 0.5
			end
		end
	elseif not ok and warn then
		-- (warn is nil in the offline pack checks, which stub the module tree)
		warn("[MinePackConfig] MineSetPacks: " .. tostring(SetPacks))
	end
end

return MinePackConfig
