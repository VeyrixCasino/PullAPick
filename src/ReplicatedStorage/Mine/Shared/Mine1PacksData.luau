-- Auto-generated Mine 1 PACKS. Required by MinePackConfig.
return {
	{
		id = "loam_pack", name = "Meadow Loam Pack", cards = 3,
		odds = { Common = 40.000, Uncommon = 30.000, Rare = 18.000, Epic = 8.000, Legendary = 3.200, Mythic = 0.650, Divine = 0.120, Exotic = 0.030 },
		shiny = 4.0,
	},
	{
		id = "ashen_pack", name = "Meadow Ashen Pack", cards = 3,
		odds = { Common = 36.036, Uncommon = 30.030, Rare = 20.020, Epic = 9.009, Legendary = 3.804, Mythic = 0.901, Divine = 0.160, Exotic = 0.040 },
		shiny = 4.0,
	},
	{
		id = "clay_pack", name = "Meadow Clay Pack", cards = 3,
		odds = { Common = 33.076, Uncommon = 30.069, Rare = 21.048, Epic = 10.023, Legendary = 4.410, Mythic = 1.103, Divine = 0.221, Exotic = 0.050 },
		shiny = 4.5,
	},
	{
		id = "slate_pack", name = "Meadow Slate Pack", cards = 3,
		odds = { Common = 30.111, Uncommon = 29.108, Rare = 22.082, Epic = 11.543, Legendary = 5.219, Mythic = 1.506, Divine = 0.351, Exotic = 0.080 },
		shiny = 5.0,
	},
	{
		id = "cinder_pack", name = "Meadow Cinder Pack", cards = 3,
		odds = { Common = 27.049, Uncommon = 28.050, Rare = 23.041, Epic = 13.023, Legendary = 6.211, Mythic = 2.004, Divine = 0.501, Exotic = 0.120 },
		shiny = 5.0,
	},
	{
		id = "crimson_pack", name = "Meadow Crimson Pack", cards = 3,
		odds = { Common = 23.981, Uncommon = 26.978, Rare = 23.981, Epic = 14.488, Legendary = 7.194, Mythic = 2.498, Divine = 0.699, Exotic = 0.180 },
		shiny = 5.5,
	},
	{
		id = "iron_pack", name = "Meadow Ironsoil Pack", cards = 3,
		odds = { Common = 20.024, Uncommon = 25.030, Rare = 25.030, Epic = 16.019, Legendary = 9.011, Mythic = 3.504, Divine = 1.101, Exotic = 0.280 },
		shiny = 6.0,
	},
	{
		id = "night_pack", name = "Meadow Nightclay Pack", cards = 3,
		odds = { Common = 16.008, Uncommon = 23.012, Rare = 26.013, Epic = 18.009, Legendary = 11.006, Mythic = 4.202, Divine = 1.401, Exotic = 0.350 },
		shiny = 6.0,
	},
	{
		id = "void_pack", name = "Meadow Voidloam Pack", cards = 3,
		odds = { Common = 12.127, Uncommon = 20.212, Rare = 26.276, Epic = 20.212, Legendary = 13.138, Mythic = 5.558, Divine = 2.021, Exotic = 0.455 },
		shiny = 7.0,
	},
	{
		id = "end_pack", name = "Meadow Endsoil Pack", cards = 3,
		odds = { Common = 10.040, Uncommon = 18.072, Rare = 25.100, Epic = 22.088, Legendary = 15.060, Mythic = 6.526, Divine = 2.610, Exotic = 0.502 },
		shiny = 7.0,
	},
	{
		id = "hopper_pack", name = "Universal Hopper Pack", cards = 6,
		odds = { Common = 55.000, Uncommon = 30.000, Rare = 11.000, Epic = 3.000, Legendary = 0.800, Mythic = 0.150, Divine = 0.040, Exotic = 0.010 },
		shiny = 3.0,
	},
	{
		id = "magma_pack", name = "Universal Magma Pack", cards = 8,
		odds = { Common = 58.000, Uncommon = 27.000, Rare = 10.000, Epic = 3.200, Legendary = 1.200, Mythic = 0.450, Divine = 0.120, Exotic = 0.030 },
		shiny = 12.0,
	},
	{
		id = "apex_pack", name = "Universal Apex Pack", cards = 1,
		odds = { Common = 0.000, Uncommon = 5.000, Rare = 18.000, Epic = 32.000, Legendary = 30.000, Mythic = 11.000, Divine = 3.500, Exotic = 0.500 },
		shiny = 6.0,
	},
	{
		--[[
			SHADOW PACK -- BUILT, NOT SOLD.

			Every card comes out SHADOW: shiny = 100 puts a finish on all three,
			and MinePackConfig.SHADOW_OF_SHINY.shadow_pack = 1 turns every one of
			those shinies into a shadow instead of one in twenty-five.

			It is deliberately absent from MinePackConfig.PACK_PRICE and carries
			no `spawn`, so nothing sells it and no chest drops it. It exists so
			the product is ready the day you want it; putting a price on it is
			the only step left.
		]]
		id = "shadow_pack", name = "Universal Shadow Pack", cards = 3,
		odds = { Common = 2.000, Uncommon = 5.000, Rare = 11.000, Epic = 20.000, Legendary = 30.000, Mythic = 18.000, Divine = 9.500, Exotic = 4.500 },
		shiny = 100.0,
	},
	{
		id = "shiny_pack", name = "Universal Shiny Pack", cards = 3,
		-- Every card comes out shiny -- that is the whole product -- and the
		-- rarity table sits with the top of the shop so the five stars are real.
		odds = { Common = 4.000, Uncommon = 8.000, Rare = 14.000, Epic = 22.000, Legendary = 28.000, Mythic = 14.000, Divine = 7.500, Exotic = 2.500 },
		shiny = 100.0,
	},
	{
		id = "cobalt_pack", name = "Universal Cobalt Pack", cards = 3,
		odds = { Common = 22.000, Uncommon = 24.000, Rare = 24.000, Epic = 16.000, Legendary = 9.000, Mythic = 3.500, Divine = 1.200, Exotic = 0.300 },
		shiny = 8.0,
	},
	{
		id = "omen_pack", name = "Universal Omen Pack", cards = 3,
		odds = { Common = 14.000, Uncommon = 20.000, Rare = 24.000, Epic = 20.000, Legendary = 13.000, Mythic = 6.000, Divine = 2.400, Exotic = 0.600 },
		shiny = 7.0,
	},
	{
		id = "anomaly_pack", name = "Universal Anomaly Pack", cards = 3,
		odds = { Common = 10.000, Uncommon = 16.000, Rare = 22.000, Epic = 22.000, Legendary = 16.000, Mythic = 9.000, Divine = 4.000, Exotic = 1.000 },
		shiny = 10.0,
	},
	{
		id = "heirloom_pack", name = "Universal Heirloom Pack", cards = 3,
		odds = { Common = 8.000, Uncommon = 14.000, Rare = 20.000, Epic = 22.000, Legendary = 18.000, Mythic = 11.000, Divine = 5.500, Exotic = 1.500 },
		shiny = 12.0,
	},

	--[[
		LOOT PACKS -- runes and gear, sold and opened as packs.

		Same shape as a card pack on purpose. `cards` is how many ITEMS the pack
		pays, and `odds` is over the same eight-name rarity ladder, so every
		derived thing keeps working with nothing to teach it: PACK_TIER scores
		them, the store lists them, the inspector prints them, the reveal colours
		and paces them, and the worst-to-best sort puts the hit last.

		`kind` is the only new field. It says which roller builds the item, and
		MineLootPacks maps the ladder onto that family's own scale --
		Common..Exotic onto gear F..SSS and onto rune tiers 1..5.

		These odds GOVERN. The roller reads this table rather than each family's
		internal weights, for the same reason the card packs do: two tables that
		can disagree eventually do, and the one on screen is the one that lies.
	]]
	-- Runes stop at tier 5, so Mythic and above are zero here rather than absent:
	-- a printed 0.00% is a promise, a missing row is a question.
	{
		id = "rune_pack", name = "Rune Case", kind = "rune", cards = 1,
		odds = { Common = 30.000, Uncommon = 25.000, Rare = 20.000, Epic = 15.000, Legendary = 10.000, Mythic = 0.000, Divine = 0.000, Exotic = 0.000 },
	},
	{
		id = "rune_heavy_pack", name = "Heavy Rune Case", kind = "rune", cards = 3,
		odds = { Common = 22.000, Uncommon = 24.000, Rare = 23.000, Epic = 18.000, Legendary = 13.000, Mythic = 0.000, Divine = 0.000, Exotic = 0.000 },
	},
	{
		id = "rune_sealed_pack", name = "Sealed Rune Case", kind = "rune", cards = 6,
		odds = { Common = 0.000, Uncommon = 34.000, Rare = 28.000, Epic = 22.000, Legendary = 16.000, Mythic = 0.000, Divine = 0.000, Exotic = 0.000 },
	},
	{
		id = "gear_pack", name = "Gear Case", kind = "gear", cards = 1,
		odds = { Common = 9.800, Uncommon = 23.783, Rare = 31.913, Epic = 23.783, Legendary = 9.800, Mythic = 0.808, Divine = 0.101, Exotic = 0.020 },
	},
	{
		id = "gear_case_pack", name = "Gear Case", kind = "gear", cards = 3,
		odds = { Common = 4.000, Uncommon = 16.000, Rare = 30.000, Epic = 28.000, Legendary = 18.000, Mythic = 3.200, Divine = 0.650, Exotic = 0.150 },
	},
	{
		id = "gear_vault_pack", name = "Gear Vault", kind = "gear", cards = 5,
		odds = { Common = 0.000, Uncommon = 6.000, Rare = 20.000, Epic = 30.000, Legendary = 28.000, Mythic = 12.000, Divine = 3.200, Exotic = 0.800 },
	},
}
