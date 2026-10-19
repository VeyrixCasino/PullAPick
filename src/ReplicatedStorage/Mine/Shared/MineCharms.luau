-- MineCharms: one-equip chase identities.
-- Zone grants: every second (odd) island × three depth bands.
-- Pack: 15 gem/Robux pool. Lucky Charm is reserved limited (not in pack).
--
-- 2026-10-19 (owner): EVERY CHARM HAS ONE RARITY, F..SSS, forever ("{sod charm
-- rare always}"), on every row: zone, pack and limited rows say it, the graded
-- and Halloween rows always did, and an ore charm takes its ore's band. A charm
-- climbs TIERS I..V by merging (gems plus any charm of the same tier, used up);
-- a merge never changes the rarity. See TIERS below, the 32 NEW_GRADED charms
-- (four per rarity), the eight CRYPT_CHEST_CHARMS (cryptChestCharm) and the
-- eight CHARM_PACKS. The server half is MineCharmService.

local MineCharms = {}

-- The graded charms sit on MineTemper's F..SSS ladder rather than inventing a
-- second one, so a grade means the same thing on a charm as on a temperament.
local Temper = require(script.Parent:WaitForChild("MineTemper"))
-- Numbers follow handoff/launch/CHARMS.md ("one slot = chase": a shallow charm is
-- +100-140%, mid +170-230%, deep +250-320%). A morning retune had cut the five dig
-- charms to +18-90%; the user asked for them back (2026-09-19).

function MineCharms.bandForLayer(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	if layer <= 500 then
		return "shallow"
	elseif layer <= 1500 then
		return "mid"
	end
	return "deep"
end

MineCharms.CHARM_ZONES = {
	meadow = true,
	mistreef = true,
	bloodmoon = true,
	riftmarch = true,
	mythral = true,
}

local LIST = {
	{ id = "sod", name = "Sod Charm", source = "zone", rarity = "C", zoneId = "meadow", band = "shallow",
		blurb = "+110% Mine Speed", stats = { mineSpeed = 1.10 } },
	{ id = "rootstride", name = "Rootstride Charm", source = "zone", rarity = "B", zoneId = "meadow", band = "mid",
		blurb = "+180% Mine Speed · +60% Backpack", stats = { mineSpeed = 1.80, backpack = 0.60 } },
	{ id = "thornvault", name = "Thornvault Charm", source = "zone", rarity = "A", zoneId = "meadow", band = "deep",
		blurb = "+260% Dirt Break · +40% Pulverizer", stats = { dirtBreak = 2.60, pulverize = 0.40 } },

	{ id = "brine", name = "Brine Charm", source = "zone", rarity = "C", zoneId = "mistreef", band = "shallow",
		blurb = "+130% Gem Find", stats = { gemFind = 1.30 } },
	{ id = "tideglass", name = "Tideglass Charm", source = "zone", rarity = "B", zoneId = "mistreef", band = "mid",
		blurb = "+200% Mine Speed · +40% Swing Rate", stats = { mineSpeed = 2.00, swingRate = 0.40 } },
	{ id = "abyss_latch", name = "Abyss Latch", source = "zone", rarity = "B", zoneId = "mistreef", band = "deep",
		blurb = "+55% Omni Blast · +90% Scrap", stats = { blastChance = 0.55, scrap = 0.90 } },

	{ id = "emberseal", name = "Emberseal Charm", source = "zone", rarity = "C", zoneId = "bloodmoon", band = "shallow",
		blurb = "+140% Dirt Break", stats = { dirtBreak = 1.40 } },
	{ id = "veilspike", name = "Veilspike Charm", source = "zone", rarity = "B", zoneId = "bloodmoon", band = "mid",
		blurb = "+210% Mine Speed · +50% Luck", stats = { mineSpeed = 2.10, luck = 0.50 } },
	{ id = "crimson_crown", name = "Crimson Crown", source = "zone", rarity = "A", zoneId = "bloodmoon", band = "deep",
		blurb = "+280% Coin Bonus · +70% Chest Luck", stats = { coinBonus = 2.80, chestLuck = 0.70 } },

	{ id = "fracture_pin", name = "Fracture Pin", source = "zone", rarity = "C", zoneId = "riftmarch", band = "shallow",
		blurb = "+140% Mine Speed · +50% Dirt Break", stats = { mineSpeed = 1.40, dirtBreak = 0.50 } },
	{ id = "scarpsign", name = "Scarpsign Charm", source = "zone", rarity = "C", zoneId = "riftmarch", band = "mid",
		blurb = "+70% Pulverizer · +80% Fossil Finder", stats = { pulverize = 0.70, fossilFind = 0.80 } },
	{ id = "gatebreaker", name = "Gatebreaker Charm", source = "zone", rarity = "A", zoneId = "riftmarch", band = "deep",
		blurb = "+300% Mine Speed · +40% Swing Rate", stats = { mineSpeed = 3.00, swingRate = 0.40 } },

	{ id = "prism_nail", name = "Prism Nail", source = "zone", rarity = "C", zoneId = "mythral", band = "shallow",
		blurb = "+120% Luck · +80% Gem Find", stats = { luck = 1.20, gemFind = 0.80 } },
	{ id = "catacomb_key", name = "Catacomb Key", source = "zone", rarity = "C", zoneId = "mythral", band = "mid",
		blurb = "+100% Chest Luck · +100% Scrap", stats = { chestLuck = 1.00, scrap = 1.00 } },
	{ id = "aether_seal", name = "Aether Seal", source = "zone", rarity = "A", zoneId = "mythral", band = "deep",
		blurb = "+75% Omni Blast · +250% Mine Speed", stats = { blastChance = 0.75, mineSpeed = 2.50 } },

	--[[
		THE THIRTY-SIX GRADED CHARMS, 2026-10-07.

		Owner: "make 36 charms. make them all unique, and each come in their own
		rarity. they can be found in chests (0.5%) or bought with tokens", then the
		art for all thirty-six (`charms2.svg`, extracted to
		`build/charm-sheet2.png`). Every row is one icon: the picture came first and
		the name and stat line follow what it actually shows, which is why a lotus
		carries Luck and an anchor carries Chest Luck. `icon` is the sheet index, so
		the pairing survives a re-export.

		So, unlike every other charm in this file:

		  GRADED. Each row carries a `rarity` on MineTemper's F..SSS ladder rather
		  than a zone and a band. Magnitudes come from that grade, not from where
		  the charm was found: primary is about RARITY_MULT x 1.15, secondary about
		  x 0.35, which keeps an S charm meaningfully above a B without inventing a
		  second scale to maintain. The spread is 8/7/6/5/4/3/2/1 from F to SSS, so
		  the ladder thins the way the ore roster does.

		  TWO WAYS IN, neither of them a zone drop. A chest pays one at
		  CHARM_CHEST_CHANCE, and every charm has a token price. That is why there
		  is no `zoneId` or `band` here -- ZONE_BAND indexes on those, and a row
		  with both would also become a free zone grant by accident.

		  RARITY FOLLOWS THE ART. The grandest pictures take the top grades: the
		  galaxy in a locket is the one SSS, the winged blade and the hourglass are
		  the two SS. The humble ones -- a leaf, an acorn, a feather -- are F. A
		  player should be able to guess roughly what they found before reading it.

		`backpack` appears on none of them. It is retired (`MineStats` marks it
		`legacy = true`; capacity comes from the bag ladder and the pouch), though
		24 of the generated ore charms still carry it -- see open-questions #11.

		`luck` is fine here: the rule it would break -- no reward boosts its own
		acquisition -- bites on ore-case charms, where luck raises the case chance
		that pays the charm. A chest charm is not rolled off luck.
	]]

	-- F: humble things. One honest stat each.
	{ id = "greenleaf", name = "Greenleaf Charm", source = "charm", rarity = "F", icon = 4,
		art = "rbxassetid://92876185206702", -- a single green leaf on a gold stem
		blurb = "+52% Scrap", stats = { scrap = 0.52 } },
	{ id = "acorn_charm", name = "Acorn Charm", source = "charm", rarity = "F", icon = 27,
		art = "rbxassetid://100555623479933", -- an acorn with a green light inside it
		blurb = "+52% Mine Speed", stats = { mineSpeed = 0.52 } },
	{ id = "gilt_quill", name = "Gilt Quill", source = "charm", rarity = "F", icon = 20,
		art = "rbxassetid://133744953770197", -- a gold feather, a quill for counting takings
		blurb = "+52% Coin Bonus", stats = { coinBonus = 0.52 } },
	{ id = "silverplume", name = "Silverplume Charm", source = "charm", rarity = "F", icon = 32,
		art = "rbxassetid://87693502882956", -- a silver feather set with small violet gems
		blurb = "+18% Swing Rate", stats = { swingRate = 0.18 } },
	{ id = "runestone_tablet", name = "Runestone Tablet", source = "charm", rarity = "F", icon = 22,
		art = "rbxassetid://125991194910265", -- a carved stone tablet with blue gems at its ends
		blurb = "+52% Dirt Break", stats = { dirtBreak = 0.52 } },
	{ id = "anchor_charm", name = "Anchor Charm", source = "charm", rarity = "F", icon = 31,
		art = "rbxassetid://123782673754717", -- a bronze anchor on a teal disc
		blurb = "+52% Chest Luck", stats = { chestLuck = 0.52 } },
	{ id = "green_flask", name = "Green Flask", source = "charm", rarity = "F", icon = 33,
		art = "rbxassetid://118350563234345", -- a glass flask of bubbling green liquid
		blurb = "+30% Pulverizer", stats = { pulverize = 0.30 } },
	{ id = "wirewrap_shard", name = "Wirewrap Shard", source = "charm", rarity = "F", icon = 10,
		art = "rbxassetid://80537908381100", -- a purple shard bound in silver wire
		blurb = "+52% Gem Find", stats = { gemFind = 0.52 } },

	-- D: a second stat starts to appear.
	{ id = "darkmoon", name = "Darkmoon Charm", source = "charm", rarity = "D", icon = 5,
		art = "rbxassetid://77918516274651", -- a black crescent moon chased with violet
		blurb = "+80% Gem Find", stats = { gemFind = 0.80 } },
	{ id = "pearlmoon", name = "Pearlmoon Charm", source = "charm", rarity = "D", icon = 7,
		art = "rbxassetid://96590520795154", -- a silver filigree crescent cradling a pearl
		blurb = "+80% Chest Luck", stats = { chestLuck = 0.80 } },
	{ id = "wayfinder", name = "Wayfinder Compass", source = "charm", rarity = "D", icon = 8,
		art = "rbxassetid://93612266081022", -- a gold compass rose around a teal centre
		blurb = "+80% Mine Speed", stats = { mineSpeed = 0.80 } },
	{ id = "gilded_scarab", name = "Gilded Scarab", source = "charm", rarity = "D", icon = 6,
		art = "rbxassetid://131044491383735", -- a gold scarab on a coin-like disc
		blurb = "+80% Coin Bonus", stats = { coinBonus = 0.80 } },
	{ id = "emberrune", name = "Emberrune Stone", source = "charm", rarity = "D", icon = 16,
		art = "rbxassetid://113724525530167", -- a dark stone split by a burning orange rune
		blurb = "+80% Dirt Break · +25% Coin Bonus", stats = { dirtBreak = 0.80, coinBonus = 0.25 } },
	{ id = "cogwheel", name = "Cogwheel Charm", source = "charm", rarity = "D", icon = 24,
		art = "rbxassetid://102518470630814", -- a bronze gear turning inside a ring
		blurb = "+60% Mine Speed · +25% Swing Rate", stats = { mineSpeed = 0.60, swingRate = 0.25 } },
	{ id = "keenedge", name = "Keenedge Charm", source = "charm", rarity = "D", icon = 28,
		art = "rbxassetid://120837991541927", -- a silver rhombus plate honed to a point
		blurb = "+45% Pulverizer", stats = { pulverize = 0.45 } },

	-- C: the middle of the ladder, where a charm earns its slot.
	{ id = "sunface", name = "Sunface Medallion", source = "charm", rarity = "C", icon = 1,
		art = "rbxassetid://133396769823189", -- a gold sun disc with a face at its centre
		blurb = "+120% Coin Bonus", stats = { coinBonus = 1.20 } },
	{ id = "rimefall", name = "Rimefall Charm", source = "charm", rarity = "C", icon = 2,
		art = "rbxassetid://128223123383806", -- a silver snowflake set with a blue gem
		blurb = "+100% Pulverizer · +37% Dirt Break", stats = { pulverize = 1.00, dirtBreak = 0.37 } },
	{ id = "tidecaller", name = "Tidecaller Shell", source = "charm", rarity = "C", icon = 15,
		art = "rbxassetid://109020345612119", -- a blue scallop shell holding a teal gem and pearls
		blurb = "+120% Chest Luck", stats = { chestLuck = 1.20 } },
	{ id = "lotus_charm", name = "Lotus Charm", source = "charm", rarity = "C", icon = 17,
		art = "rbxassetid://111155701156001", -- a white lotus opened around a pearl
		blurb = "+120% Luck", stats = { luck = 1.20 } },
	{ id = "vivid_shard", name = "Vivid Shard", source = "charm", rarity = "C", icon = 23,
		art = "rbxassetid://112927184530004", -- a magenta crystal in a bright silver frame
		blurb = "+120% Gem Find · +37% Luck", stats = { gemFind = 1.20, luck = 0.37 } },
	{ id = "helmsman", name = "Helmsman Charm", source = "charm", rarity = "C", icon = 12,
		art = "rbxassetid://77444360783899", -- a copper ship's wheel on a watch case
		blurb = "+120% Mine Speed · +37% Scrap", stats = { mineSpeed = 1.20, scrap = 0.37 } },

	-- B: a clear specialism, and the first charms worth building around.
	{ id = "stormbolt", name = "Stormbolt Charm", source = "charm", rarity = "B", icon = 11,
		art = "rbxassetid://121481914621315", -- a white lightning bolt on a storm-blue disc
		blurb = "+178% Mine Speed · +54% Swing Rate", stats = { mineSpeed = 1.78, swingRate = 0.54 } },
	{ id = "heartfrost", name = "Heartfrost Charm", source = "charm", rarity = "B", icon = 21,
		art = "rbxassetid://103023219746855", -- an ice crystal with a fire burning inside it
		blurb = "+178% Dirt Break · +54% Pulverizer", stats = { dirtBreak = 1.78, pulverize = 0.54 } },
	{ id = "magma_ring", name = "Magma Ring", source = "charm", rarity = "B", icon = 29,
		art = "rbxassetid://105028895633143", -- a cracked black sphere with a molten ring through it
		blurb = "+178% Dirt Break · +65% Omni Blast", stats = { dirtBreak = 1.78, blastChance = 0.65 } },
	{ id = "coilfang", name = "Coilfang Charm", source = "charm", rarity = "B", icon = 13,
		art = "rbxassetid://126986534765173", -- a green serpent coiled back through itself
		blurb = "+178% Scrap · +54% Luck", stats = { scrap = 1.78, luck = 0.54 } },
	{ id = "scarabright", name = "Scarabright Charm", source = "charm", rarity = "B", icon = 35,
		art = "rbxassetid://104052421120518", -- a beetle shelled in iridescent green and blue
		blurb = "+178% Gem Find · +54% Coin Bonus", stats = { gemFind = 1.78, coinBonus = 0.54 } },

	-- A: one of these changes how a run feels.
	{ id = "thunderheart", name = "Thunderheart Amethyst", source = "charm", rarity = "A", icon = 26,
		art = "rbxassetid://115676544738828", -- a great amethyst with lightning caught inside
		blurb = "+265% Mine Speed · +80% Swing Rate", stats = { mineSpeed = 2.65, swingRate = 0.80 } },
	{ id = "thornset_ruby", name = "Thornset Ruby", source = "charm", rarity = "A", icon = 18,
		art = "rbxassetid://94133030814441", -- a red gem held in a crown of black thorns
		blurb = "+265% Dirt Break · +80% Omni Blast", stats = { dirtBreak = 2.65, blastChance = 0.80 } },
	{ id = "sovereign_heart", name = "Sovereign Heart", source = "charm", rarity = "A", icon = 9,
		art = "rbxassetid://133379738679371", -- a crowned gold heart around a red stone
		blurb = "+265% Coin Bonus · +80% Chest Luck", stats = { coinBonus = 2.65, chestLuck = 0.80 } },
	{ id = "northstar", name = "Northstar Diamond", source = "charm", rarity = "A", icon = 14,
		art = "rbxassetid://101191514110672", -- an eight-pointed gold star around a white diamond
		blurb = "+265% Luck · +80% Gem Find", stats = { luck = 2.65, gemFind = 0.80 } },

	-- S: three charms, each the best in the game at one thing.
	{ id = "prism_cluster", name = "Prism Cluster", source = "charm", rarity = "S", icon = 25,
		art = "rbxassetid://98345534847092", -- a cluster of crystal throwing every colour at once
		blurb = "+390% Gem Find · +119% Luck", stats = { gemFind = 3.90, luck = 1.19 } },
	{ id = "lionheart_crest", name = "Lionheart Crest", source = "charm", rarity = "S", icon = 34,
		art = "rbxassetid://91264778981667", -- a crowned red shield bearing a gold lion
		blurb = "+390% Dirt Break · +119% Coin Bonus", stats = { dirtBreak = 3.90, coinBonus = 1.19 } },
	{ id = "dragoneye", name = "Dragoneye Charm", source = "charm", rarity = "S", icon = 3,
		art = "rbxassetid://105995325088619", -- a scaled orb with a slit red eye that watches back
		blurb = "+390% Ore Finder · +119% Luck", stats = { fossilFind = 3.90, luck = 1.19 } },

	-- SS: two, and you will remember finding either.
	{ id = "seraph_edge", name = "Seraph Edge", source = "charm", rarity = "SS", icon = 30,
		art = "rbxassetid://131609907456467", -- a white wing folded around a blade of light
		blurb = "+575% Mine Speed · +175% Swing Rate", stats = { mineSpeed = 5.75, swingRate = 1.75 } },
	{ id = "hourglass_ages", name = "Hourglass of Ages", source = "charm", rarity = "SS", icon = 36,
		art = "rbxassetid://86200992977682", -- a gold hourglass running with violet starlight
		blurb = "+575% Chest Luck · +175% Coin Bonus", stats = { chestLuck = 5.75, coinBonus = 1.75 } },

	-- SSS: one charm. A galaxy, in a locket.
	{ id = "galaxy_core", name = "Galaxy Core", source = "charm", rarity = "SSS", icon = 19,
		art = "rbxassetid://136713205644319", -- a whole spiral galaxy turning behind gold glass
		blurb = "+860% Mine Speed · +260% Omni Blast", stats = { mineSpeed = 8.60, blastChance = 2.60 } },

	{ id = "jackhammer", name = "Jackhammer", source = "pack", rarity = "B",
		blurb = "+160% Dirt Break · +50% Swing Rate", stats = { dirtBreak = 1.60, swingRate = 0.50 } },
	{ id = "midas_touch", name = "Midas Touch", source = "pack", rarity = "B",
		blurb = "+200% Coin Bonus", stats = { coinBonus = 2.00 } },
	{ id = "piggybank", name = "Piggybank", source = "pack", rarity = "B",
		blurb = "+170% sell payout", stats = { coinBonus = 1.70 } },
	{ id = "cartwright", name = "Cartwright", source = "pack", rarity = "B",
		blurb = "+180% Backpack", stats = { backpack = 1.80 } },
	{ id = "night_shift", name = "Night Shift", source = "pack", rarity = "C",
		blurb = "+120% Chest Luck", stats = { chestLuck = 1.20 } },
	{ id = "seer", name = "Seer", source = "pack", rarity = "C",
		blurb = "+130% Luck", stats = { luck = 1.30 } },
	{ id = "smelter", name = "Smelter", source = "pack", rarity = "D",
		blurb = "+65% Pulverizer", stats = { pulverize = 0.65 } },
	{ id = "prospector", name = "Prospector", source = "pack", rarity = "B",
		blurb = "+200% Gem Find", stats = { gemFind = 2.00 } },
	{ id = "spindle", name = "Spindle", source = "pack", rarity = "A",
		blurb = "+100% Swing Rate", stats = { swingRate = 1.00 } },
	{ id = "striker", name = "Striker", source = "pack", rarity = "A",
		blurb = "+230% Mine Speed", stats = { mineSpeed = 2.30 } },
	{ id = "chainlink", name = "Chainlink", source = "pack", rarity = "C",
		blurb = "+60% Zap", stats = { zap = 0.60 } },
	{ id = "yardarm", name = "Yardarm", source = "pack", rarity = "C",
		blurb = "+100% Fossil Finder", stats = { fossilFind = 1.00 } },
	{ id = "scrappers_sign", name = "Scrapper's Sign", source = "pack", rarity = "C",
		blurb = "+120% Scrap", stats = { scrap = 1.20 } },
	{ id = "cubit_pin", name = "Cubit Pin", source = "pack", rarity = "C",
		blurb = "+50% Lucky Find", stats = { luckyFind = 0.50 } },
	{ id = "canopy", name = "Canopy", source = "pack", rarity = "B",
		blurb = "+55% Omni Blast", stats = { blastChance = 0.55 } },

	--[[
		Pot of Gold carries EVERY kind of luck.

		It was one stat -- pack luck -- on an item sold as the luck item. Chest
		odds, ore quality, ore quantity, gems and lucky blocks are all separate
		stats and it touched none of them.

		`luck` stays at 2. It is advertised at 200% on a limited item people
		paid for, and dropping it to 1.00 to make the row tidy would be a nerf
		to something already bought. Everything else lands at a full 100%.
	]]
	{ id = "lucky_charm", name = "Pot of Gold", source = "limited", rarity = "S",
		blurb = "200% Luck + 100% of every other luck. LIMITED TIME. NEVER COMING BACK.",
		stats = {
			luck = 2,            -- packs / cards
			chestLuck = 1.00,    -- chests
			rareOre = 1.00,      -- ore quality
			fossilFind = 1.00,   -- ore quantity (the ore finder)
			gemFind = 1.00,      -- gems
			luckyFind = 1.00,    -- lucky blocks
		} },
}

--[[
	A ZONE CHARM IS A FIND, NOT A DOOR PRIZE.

	It used to be handed over the first time you broke a block in the right
	band -- a 100% drop in every zone, which made five of the strongest items in
	the game a formality you walked into.

	It is a roll per qualifying block now. The exception is your FIRST charm:
	somebody who owns none gets the next one outright, because the early game is
	built around wearing one (the Sod Charm is most of why the second pickaxe
	one-shots dirt) and a new player should never be gated behind a 1-in-220 on
	their way to it.
]]
-- A roll PER BLOCK. 0.01% flat, set directly by the owner.
-- (1 in 220 before, which was a charm every twenty-odd seconds.)
MineCharms.ZONE_DROP_ONE_IN = 10000

function MineCharms.zoneDropChance(ownsAny)
	if not ownsAny then
		return 1
	end
	return 1 / math.max(1, MineCharms.ZONE_DROP_ONE_IN)
end

--[[
	THE GRADED CHARMS: two ways in, and neither is a zone.

	Owner, 2026-10-07: "they can be found in chests (0.5%) or bought with tokens".

	0.5% is per CHEST OPENED, not per block broken, and it is the chance that a
	chest pays a charm at all. Which charm is then a weighted draw over the
	rarity ladder, so the 0.5% is spent mostly on F and D and an SSS is 0.5% of
	2/10000 -- rare twice over, which is the point of a graded set.
]]
MineCharms.CHARM_CHEST_CHANCE = 0.005

-- Token prices climb with the grade, on MineTemper's F..SSS ladder. Priced off
-- MineTemper.CASE_PRICE_TOKENS = 20 as the unit a player already knows.
MineCharms.CHARM_TOKEN_PRICE = {
	F = 15, D = 30, C = 60, B = 120, A = 250, S = 500, SS = 1000, SSS = 2500,
}

--[[
	Grade to the word a player sees. Built by INVERTING MineTemper.LEGACY_RARITY
	rather than retyping the eight names, so the two cannot drift: the reveal
	panel and the temper UI call the same grade the same thing.
]]
MineCharms.RARITY_LABEL = {}
for word, grade in pairs(Temper.LEGACY_RARITY or {}) do
	MineCharms.RARITY_LABEL[grade] = word
end

--[[
	WHICH RARITY A CHEST CHARM IS (2026-10-19). Until now each graded charm
	weighed its grade's Temper.RARITY_WEIGHTS, so a grade's share grew with its
	count of charms. Every rarity has more charms now (NEW_GRADED), and adding
	them that way would have made a chest's charm rarer on average. So the grade
	is drawn first, at exactly the shares the 36 gave (count x weight: F 56.0%,
	D 27.1%, C 10.5%, B 4.7%, A 1.4%, S 0.21%, SS 0.028%, SSS 0.0028%), and the
	charm second, evenly among that grade's charms. "The same loot overall."
]]
MineCharms.CHEST_CHARM_GRADE_WEIGHT = {
	F = 8 * 5000, D = 7 * 2763, C = 6 * 1250, B = 5 * 675,
	A = 4 * 250, S = 3 * 50, SS = 2 * 10, SSS = 1 * 2,
}

-- The graded charms of one rarity, in LIST order.
function MineCharms.gradedOf(rarity)
	local out = {}
	for _, def in ipairs(MineCharms.GRADED or {}) do
		if def.rarity == rarity then
			table.insert(out, def)
		end
	end
	return out
end

--[[
	Which charm a chest pays: a grade by CHEST_CHARM_GRADE_WEIGHT, then one of
	that grade's charms, evenly.

	`rng` is passed in rather than taken from math.random so the server can seed
	it and a harness can make the draw repeatable. Returns nil when there are no
	graded charms, so a caller that forgets to check cannot hand out a nil id.
]]
function MineCharms.rollChestCharm(rng)
	local graded = MineCharms.GRADED
	if not graded or #graded == 0 then
		return nil
	end
	local odds = MineCharms.chestCharmOdds()
	local u = (rng and rng:NextNumber()) or math.random()
	local grade = odds[#odds] and odds[#odds].grade
	for _, row in ipairs(odds) do
		u -= row.p
		if u <= 0 then
			grade = row.grade
			break
		end
	end
	local pool = MineCharms.gradedOf(grade)
	if #pool == 0 then
		return graded[1]
	end
	local v = (rng and rng:NextNumber()) or math.random()
	return pool[math.clamp(math.floor(v * #pool) + 1, 1, #pool)]
end

-- What one graded charm costs in temper tokens, or nil if it is not graded.
function MineCharms.charmTokenPrice(idOrDef)
	local def = type(idOrDef) == "table" and idOrDef or MineCharms.byId(idOrDef)
	-- Graded rows only: the Halloween charms carry a grade too, but they are
	-- crafted from candy ore and never sold for tokens.
	if type(def) ~= "table" or not def.rarity or def.source ~= "charm" then
		return nil
	end
	return MineCharms.CHARM_TOKEN_PRICE[def.rarity]
end

--[[
	YOUR FIRST CHARM IS NEVER A ROLL, whichever source it comes from.

	An ore case pays a charm a quarter of the time and a skin the rest
	(MineConfig.ORE_CASE_CHARM_SHARE). For a player who owns none, that is three
	cases in four spent on the half of the build they cannot use yet -- and the
	first charm is the one that teaches what a charm IS.

	So it is guaranteed until you own one, which is the same rule the zone grant
	already applied and the same reason. It lives here rather than in the case
	branch so the two sources cannot drift: one place decides what "your first
	one" means.

	`ownsAny` is whether the player holds any charm at all. Pass the real answer:
	a nil here hands out a free charm to somebody who already has a shelf of them.
]]
function MineCharms.caseCharmShare(ownsAny, share)
	if not ownsAny then
		return 1
	end
	return math.clamp(tonumber(share) or 0.25, 0, 1)
end

-- Does this player hold any charm? One reader, because "do I own one" is asked
-- by both grant paths and a count of zero must not read as ownership.
function MineCharms.ownsAnyCharm(p)
	if type(p) ~= "table" or type(p.charms) ~= "table" then
		return false
	end
	for id, n in pairs(p.charms) do
		-- A legacy `true` counts, and so does any positive tally; a zero left
		-- behind by a removal does not.
		if n == true or (tonumber(n) or 0) > 0 then
			if MineCharms.byId(id) then
				return true
			end
		end
	end
	return false
end


--[[
	ONE CHARM PER ORE, ALL 82 -- AND NOT A LADDER OF ONE NUMBER.

	Charms are one of the two things a build is made of (the other is skins), so
	the roster has to cover the roster: every ore that can drop a case needs a
	charm behind it, or a case rolls a charm and finds nothing there.

	They are GENERATED rather than authored. 82 hand-written rows is 82 chances
	to leave one out, and the roster has been renumbered before -- it silently
	mis-pointed the tool ladder once already. Deriving them makes "one per ore" a
	property of the code instead of something to remember.

	WHAT THIS REPLACED, AND WHY
	---------------------------
	The first cut gave every charm one stat and one magnitude, ramped +100% at
	tier 1 to +320% at tier 82. That is the thing a charm must never be: tier 82
	strictly beat tier 41 of the same stat, so there was exactly one best charm
	per stat and 81 obsolete ones. "Higher number, better charm" is not a build.

	Later charms ARE better here -- budget still rises with tier. What changed is
	that budget is no longer always spent the same way, so a charm has a SHAPE as
	well as a size, and a shallow charm of the right shape beats a deep one of
	the wrong shape for a given build.

	THE FIVE SHAPES
	---------------
	Each spends the same tier budget differently. The multiplier on budget is the
	price of reliability -- a charm that asks for a condition, or takes something
	away, is allowed to pay more:

	  FOCUS      1.00x budget, one stat, always on.  The benchmark.
	  PAIR       1.15x split 60/40 over two stats.   Flexible, lower ceiling.
	  PACT       1.75x on one stat, MINUS ~0.55x on  Biggest always-on number
	             another.                            in the game, and it costs.
	  CONDITION  2.00x, but only while a condition    Build-defining when your
	             holds.                               build already holds it.
	  THRESHOLD  2.40x, and NOTHING until a gate is   Dead weight until it is
	             met.                                 not. Then enormous.

	A RAMP shape -- grows while something persists, resets when it breaks -- is
	the obvious sixth and is deliberately absent: it needs a counter on the
	profile and event hooks to feed it, which is plumbing rather than a table.
	See docs/TODO.md.

	WHY CONDITIONS CAN BE READ AT ALL
	---------------------------------
	`boosts(p)` is recomputed on every swing rather than cached, so a condition
	may read live state. Every condition here reads the PROFILE and nothing else,
	which is what keeps this honest: the server owns all of it, there is no new
	plumbing, and the same function serves the UI preview and the live boost.

	One condition, `skinned`, asks whether a skin is equipped. That is on purpose.
	Charms and skins are the two halves of a build, and a charm that pays more
	when the other half is present is the cheapest way to make them feel like
	halves of one thing rather than two parallel stat sources.

	NOT IN ANY POOL: echo (barred as a buff), zap and blastRadius (both pending a
	nerf). A generated table is the last place a stat under review should quietly
	pick up 82 new sources.
]]
-- Multiplicative stats. The budget is expressed as "+N% of what you had", which
-- only means one thing for these; the additive stats are fractions and are
-- handled separately where they appear.
local ORE_CHARM_STATS = {
	"mineSpeed", "dirtBreak", "coinBonus", "gemFind",
	"luck", "chestLuck", "backpack", "swingRate",
}

MineCharms.ORE_CHARM_MIN = 1.00
MineCharms.ORE_CHARM_MAX = 3.20

-- A PACT's cost, as a fraction of the stat it takes from. Bounded well under 1:
-- at -100% the stat is gone, and a cost that can erase a stat is not a trade.
local PACT_COST_MIN = 0.30
local PACT_COST_MAX = 0.60

-- Budget multiplier per shape. See the header for why they differ.
MineCharms.SHAPES = {
	{ id = "focus", label = "Focus", mult = 1.00 },
	{ id = "pair", label = "Pair", mult = 1.15 },
	{ id = "pact", label = "Pact", mult = 1.75 },
	{ id = "condition", label = "Condition", mult = 2.00 },
	{ id = "threshold", label = "Threshold", mult = 2.40 },
	{ id = "ramp", label = "Ramp", mult = 2.20 },
}

--[[
	THE RAMP. Builds while you keep mining, resets when you stop.

	Stacks come from BREAKING BLOCKS -- the thing a player does constantly -- and
	the payout is the budget times stacks/RAMP_MAX, so a ramp charm pays nothing
	cold and its full 2.20x only once you have been digging a while. It is the
	one shape that rewards a long uninterrupted session rather than a state you
	can set up and then sit in.

	WALL CLOCK, NOT os.clock(). The timestamp is persisted on the profile and
	read back after a rejoin, and os.clock() is process-relative -- the value
	saved by one server means nothing to the next. os.time() is comparable
	across both, so a stale stack correctly reads as expired instead of as
	freshly earned.
]]
MineCharms.RAMP_MAX = 60
MineCharms.RAMP_IDLE_SEC = 12

--[[
	How far up the ramp this player is, 0 to 1. READ ONLY -- it never mutates,
	because applyEquipped calls it and a boost calculation that changes state is
	a boost calculation that behaves differently depending on how often something
	happens to ask for it.

	Expiry is computed rather than stored: more than RAMP_IDLE_SEC since the last
	block and the ramp reads as cold, whether or not anything has got round to
	clearing it.
]]
function MineCharms.rampFraction(p)
	local ramp = type(p) == "table" and p.charmRamp or nil
	if type(ramp) ~= "table" then
		return 0
	end
	local n = math.max(0, math.floor(tonumber(ramp.n) or 0))
	if n <= 0 then
		return 0
	end
	local at = tonumber(ramp.at) or 0
	local now = os.time()
	-- A timestamp in the future is a clock that moved; treat it as cold rather
	-- than as an infinitely fresh stack.
	if at > now or (now - at) > MineCharms.RAMP_IDLE_SEC then
		return 0
	end
	return math.clamp(n / math.max(1, MineCharms.RAMP_MAX), 0, 1)
end

--[[
	One block broken. Call it on every break, equipped ramp charm or not: it is
	two field writes, and keeping the state coherent regardless means swapping
	onto a ramp charm does not inherit a stale ramp from whatever was on before.
]]
function MineCharms.bumpRamp(p)
	if type(p) ~= "table" then
		return
	end
	local now = os.time()
	local ramp = type(p.charmRamp) == "table" and p.charmRamp or nil
	local n = 0
	if ramp then
		local at = tonumber(ramp.at) or 0
		if at <= now and (now - at) <= MineCharms.RAMP_IDLE_SEC then
			n = math.max(0, math.floor(tonumber(ramp.n) or 0))
		end
	end
	p.charmRamp = { n = math.min(MineCharms.RAMP_MAX, n + 1), at = now }
end

--[[
	THE CONDITIONS. Each is a pure function of the profile, and each is
	REVOCABLE -- that is the part that took two attempts.

	The first set included "you have dug past 400m in this zone" and "you have
	rebirthed at least once". Both read a high-water mark, so both are PERMANENT
	once passed: a 2.0x or 2.4x budget that never switches off again is not a
	conditional charm, it is a strictly better charm with a sentence attached.
	Progress is what TIER already encodes; a condition has to be something you
	can lose, or it is not paying for the extra budget.

	So every condition below is a state the player moves in and out of while
	playing, and each one costs something real to hold:

	  pouch fullness   tension with selling -- hold the state or bank the haul,
	                   not both
	  pet count        tension with the pet pillar: a seat, or all of them, empty
	  skin / no skin   tension with the other half of the build
	  home zone        tension with where you want to be standing

	A backpack-fullness condition was tried and dropped: `p.backpack` is the
	bag-ownership TABLE, not a capacity, and the real capacity comes from a server
	local the shared module cannot reach. Both pack conditions would have silently
	never fired. Everything above reads state that the profile and the snapshot
	carry identically, which is what lets one function serve the live boost and
	the UI preview.

	CONDITION charms (2.00x) take the moderate windows. THRESHOLD charms (2.40x)
	take the NARROW ones -- a 90% pouch, a single pet, no skin at all -- so the
	larger budget is paid for with a window that is harder to sit inside, rather
	than with a gate that opens once.

	`test` returns true when the charm is paying. `blurb` says what the player has
	to do in the fewest words that are still unambiguous, because a conditional
	charm nobody can read is worse than no charm.
]]
local function pouchFrac(p)
	local okP, Pouch = pcall(function()
		return require(script.Parent:WaitForChild("MineOrePouch"))
	end)
	if not (okP and Pouch) then
		return 0
	end
	local cap = math.max(1, Pouch.capacity(p and p.orePouchTier))
	return math.clamp(Pouch.held(p and p.ores) / cap, 0, 1)
end

--[[
	The zone an ore calls home, by tier, spread evenly across the ladder.

	This is what the `homeZone` condition reads. It is derived rather than
	authored so it cannot fall out of step with the roster, and it only has to be
	approximately right: being a zone out changes which charm suits which trip,
	not whether the game works.
]]
local function homeZoneIndexFor(tier)
	local C = require(script.Parent:WaitForChild("MineConfig"))
	local zones = math.max(1, #(C.ZONES or {}))
	local count = math.max(1, tonumber(C.ORE_COUNT) or 82)
	local t = math.clamp(math.floor(tonumber(tier) or 1), 1, count)
	return math.clamp(math.ceil(t / count * zones), 1, zones)
end

local function wearingSkin(p)
	if type(p) ~= "table" then
		return false
	end
	-- Any of the places a skin can live: the tool family's, a chest tool's, or
	-- the legacy single field.
	for _, t in pairs(p.toolTempers or {}) do
		if t ~= nil and t ~= "" then
			return true
		end
	end
	for _, ct in ipairs(p.chestTools or {}) do
		if type(ct) == "table" and (ct.temperId or (ct.tempers and ct.tempers[1])) then
			return true
		end
	end
	return false
end

-- MODERATE windows, for CONDITION charms.
local CONDITIONS = {
	{
		id = "skinned",
		blurb = "while a SKIN is equipped",
		test = function(p) return wearingSkin(p) end,
	},
	{
		--[[
			Strongest in its own ore's home zone.

			Revocable by walking, which is the point: it makes a charm a reason to
			be somewhere rather than a number you set once. `def` is passed so the
			condition can read the charm's own tier -- it is the only one that
			needs to know which charm is asking.
		]]
		id = "homeZone",
		blurb = "while you are in its ore's home zone",
		test = function(p, def)
			if type(p) ~= "table" or type(def) ~= "table" then
				return false
			end
			local C = require(script.Parent:WaitForChild("MineConfig"))
			local here = C.zoneIndex and C.zoneIndex(p.zoneId) or 1
			return here == homeZoneIndexFor(def.tier)
		end,
	},
	{
		id = "hoard",
		blurb = "while your ore pouch is over half full",
		test = function(p) return pouchFrac(p) > 0.5 end,
	},
	{
		id = "lean",
		blurb = "while you have 2 pets out or fewer",
		test = function(p)
			return type(p) == "table" and #(p.equipped or {}) <= 2
		end,
	},
}

-- NARROW windows, for THRESHOLD charms. Same kinds of state, harder to hold.
local THRESHOLDS = {
	{
		id = "brimming",
		blurb = "while your ore pouch is over 90% full",
		test = function(p) return pouchFrac(p) > 0.9 end,
	},
	{
		-- The whole pet pillar, given up. The narrowest window there is, and the
		-- largest payoff for sitting inside it.
		id = "noPets",
		blurb = "while you have NO pets out",
		test = function(p)
			return type(p) == "table" and #(p.equipped or {}) == 0
		end,
	},
	{
		id = "soloPet",
		blurb = "while exactly ONE pet is out",
		test = function(p)
			return type(p) == "table" and #(p.equipped or {}) == 1
		end,
	},
	{
		id = "bare",
		blurb = "while NO skin is equipped",
		test = function(p) return not wearingSkin(p) end,
	},
}

MineCharms.CONDITIONS = {}
for _, cond in ipairs(CONDITIONS) do
	MineCharms.CONDITIONS[cond.id] = cond
end
for _, cond in ipairs(THRESHOLDS) do
	MineCharms.CONDITIONS[cond.id] = cond
end

-- Is this charm paying right now? True for anything unconditional, so a caller
-- can ask without checking the shape first.
function MineCharms.conditionMet(def, p)
	if type(def) ~= "table" or not def.condition then
		return true
	end
	local cond = MineCharms.CONDITIONS[def.condition]
	if not cond then
		return true
	end
	local ok, res = pcall(cond.test, p, def)
	return ok and res == true
end

local STAT_LABEL = {
	mineSpeed = "Mine Speed", dirtBreak = "Dirt Break", coinBonus = "Coin Bonus",
	gemFind = "Gem Find", luck = "Luck", chestLuck = "Chest Luck",
	backpack = "Backpack", swingRate = "Swing Rate", pulverize = "Pulverizer",
	scrap = "Scrap", fossilFind = "Ore Finder", blastChance = "Omni Blast",
	luckyFind = "Lucky Find",
	-- The Halloween charms' two (2026-10-19). Candy Find multiplies the candy a
	-- block or Crypt chest pays (MineCrypt reads boosts().candyFind); Event
	-- Digging multiplies an EVENT tool's power wherever it is swung (MineCryptRules
	-- reads it off the worn charm). Neither touches a normal tool.
	candyFind = "Candy Find", eventDig = "Event Digging",
}

MineCharms.STAT_LABEL = STAT_LABEL

-- "+52% Luck · +16% Scrap", largest first, from a stats table.
local function statLine(stats)
	local rows = {}
	for stat, amt in pairs(stats or {}) do
		table.insert(rows, { stat = stat, amt = tonumber(amt) or 0 })
	end
	table.sort(rows, function(a, b)
		if math.abs(a.amt) ~= math.abs(b.amt) then
			return math.abs(a.amt) > math.abs(b.amt)
		end
		return a.stat < b.stat
	end)
	local bits = {}
	for _, r in ipairs(rows) do
		local pct = math.floor(math.abs(r.amt) * 100 + 0.5)
		table.insert(bits, string.format("%s%d%% %s", (r.amt < 0) and "−" or "+", pct, STAT_LABEL[r.stat] or r.stat))
	end
	return table.concat(bits, " · ")
end
MineCharms.statLine = statLine

--[[
	MORE CHARMS AT EVERY RARITY (owner, 2026-10-19: "more charm types at every
	rarity"; Common and Uncommon charms exist too). Four more of each, so every
	rarity has a real pool for its Charm Pack and the chest roll: F 12, D 11,
	C 10, B 9, A 8, S 7, SS 6, SSS 5 graded charms in all.

	They follow the 36's rule -- the primary is about RARITY_MULT x 1.15, the
	secondary about x 0.35 (Swing Rate x 0.40, Omni Blast and Lucky Find on
	their own smaller scales) -- so no new charm out-peaks its rarity. None
	carries Gem Find, Ore Quality or Ore Finder: the gems hold their value
	(owner: "make sure gems semi maintain the same ish value"), so no new charm
	is a new gem faucet.

	No art yet (`art` nil, the Inventory's generic charm icon): the pictures are
	tools/cursor/tasks/chest-and-charm-icons.md. Names, stats and rarities are
	PROPOSED (2026-10-19). The blurb is written from the stats, so it cannot
	drift from them.
]]
MineCharms.NEW_GRADED = {
	-- F: humble things
	{ id = "clover_sprig", name = "Clover Sprig", rarity = "F", look = "a three-leaf clover on a tin ring", stats = { luck = 0.52 } },
	{ id = "lucky_penny", name = "Lucky Penny", rarity = "F", look = "a shiny copper penny on a string", stats = { luckyFind = 0.22 } },
	{ id = "firecracker_charm", name = "Firecracker Charm", rarity = "F", look = "a tiny red firecracker with a gold fuse", stats = { blastChance = 0.20 } },
	{ id = "pebble_pal", name = "Pebble Pal", rarity = "F", look = "a round grey pebble with a painted smile", stats = { mineSpeed = 0.26, dirtBreak = 0.26 } },
	-- D
	{ id = "four_leaf", name = "Four-Leaf Clover", rarity = "D", look = "a bright four-leaf clover in clear resin", stats = { luck = 0.80 } },
	{ id = "horseshoe_charm", name = "Horseshoe Charm", rarity = "D", look = "a silver horseshoe with gold nails", stats = { luckyFind = 0.35, chestLuck = 0.25 } },
	{ id = "cherry_bomb", name = "Cherry Bomb", rarity = "D", look = "two red cherry-shaped bombs on one stem", stats = { blastChance = 0.30, dirtBreak = 0.25 } },
	{ id = "tin_soldier", name = "Tin Soldier", rarity = "D", look = "a toy tin soldier with a drum", stats = { swingRate = 0.28, coinBonus = 0.25 } },
	-- C
	{ id = "rocket_fin", name = "Rocket Fin", rarity = "C", look = "a red rocket fin with a white stripe", stats = { swingRate = 0.42, mineSpeed = 0.37 } },
	{ id = "treasure_map", name = "Treasure Map", rarity = "C", look = "a rolled map with a red X and a gold ribbon", stats = { luckyFind = 0.52, chestLuck = 0.37 } },
	{ id = "thunder_egg", name = "Thunder Egg", rarity = "C", look = "a cracked stone egg with a lightning geode inside", stats = { blastChance = 0.45, dirtBreak = 0.37 } },
	{ id = "honeycomb_charm", name = "Honeycomb Charm", rarity = "C", look = "a golden honeycomb dripping honey", stats = { dirtBreak = 1.20, coinBonus = 0.37 } },
	-- B
	{ id = "comet_tail", name = "Comet Tail", rarity = "B", look = "a blue comet with a long sparkling tail", stats = { mineSpeed = 1.78, chestLuck = 0.54 } },
	{ id = "clockwork_heart", name = "Clockwork Heart", rarity = "B", look = "a brass heart full of turning gears", stats = { swingRate = 0.62, dirtBreak = 0.54 } },
	{ id = "coin_fountain", name = "Coin Fountain", rarity = "B", look = "a tiny fountain spilling gold coins", stats = { coinBonus = 1.78, luck = 0.54 } },
	{ id = "lantern_fish", name = "Lantern Fish", rarity = "B", look = "a deep-sea fish with a glowing lure", stats = { chestLuck = 1.78, scrap = 0.54 } },
	-- A
	{ id = "phoenix_feather", name = "Phoenix Feather", rarity = "A", look = "a fiery orange feather with flame tips", stats = { blastChance = 0.95, mineSpeed = 0.80 } },
	{ id = "wizard_monocle", name = "Wizard's Monocle", rarity = "A", look = "a star-etched monocle on a purple chain", stats = { luck = 2.65, chestLuck = 0.80 } },
	{ id = "kraken_tooth", name = "Kraken Tooth", rarity = "A", look = "a curved sea-green tooth wrapped in rope", stats = { dirtBreak = 2.65, swingRate = 0.80 } },
	{ id = "golden_goose", name = "Golden Goose Egg", rarity = "A", look = "a shining golden egg in a little nest", stats = { coinBonus = 2.65, luckyFind = 0.80 } },
	-- S
	{ id = "storm_crown", name = "Storm Crown", rarity = "S", look = "a silver crown crackling with lightning", stats = { mineSpeed = 3.90, swingRate = 1.19 } },
	{ id = "meteor_core", name = "Meteor Core", rarity = "S", look = "a glowing red meteor in a cage of iron", stats = { blastChance = 1.40, dirtBreak = 1.19 } },
	{ id = "moonstone_key", name = "Moonstone Key", rarity = "S", look = "a pale moonstone key that glows blue", stats = { chestLuck = 3.90, luckyFind = 1.19 } },
	{ id = "unicorn_horn", name = "Unicorn Horn", rarity = "S", look = "a spiral pearl horn with rainbow glints", stats = { luck = 3.90, coinBonus = 1.19 } },
	-- SS
	{ id = "world_seed", name = "World Seed", rarity = "SS", look = "a glowing seed with tiny roots and leaves", stats = { dirtBreak = 5.75, scrap = 1.75 } },
	{ id = "halo_ring", name = "Halo Ring", rarity = "SS", look = "a floating golden halo with white wings", stats = { luck = 5.75, chestLuck = 1.75 } },
	{ id = "supernova_shard", name = "Supernova Shard", rarity = "SS", look = "a crystal shard bursting with star light", stats = { blastChance = 2.00, mineSpeed = 1.75 } },
	{ id = "golden_gauntlet", name = "Golden Gauntlet", rarity = "SS", look = "a golden glove set with six bright gems", stats = { coinBonus = 5.75, luckyFind = 1.75 } },
	-- SSS
	{ id = "black_hole_heart", name = "Black Hole Heart", rarity = "SSS", look = "a swirling black hole inside a gold ring", stats = { dirtBreak = 8.60, chestLuck = 2.60 } },
	{ id = "sunheart_crown", name = "Sunheart Crown", rarity = "SSS", look = "a blazing sun set in a golden crown", stats = { coinBonus = 8.60, luck = 2.60 } },
	{ id = "dragon_pearl", name = "Rainbow Dragon Pearl", rarity = "SSS", look = "a rainbow pearl held in a dragon's claw", stats = { luck = 8.60, luckyFind = 2.60 } },
	{ id = "big_bang_bell", name = "Big Bang Bell", rarity = "SSS", look = "a cosmic bell that rings with exploding stars", stats = { blastChance = 3.00, mineSpeed = 2.60 } },
}
for _, r in ipairs(MineCharms.NEW_GRADED) do
	table.insert(LIST, {
		id = r.id,
		name = r.name,
		source = "charm",
		rarity = r.rarity,
		look = r.look,
		stats = r.stats,
		blurb = statLine(r.stats),
	})
end

--[[
	THE SIX HALLOWEEN CHARMS. Owner, 2026-10-19: "a new set of 6 Halloween
	charms, crafted at the Forge from candy ores (deeper ore, better charm);
	candy find, event digging and a small normal stat; the same power
	everywhere."

	CRAFTED, NOT DROPPED. Source "candy": no zone grant, no chest roll, no token
	price and no merge -- each is made from N of ONE candy ore (`recipe`), with
	MineCrypt's `cryptCraftCharm` verb. The recipe is on the row, so the Forge
	and the server read the same cost.

	ON THE GRADED LADDER, D to SS, one grade per charm, deeper ore higher. The
	numbers are not typed: each stat is MineTemper.RARITY_MULT for the grade
	times a share (CANDY_CHARM_SHARE), the same "magnitude follows the grade"
	rule the graded 36 use. So a D charm is +56% Candy Find, +42% Event
	Digging and +10% of its normal stat, and the SS one +400%, +300% and +75%.

	THE SAME POWER EVERYWHERE: nothing here is scaled by where you stand. Candy
	Find only has candy to act on in the Crypt, Event Digging only has event
	tools, and the normal stat (a different one per charm) works anywhere --
	small on purpose, so wearing one in the main world costs you the slot.

	NO ICONS YET (`art` nil): the Inventory falls back to the generic charm
	icon. The six pictures are owed.

	PROPOSED (2026-10-19): the names, which ores, the grades, the three shares
	and the recipe counts.
]]
MineCharms.CANDY_CHARM_SHARE = { candyFind = 0.80, eventDig = 0.60, normal = 0.15 }
MineCharms.CANDY_CHARMS = {
	{ id = "hallow_kernel", name = "Candy Corn Kernel", rarity = "D", oreId = "candy_corn", count = 25, normal = "coinBonus" },
	{ id = "hallow_wisp", name = "Cotton Candy Wisp", rarity = "C", oreId = "cotton_candy", count = 30, normal = "swingRate" },
	{ id = "hallow_fizz", name = "Pop Rocks Fizz", rarity = "B", oreId = "pop_rocks", count = 35, normal = "dirtBreak" },
	{ id = "hallow_lantern", name = "Rock Candy Lantern", rarity = "A", oreId = "rock_candy", count = 40, normal = "chestLuck" },
	{ id = "hallow_moon", name = "White Chocolate Moon", rarity = "S", oreId = "white_chocolate", count = 50, normal = "gemFind" },
	{ id = "hallow_skull", name = "Jawbreaker Skull", rarity = "SS", oreId = "jawbreaker", count = 60, normal = "mineSpeed" },
}
do
	local mult = Temper.RARITY_MULT or {}
	local share = MineCharms.CANDY_CHARM_SHARE
	local function hundredth(x)
		return math.floor(x * 100 + 1e-9) / 100
	end
	local function pct(x)
		return math.floor(x * 100 + 1e-9)
	end
	for _, r in ipairs(MineCharms.CANDY_CHARMS) do
		local m = tonumber(mult[r.rarity]) or 1
		local candy = hundredth(m * share.candyFind)
		local dig = hundredth(m * share.eventDig)
		local normal = hundredth(m * share.normal)
		table.insert(LIST, {
			id = r.id,
			name = r.name,
			source = "candy",
			rarity = r.rarity,
			holiday = "halloween",
			recipe = { oreId = r.oreId, count = r.count },
			stats = { candyFind = candy, eventDig = dig, [r.normal] = normal },
			blurb = string.format("+%d%% Candy Find · +%d%% Event Digging · +%d%% %s",
				pct(candy), pct(dig), pct(normal), STAT_LABEL[r.normal] or r.normal),
		})
	end
end

--[[
	THE CANDY CRYPT'S CHEST CHARMS, one per Crypt chest rank (owner, 2026-10-19:
	"each Crypt chest tier has its own special charm, mergeable, 0.5% flat per
	charm, raised by Chest Luck"). The Crypt (MineCrypt) rolls the 0.5% and
	grants through the ordinary charm tally; this module only says WHICH charm a
	rank's chest pays: MineCharms.cryptChestCharm(rankKey).

	Each charm's rarity IS its chest's rank, fixed forever, and it merges I to V
	like every charm. Stats follow the six Halloween charms' rule (RARITY_MULT x
	CANDY_CHARM_SHARE: Candy Find, Event Digging and a small normal stat), so a
	Crypt charm and a crafted one of the same rarity are worth the same.

	Source "crypt": not graded (no Charm Pack, no chest roll in the main game, no
	token price), not a zone grant. Names and normal stats PROPOSED (2026-10-19);
	no art yet (tools/cursor/tasks/chest-and-charm-icons.md).
]]
MineCharms.CRYPT_CHEST_CHARMS = {
	{ rank = "F", id = "hallow_wrapper", name = "Candy Wrapper Charm", normal = "coinBonus", look = "a twisted orange-and-black candy wrapper" },
	{ rank = "D", id = "hallow_batwing", name = "Bat Wing Charm", normal = "scrap", look = "a little purple bat wing on a silver loop" },
	{ rank = "C", id = "hallow_catbell", name = "Black Cat Bell", normal = "luck", look = "a black cat's collar bell with green eyes" },
	{ rank = "B", id = "hallow_broom", name = "Witch's Broom Charm", normal = "dirtBreak", look = "a tiny witch's broom with a starry ribbon" },
	{ rank = "A", id = "hallow_spidersilk", name = "Spider Silk Locket", normal = "chestLuck", look = "a locket wrapped in shining spider silk" },
	{ rank = "S", id = "hallow_pumpkincrown", name = "Pumpkin King Crown", normal = "swingRate", look = "a carved pumpkin crown with a candle glow" },
	{ rank = "SS", id = "hallow_ravenfeather", name = "Raven Moon Feather", normal = "luckyFind", look = "a black raven feather under a full moon" },
	{ rank = "SSS", id = "hallow_cryptkey", name = "Crypt Keeper's Key", normal = "mineSpeed", look = "an old bone-white key with a glowing purple gem" },
}
do
	local mult = Temper.RARITY_MULT or {}
	local share = MineCharms.CANDY_CHARM_SHARE
	local function hundredth(x)
		return math.floor(x * 100 + 1e-9) / 100
	end
	for _, r in ipairs(MineCharms.CRYPT_CHEST_CHARMS) do
		local m = tonumber(mult[r.rank]) or 1
		local stats = {
			candyFind = hundredth(m * share.candyFind),
			eventDig = hundredth(m * share.eventDig),
			[r.normal] = hundredth(m * share.normal),
		}
		table.insert(LIST, {
			id = r.id,
			name = r.name,
			source = "crypt",
			rarity = r.rank,
			holiday = "halloween",
			look = r.look,
			stats = stats,
			blurb = statLine(stats),
		})
	end
end

-- The charm special to a Candy Crypt chest of `rankKey` ("F".."SSS"): its id,
-- or nil for a rank that is not one. (The cross-agent contract, 2026-10-19.)
function MineCharms.cryptChestCharm(rankKey)
	for _, r in ipairs(MineCharms.CRYPT_CHEST_CHARMS) do
		if r.rank == rankKey then
			return r.id
		end
	end
	return nil
end

--[[
	TWO CHARMS PER ORE, 164 in all, and each ore's pair are different KINDS of
	thing rather than a weaker and a stronger copy.

	Variant 1 keeps the id `<ore>_charm` it has always had, so a save holding one
	still resolves. Variant 2 is `<ore>_charm_2`.

	WHY A PAIR AND NOT A LADDER. The two variants of one ore are guaranteed to
	differ in both SHAPE and primary STAT, so neither is an upgrade of the other
	-- picking between Stone Focus and Stone Twin is a question about your build,
	not about which number is larger. If they shared a shape and a stat the second
	would just be the first again at a different size, which is the ladder this
	whole design exists to avoid.

	THE NAME CARRIES THE SHAPE: "<Ore> <Word> Charm", where the word is the shape
	in charm language (Focus, Twin, Pact, Ward, Brink, Surge). Every one of the
	164 names is therefore distinct by construction, and a player can tell what a
	charm DOES from its name before reading the blurb.

	THE INDEXING, which is the whole trick:

	  slot k    = (tier - 1) * 2 + (variant - 1)     0..163, one per charm
	  shape     = k mod 6
	  stat      = (k + k/6) mod 8
	  condition = (k + k/48) mod 4

	Consecutive k differ by one, so an ore's two variants always land on
	different shapes and different stats -- that is where the pair guarantee
	comes from rather than from a check.

	Each divisor term breaks a lockstep. Without `k/6` the (shape, stat) pair
	would cycle every LCM(6,8) = 24; without `k/48` the condition would ride the
	same 48-slot cycle as (shape, stat) and the signature count would sit at 48.
	With both, 86 of the 96 possible (shape, stat, condition) signatures are
	used across the 164 charms -- verified by tools/verify/charms.js.
]]
-- The shape, in charm language. "Stone Condition Charm" reads like a bug report;
-- "Stone Ward Charm" reads like an item.
MineCharms.SHAPE_WORD = {
	focus = "Focus",
	pair = "Twin",
	pact = "Pact",
	condition = "Ward",
	threshold = "Brink",
	ramp = "Surge",
}

MineCharms.ORE_CHARM_VARIANTS = 2

--[[
	The charm id for an ore, by variant. One function, so the server and the UI
	cannot disagree about what an ore's charms are called.

	Variant 1 deliberately has NO suffix: that is the id that already exists in
	saves, and changing it would orphan every charm anyone owns.
]]
function MineCharms.oreCharmId(oreId, variant)
	local v = math.max(1, math.floor(tonumber(variant) or 1))
	local base = tostring(oreId or "") .. "_charm"
	if v <= 1 then
		return base
	end
	return base .. "_" .. v
end

do
	local C = require(script.Parent:WaitForChild("MineConfig"))
	local ores = C.ORES or {}
	local span = math.max(1, (C.ORE_COUNT or #ores) - 1)
	local lo, hi = MineCharms.ORE_CHARM_MIN, MineCharms.ORE_CHARM_MAX
	local shapes = MineCharms.SHAPES
	local variants = MineCharms.ORE_CHARM_VARIANTS
	local function pct(x)
		return math.floor(x * 100 + 1e-9)
	end
	for i, ore in ipairs(ores) do
		local tier = tonumber(ore.tier) or i
		local t = math.clamp((tier - 1) / span, 0, 1)
		for variant = 1, variants do
			-- One slot per charm across the whole roster. See the header.
			local k = (tier - 1) * variants + (variant - 1)
			local shape = shapes[(k % #shapes) + 1]
			local statStep = k + math.floor(k / #shapes)
			local primary = ORE_CHARM_STATS[(statStep % #ORE_CHARM_STATS) + 1]
			-- Budget, floored to a hundredth so the number read is the number
			-- applied. Both variants of an ore share the tier budget; only how
			-- it is SPENT differs.
			local budget = math.floor((lo + (hi - lo) * t) * shape.mult * 100 + 1e-9) / 100

			local stats, blurb, condition = {}, nil, nil

			if shape.id == "pair" then
				-- Six along, not adjacent: neighbours in the pool are
				-- near-synonyms (luck / chestLuck), and pairing those reads as
				-- one stat written twice.
				local second = ORE_CHARM_STATS[((statStep + 5) % #ORE_CHARM_STATS) + 1]
				local a = math.floor(budget * 0.60 * 100 + 1e-9) / 100
				local b2 = math.floor(budget * 0.40 * 100 + 1e-9) / 100
				stats[primary] = a
				stats[second] = b2
				blurb = string.format("+%d%% %s · +%d%% %s",
					pct(a), STAT_LABEL[primary] or primary,
					pct(b2), STAT_LABEL[second] or second)
			elseif shape.id == "pact" then
				local cost = ORE_CHARM_STATS[((statStep + 3) % #ORE_CHARM_STATS) + 1]
				local give = math.floor(budget * 100 + 1e-9) / 100
				--[[
					THE COST IS BOUNDED, and it has to be. It was a fraction of
					the BUDGET, which meant it scaled with the upside: -96% of a
					stat at tier 1 and -308% at tier 82. A multiplicative penalty
					past -100% is not a steep cost, it is a broken number -- the
					stat is gone at -100% and there is nothing left to take.

					A fraction of the STAT instead, -30% at tier 1 to -60% at the
					deepest: the cost still grows with the upside, stays readable,
					and can never erase a stat.
				]]
				local take = math.min(PACT_COST_MAX,
					PACT_COST_MIN + (PACT_COST_MAX - PACT_COST_MIN) * t)
				take = math.floor(take * 100 + 1e-9) / 100
				stats[primary] = give
				stats[cost] = -take
				blurb = string.format("+%d%% %s · −%d%% %s",
					pct(give), STAT_LABEL[primary] or primary,
					pct(take), STAT_LABEL[cost] or cost)
			elseif shape.id == "condition" or shape.id == "threshold" then
				-- A CONDITION takes a moderate window, a THRESHOLD a narrow one.
				-- That is what the threshold's larger budget buys: a window that
				-- is harder to sit inside, not a gate that opens once.
				local pool = (shape.id == "threshold") and THRESHOLDS or CONDITIONS
				-- The /48 term stops the condition riding the same cycle as
				-- (shape, stat); see the header.
				local cond = pool[((k + math.floor(k / 48)) % #pool) + 1]
				condition = cond.id
				stats[primary] = budget
				blurb = string.format("+%d%% %s %s",
					pct(budget), STAT_LABEL[primary] or primary, cond.blurb)
			elseif shape.id == "ramp" then
				-- Authored at FULL value; applyEquipped scales it by how far up
				-- the ramp the player is, so the number on the card is what it
				-- pays at the top rather than an average nobody ever sees.
				stats[primary] = budget
				blurb = string.format("+%d%% %s at full stacks · builds as you mine, resets if you stop",
					pct(budget), STAT_LABEL[primary] or primary)
			else
				stats[primary] = budget
				blurb = string.format("+%d%% %s", pct(budget), STAT_LABEL[primary] or primary)
			end

			local word = MineCharms.SHAPE_WORD[shape.id] or shape.label or "Charm"
			-- ONE RARITY FOREVER (owner, 2026-10-19): an ore charm's is its
			-- ore's band, Common F .. Exotic SSS, the ladder the ores already
			-- print (MineConfig.ORE_YIELD_BANDS).
			local GRADE_BY_BAND = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
			local rarity = GRADE_BY_BAND[tonumber(ore.bandIndex) or 0]
				or (Temper.LEGACY_RARITY and Temper.LEGACY_RARITY[ore.band]) or "F"
			table.insert(LIST, {
				id = MineCharms.oreCharmId(ore.id, variant),
				name = string.format("%s %s Charm", ore.name or ore.id, word),
				source = "ore",
				rarity = rarity,
				oreId = ore.id,
				variant = variant,
				tier = tier,
				band = ore.band,
				-- Carried as well as the name so a reader can order or ink by
				-- rarity without a second lookup into the roster.
				bandIndex = ore.bandIndex,
				shape = shape.id,
				shapeLabel = shape.label,
				condition = condition,
				blurb = blurb,
				stats = stats,
			})
		end
	end
end

MineCharms.LIST = LIST
MineCharms.PACK_PRICE_GEMS = 2500

local BY_ID = {}
local ZONE_BAND = {}
local PACK = {}
local BY_ORE = {}
local GRADED = {}
for _, def in ipairs(LIST) do
	BY_ID[def.id] = def
	if def.source == "charm" then
		-- Graded charms: chest or token, never a zone grant. Kept in LIST order so
		-- the drawn six stay first and the roll is reproducible from a seed.
		table.insert(GRADED, def)
	elseif def.source == "zone" and def.zoneId and def.band then
		ZONE_BAND[def.zoneId .. "|" .. def.band] = def
	elseif def.source == "pack" then
		table.insert(PACK, def)
	elseif def.source == "ore" and def.oreId then
		-- An ore has SEVERAL charms now, so this is a list per ore rather than a
		-- single entry. Keyed by variant so the order cannot depend on the order
		-- LIST happens to be walked in.
		local key = tostring(def.oreId)
		BY_ORE[key] = BY_ORE[key] or {}
		BY_ORE[key][math.max(1, math.floor(tonumber(def.variant) or 1))] = def
	end
end

MineCharms.GRADED = GRADED

function MineCharms.byId(id)
	return BY_ID[tostring(id or "")]
end

-- The six Halloween charms, in grade order (CANDY_CHARMS). Each def carries
-- `recipe = { oreId, count }`: the candy ore and how many craft one.
function MineCharms.candyCharms()
	local out = {}
	for _, r in ipairs(MineCharms.CANDY_CHARMS or {}) do
		local def = BY_ID[r.id]
		if def then
			table.insert(out, def)
		end
	end
	return out
end

-- A craftable charm's recipe, or nil for every other charm.
function MineCharms.recipeFor(charmId)
	local def = BY_ID[tostring(charmId or "")]
	if def and def.source == "candy" and type(def.recipe) == "table" then
		return def.recipe
	end
	return nil
end

--[[
	ONE RARITY FOREVER, AND A TIER, I TO V (owner, 2026-10-19).

	"each charm has its own rarity always. {sod charm rare always}" and "f-sss
	charms (same system as packs)": every charm in LIST carries one `rarity`,
	F..SSS on MineTemper's ladder, and nothing ever changes it -- no grade is
	rolled when a charm drops. The 36 graded charms kept theirs; the zone and
	pack charms and Pot of Gold were given one by their power against that
	ladder (the Sod Charm is Rare, C); an ore charm's is its ore's band.

	"teir i to v": what a merge raises is the charm's TIER. A copy starts at I;
	merging it costs gems plus ANY one charm at the same tier, which is used up,
	and the copy comes out a tier higher. Merging never changes rarity. Tier V
	is the top.

	THE SAVE. `p.charms[id]` stays the count of copies at every tier (so every
	grant -- the zone roll, the ore case, a chest, a trader, the Crypt -- keeps
	adding a tier-I copy the way it always did), and `p.charmTiers[id]` holds
	how many of them sit at II..V, keyed "II".."V". Tier I is the rest. A worn
	charm (`p.equippedCharm`, an id) is always its best copy.

	THE TIER EFFECT multiplies every stat by TIER_MULT -- except Gem Find, Ore
	Quality and Ore Finder (TIER_FLAT), the three that pay gems straight out of
	a chest or an ore. Merging must never print gems (owner: "make sure gems
	semi maintain the same ish value"), so those three stay at their tier-I
	value. tools/verify/economy-gems.js checks it. A pact's cost (a negative
	stat) stays too: it is bounded under -100% on purpose.

	PROPOSED (2026-10-19): TIER_MULT, TIER_FLAT, MERGE_GEMS, MERGE_TIER_STEP.
]]
MineCharms.TIER_MAX = 5
MineCharms.TIER_ROMAN = { "I", "II", "III", "IV", "V" }
MineCharms.TIER_MULT = { 1.00, 1.20, 1.45, 1.75, 2.10 }
MineCharms.TIER_FLAT = { gemFind = true, rareOre = true, fossilFind = true }

--[[
	The gem price of one merge, by the charm's rarity and the tier it reaches:
	MERGE_GEMS[rarity] to reach II, then x MERGE_TIER_STEP for every tier above.
	All the way to V is 40x the first step: F 20k, B 240k, SSS 10M.
]]
MineCharms.MERGE_GEMS = {
	F = 500, D = 1000, C = 2500, B = 6000, A = 15000, S = 40000, SS = 100000, SSS = 250000,
}
MineCharms.MERGE_TIER_STEP = 3

-- Charms used up by a merge besides the one being raised: one, of the same tier.
MineCharms.MERGE_COST = 1

function MineCharms.romanTier(tier)
	return MineCharms.TIER_ROMAN[math.clamp(math.floor(tonumber(tier) or 1), 1, MineCharms.TIER_MAX)]
end

-- The gem price of raising a charm of `rarityOrDef` to `toTier` (2..5), or nil.
function MineCharms.mergeGemCost(rarityOrDef, toTier)
	local rarity = type(rarityOrDef) == "table" and rarityOrDef.rarity or rarityOrDef
	local base = MineCharms.MERGE_GEMS[rarity or ""]
	local t = math.floor(tonumber(toTier) or 0)
	if not base or t < 2 or t > MineCharms.TIER_MAX then
		return nil
	end
	return math.floor(base * MineCharms.MERGE_TIER_STEP ^ (t - 2) + 0.5)
end

local TIER_KEY = { [2] = "II", [3] = "III", [4] = "IV", [5] = "V" }

local function held(p, id)
	local n = type(p) == "table" and type(p.charms) == "table" and p.charms[id]
	if n == true then
		return 1
	end
	return math.max(0, math.floor(tonumber(n) or 0))
end

--[[
	How many copies of `id` this player holds at each tier: { [1]..[5] }, and
	the total. Reads the save defensively: if something took copies away
	without touching charmTiers, the lowest high tiers give way first, so the
	best copies are the ones kept.
]]
function MineCharms.tierCounts(p, id)
	id = tostring(id or "")
	local total = held(p, id)
	local counts = { 0, 0, 0, 0, 0 }
	local row = type(p) == "table" and type(p.charmTiers) == "table" and p.charmTiers[id] or nil
	local high = 0
	for t = 2, MineCharms.TIER_MAX do
		local n = math.max(0, math.floor(tonumber(type(row) == "table" and row[TIER_KEY[t]]) or 0))
		counts[t] = n
		high += n
	end
	local over = high - total
	for t = 2, MineCharms.TIER_MAX do
		if over <= 0 then
			break
		end
		local cut = math.min(over, counts[t])
		counts[t] -= cut
		over -= cut
	end
	local sum = 0
	for t = 2, MineCharms.TIER_MAX do
		sum += counts[t]
	end
	counts[1] = math.max(0, total - sum)
	return counts, total
end

-- Write counts { [1]..[5] } back into the save for `id`.
local function storeCounts(p, id, counts)
	p.charms = p.charms or {}
	p.charmTiers = p.charmTiers or {}
	local total, row = 0, {}
	for t = 1, MineCharms.TIER_MAX do
		total += counts[t] or 0
		if t >= 2 and (counts[t] or 0) > 0 then
			row[TIER_KEY[t]] = counts[t]
		end
	end
	p.charms[id] = (total > 0) and total or nil
	p.charmTiers[id] = next(row) and row or nil
end

--[[
	On load: the tier save is a table, no row names a charm the tally does not
	hold, and no charm claims more high-tier copies than it has (tierCounts
	trims the lowest high tiers first, keeping the best).
]]
function MineCharms.normalizeTiers(p)
	if type(p) ~= "table" then
		return
	end
	p.charms = type(p.charms) == "table" and p.charms or {}
	p.charmTiers = type(p.charmTiers) == "table" and p.charmTiers or {}
	local ids = {}
	for id in pairs(p.charmTiers) do
		table.insert(ids, id)
	end
	for _, id in ipairs(ids) do
		local row = p.charmTiers[id]
		if type(row) ~= "table" or not MineCharms.byId(id) or not p.charms[id] then
			p.charmTiers[id] = nil
		else
			local counts = MineCharms.tierCounts(p, id)
			local fixed = {}
			for t = 2, MineCharms.TIER_MAX do
				if counts[t] > 0 then
					fixed[TIER_KEY[t]] = counts[t]
				end
			end
			p.charmTiers[id] = next(fixed) and fixed or nil
		end
	end
end

-- The best tier this player holds `id` at, 0 if none.
function MineCharms.bestTier(p, id)
	local counts = MineCharms.tierCounts(p, id)
	for t = MineCharms.TIER_MAX, 1, -1 do
		if counts[t] > 0 then
			return t
		end
	end
	return 0
end

-- The tier the worn charm is at (its best copy), or 1.
function MineCharms.wornTier(p)
	local id = type(p) == "table" and p.equippedCharm
	if type(id) ~= "string" or id == "" then
		return 1
	end
	return math.max(1, MineCharms.bestTier(p, id))
end

-- A charm's stats at `tier` (TIER_FLAT stats stay as they are at I).
function MineCharms.statsAt(def, tier)
	local out = {}
	local m = MineCharms.TIER_MULT[math.clamp(math.floor(tonumber(tier) or 1), 1, MineCharms.TIER_MAX)] or 1
	for stat, amt in pairs((type(def) == "table" and def.stats) or {}) do
		local v = tonumber(amt) or 0
		-- Only a gift grows. A pact's cost (a negative) stays as it is at I: it is
		-- bounded under -100% on purpose, and a tier must not erase a stat.
		if m ~= 1 and v > 0 and not MineCharms.TIER_FLAT[stat] then
			v = math.floor(v * m * 100 + 0.5) / 100
		end
		out[stat] = v
	end
	return out
end

-- One stat of the worn charm at its tier, as a fraction (0.42 = +42%), or 0.
-- For readers that cannot go through boosts() (MineCryptRules.eventDigOf).
function MineCharms.wornStat(p, stat)
	local id = type(p) == "table" and p.equippedCharm
	local def = (type(id) == "string" and id ~= "") and MineCharms.byId(id) or nil
	if not def then
		return 0
	end
	return tonumber(MineCharms.statsAt(def, MineCharms.wornTier(p))[stat]) or 0
end

--[[
	What merging this charm at `tier` makes: the same charm, a tier up. Returns
	(id, def, nil), or (nil, nil, reason) -- a sentence a player can read, the
	same one the server says.
]]
function MineCharms.mergeTarget(charmId, tier)
	local def = MineCharms.byId(charmId)
	if not def then
		return nil, nil, "That charm is not in the game"
	end
	local t = math.max(1, math.floor(tonumber(tier) or 1))
	if t >= MineCharms.TIER_MAX then
		return nil, nil, "Tier V is the top"
	end
	return def.id, def, nil
end

--[[
	Can this player merge their copy of `id` at `tier`, using up one `fodderId`
	at the same tier? Returns (true, nil, gemCost) or (false, reason).
	Pure: reads the profile, changes nothing.
]]
function MineCharms.canMerge(p, id, tier, fodderId)
	local def = MineCharms.byId(id)
	local fdef = MineCharms.byId(fodderId)
	tier = math.floor(tonumber(tier) or 0)
	if not def or not fdef then
		return false, "That charm is not in the game"
	end
	if tier < 1 or tier >= MineCharms.TIER_MAX then
		return false, (tier >= MineCharms.TIER_MAX) and "Tier V is the top" or "Pick a tier to merge"
	end
	local counts = MineCharms.tierCounts(p, def.id)
	if counts[tier] < 1 then
		return false, "You have no " .. def.name .. " at tier " .. MineCharms.romanTier(tier)
	end
	local fcounts = MineCharms.tierCounts(p, fdef.id)
	local need = (fdef.id == def.id) and 2 or 1
	if fcounts[tier] < need then
		return false, "Merging needs another charm at tier " .. MineCharms.romanTier(tier)
	end
	-- The worn copy is the best one; it can be raised (two copies of the worn
	-- charm make it a tier better), never used up to raise another charm.
	if fdef.id ~= def.id and p.equippedCharm == fdef.id
		and MineCharms.bestTier(p, fdef.id) == tier and fcounts[tier] <= 1 then
		return false, "That's the charm you're wearing -- take it off to use it up"
	end
	local cost = MineCharms.mergeGemCost(def.rarity, tier + 1)
	if not cost then
		return false, "That charm has no rarity"
	end
	if math.floor(tonumber(p.gems) or 0) < cost then
		return false, string.format("Needs %d gems to merge", cost), cost
	end
	return true, nil, cost
end

--[[
	Do the merge: gems out, the fodder used up, the charm a tier up. All or
	nothing, after canMerge. Returns (true, { cost, toTier }) or (false, reason).
	If the fodder was the last copy of a worn charm, nothing is worn after.
]]
function MineCharms.applyMerge(p, id, tier, fodderId)
	local ok, why, cost = MineCharms.canMerge(p, id, tier, fodderId)
	if not ok then
		return false, why
	end
	tier = math.floor(tonumber(tier) or 1)
	local def, fdef = MineCharms.byId(id), MineCharms.byId(fodderId)
	p.gems = math.floor(tonumber(p.gems) or 0) - cost
	-- The fodder first: when it is the same charm, both edits land on one row.
	local fcounts = MineCharms.tierCounts(p, fdef.id)
	fcounts[tier] -= 1
	storeCounts(p, fdef.id, fcounts)
	local counts = MineCharms.tierCounts(p, def.id)
	counts[tier] -= 1
	counts[tier + 1] += 1
	storeCounts(p, def.id, counts)
	if p.equippedCharm == fdef.id and not (p.charms and p.charms[fdef.id]) then
		p.equippedCharm = nil
	end
	return true, { cost = cost, toTier = tier + 1, id = def.id, fodderId = fdef.id }
end

--[[
	The charms this player could use up to merge `id` at `tier`: every charm
	held at that tier, the cheapest (lowest rarity) first, never the worn copy.
	{ { id, def, count } }.
]]
function MineCharms.fodderFor(p, id, tier)
	local out = {}
	tier = math.floor(tonumber(tier) or 1)
	for cid in pairs((type(p) == "table" and p.charms) or {}) do
		local d = MineCharms.byId(cid)
		if d then
			local counts = MineCharms.tierCounts(p, cid)
			local n = counts[tier] - ((cid == id) and 1 or 0)
			if cid ~= id and p.equippedCharm == cid and MineCharms.bestTier(p, cid) == tier then
				n -= 1
			end
			if n > 0 then
				table.insert(out, { id = cid, def = d, count = n })
			end
		end
	end
	table.sort(out, function(a, b)
		local ra = table.find(Temper.GRADE_ORDER, a.def.rarity) or 0
		local rb = table.find(Temper.GRADE_ORDER, b.def.rarity) or 0
		if ra ~= rb then
			return ra < rb
		end
		return a.def.name < b.def.name
	end)
	return out
end

--[[
	The charms an ore pays. Every ore has MineCharms.ORE_CHARM_VARIANTS of them,
	and these are the only ways to ask: a caller that builds the id by hand goes
	quietly nil the day the suffix changes.

	`oreCharms` returns the whole list, variant-indexed. `oreCharm(id)` returns
	one -- variant 1 by default, so every existing caller keeps working and keeps
	meaning what it meant.

	(Until 2026-10-19 an ore charm merged into the next ore's charm, a trade of
	shape for depth. Merging raises the tier now, and the rarity never moves.)
]]

function MineCharms.oreCharms(oreId)
	return BY_ORE[tostring(oreId or "")] or {}
end

function MineCharms.oreCharm(oreId, variant)
	local list = MineCharms.oreCharms(oreId)
	return list[math.max(1, math.floor(tonumber(variant) or 1))]
end

--[[
	One of an ore's charms, picked at random. This is what an ore case rolls.

	Uniform across the variants on purpose: they are different KINDS, not tiers,
	so weighting one would quietly make the other the consolation prize -- which
	is the ladder this design exists to avoid. Falls back to whatever the ore has
	if a variant is somehow missing, so a case can never pay nothing.
]]
function MineCharms.rollOreCharm(oreId, rng)
	local list = MineCharms.oreCharms(oreId)
	local pool = {}
	for _, def in pairs(list) do
		table.insert(pool, def)
	end
	if #pool == 0 then
		return nil
	end
	if #pool == 1 then
		return pool[1]
	end
	rng = rng or Random.new()
	return pool[rng:NextInteger(1, #pool)]
end

function MineCharms.zoneBandCharm(zoneId, band)
	return ZONE_BAND[tostring(zoneId or "") .. "|" .. tostring(band or "")]
end

function MineCharms.packPool()
	return PACK
end

local ADDITIVE = {
	echo = true, zap = true, blastRadius = true, autoMine = true, blastChance = true,
	luckyFind = true, fossilFind = true, pulverize = true, scrap = true,
	coolant = true, shortFuse = true, reach = true,
}

--[[
	Apply the equipped charm.

	`p` is the profile, and it is what makes a CONDITION charm possible: the
	condition is a pure function of the profile, and boosts() is recomputed every
	swing rather than cached, so the charm turns on and off live. Passing no
	profile applies only the unconditional charms -- which is the right answer for
	a caller that has no player, and never silently grants a conditional bonus.

	A NEGATIVE amount is a real reduction, not a floor at zero. That is the whole
	point of a PACT charm: the biggest always-on number in the game, paid for with
	something. Clamping it away here would make pacts free, so the clamp is only
	the one that keeps a multiplicative stat from going negative outright
	(0.05 floor) -- a stat at or below zero stops being a multiplier and starts
	being a bug.
]]
function MineCharms.applyEquipped(b, charmId, p)
	local def = MineCharms.byId(charmId)
	if not def or not b or type(def.stats) ~= "table" then
		return
	end
	-- A conditional charm pays nothing while its condition is unmet.
	if def.condition and not MineCharms.conditionMet(def, p) then
		return
	end
	--[[
		A RAMP charm's stats are authored at full value and scaled by how far up
		the ramp the player is. Cold, that is zero, and the charm pays nothing --
		which is the shape working, not a bug.
	]]
	local scale = 1
	if def.shape == "ramp" then
		scale = MineCharms.rampFraction(p)
		if scale <= 0 then
			return
		end
	end
	-- The worn copy's tier (I..V): every stat but TIER_FLAT grows with it.
	local tier = (type(p) == "table" and p.equippedCharm == def.id) and MineCharms.wornTier(p) or 1
	for stat, amount in pairs(MineCharms.statsAt(def, tier)) do
		amount = (tonumber(amount) or 0) * scale
		if amount == 0 then
			-- skip
		elseif stat == "swingRate" then
			-- A negative here LENGTHENS the swing, which is the intended cost.
			b.swingSec = (b.swingSec or 1) / math.max(0.05, 1 + amount)
		elseif ADDITIVE[stat] then
			b[stat] = math.max(0, (b[stat] or 0) + amount)
		else
			b[stat] = math.max(0.05, (b[stat] or 1) + amount)
		end
	end
end

--[[
	The charm's line, with its shape and whether it is live.

	`p` is optional. With it, a conditional charm says whether it is paying right
	now, because "+240% Mine Speed while a SKIN is equipped" and the same charm
	doing nothing look identical otherwise, and that is the single most confusing
	thing a conditional bonus can do.
]]
function MineCharms.describe(def, p, tier)
	if not def then
		return ""
	end
	-- At a tier above I the numbers are the tier's (statsAt), written fresh.
	local t = math.floor(tonumber(tier) or 1)
	local line = def.blurb or def.name or ""
	if t > 1 and type(def.stats) == "table" then
		line = statLine(MineCharms.statsAt(def, t))
		local cond = def.condition and MineCharms.CONDITIONS[def.condition]
		if cond then
			line = line .. " " .. cond.blurb
		elseif def.shape == "ramp" then
			line = line .. " at full stacks"
		end
	end
	if def.shapeLabel then
		line = line .. "  ·  " .. def.shapeLabel
	end
	if def.condition and p ~= nil then
		line = line .. (MineCharms.conditionMet(def, p) and "  ·  ACTIVE" or "  ·  inactive")
	end
	-- A ramp says where it is, because "builds as you mine" is not an answer to
	-- "what is it giving me right now".
	if def.shape == "ramp" and p ~= nil then
		line = line .. string.format("  ·  %d%% charged",
			math.floor(MineCharms.rampFraction(p) * 100 + 0.5))
	end
	return line
end

-- The Charms Pack's draw for one player: every pack charm they do not own yet.
-- One function, so the roll and the odds below cannot disagree.
local function packPoolFor(ownedSet)
	local pool = {}
	for _, def in ipairs(PACK) do
		if not (ownedSet and ownedSet[def.id]) then
			table.insert(pool, def)
		end
	end
	return pool
end

function MineCharms.rollPack(ownedSet, rng)
	rng = rng or Random.new()
	local pool = packPoolFor(ownedSet)
	if #pool == 0 then
		return nil
	end
	return pool[rng:NextInteger(1, #pool)]
end

--[[
	THE CHARMS PACK'S ODDS (owner, 2026-10-19, launch audit M3: the pack costs
	gems, which trace back to Robux, so it shows its odds before you pay). A
	uniform draw over the pack charms this player does not own yet, exactly as
	rollPack draws: { { id, name, blurb, p } }, empty when there is nothing left.
]]
function MineCharms.packOdds(ownedSet)
	local pool = packPoolFor(ownedSet)
	local out = {}
	for _, def in ipairs(pool) do
		table.insert(out, { id = def.id, name = def.name, blurb = def.blurb, p = 1 / #pool })
	end
	return out
end

--[[
	The chest charm ladder by grade, as rollChestCharm draws it (a grade at its
	CHEST_CHARM_GRADE_WEIGHT share, then one of its `n` charms evenly):
	{ { grade, p, n } }, in grade order. The wandering trader's Charm Case pays
	from this ladder, so its odds sheet reads it (MineTrader.caseOdds, launch
	audit M3).
]]
function MineCharms.chestCharmOdds()
	local total, out = 0, {}
	for _, g in ipairs(Temper.GRADE_ORDER or { "F", "D", "C", "B", "A", "S", "SS", "SSS" }) do
		local n = #MineCharms.gradedOf(g)
		local w = (n > 0) and math.max(0, tonumber(MineCharms.CHEST_CHARM_GRADE_WEIGHT[g]) or 0) or 0
		if w > 0 then
			total += w
			table.insert(out, { grade = g, p = w, n = n })
		end
	end
	if total <= 0 then
		local graded = MineCharms.GRADED or {}
		if graded[1] then
			return { { grade = graded[1].rarity, p = 1, n = 1 } }
		end
		return {}
	end
	for _, row in ipairs(out) do
		row.p /= total
	end
	return out
end

--[[
	THE EIGHT CHARM PACKS (owner, 2026-10-19: "charm packs for the main game,
	one per chest rarity ("{rarity} Charm Pack")", "all 8 rarities get charms and
	packs", sold "for gems or credits").

	A pack is one charm of its rarity, drawn evenly from that rarity's graded
	charms (gradedOf: F 12 .. SSS 5), always at tier I. charmPackOdds is the
	draw, so the odds sheet and the roll cannot disagree; it is the same for
	every player (owning a charm already is fine: a copy is merge fodder).

	GEMS ARE THE SINK. A pack pays a charm and nothing else, and a charm never
	turns back into gems, so every gem spent here leaves the game. The prices
	climb about 3x a rarity, and tools/verify/economy-gems.js prices each in
	minutes of gem income at the stage that rarity belongs to.

	CREDITS are Robux-bought, so a credit (or gem) buy is a paid random item:
	Verbs.PAID_RANDOM covers the verb, and the shelf shows the odds first.

	Every price PROPOSED (2026-10-19). The old gem Charms Pack (15 legacy pack
	charms, PACK_PRICE_GEMS) is off the shelf: these replace it (PROPOSAL §0
	line 33, "keep the items, kill the three sources").
]]
MineCharms.CHARM_PACKS = {
	{ id = "charm_pack_f", rarity = "F", gems = 2500, credits = 10 },
	{ id = "charm_pack_d", rarity = "D", gems = 7500, credits = 15 },
	{ id = "charm_pack_c", rarity = "C", gems = 20000, credits = 25 },
	{ id = "charm_pack_b", rarity = "B", gems = 60000, credits = 45 },
	{ id = "charm_pack_a", rarity = "A", gems = 175000, credits = 80 },
	{ id = "charm_pack_s", rarity = "S", gems = 500000, credits = 150 },
	{ id = "charm_pack_ss", rarity = "SS", gems = 1500000, credits = 280 },
	{ id = "charm_pack_sss", rarity = "SSS", gems = 5000000, credits = 500 },
}
for _, row in ipairs(MineCharms.CHARM_PACKS) do
	row.name = row.rarity .. " Charm Pack"
	row.word = MineCharms.RARITY_LABEL[row.rarity] or row.rarity
end

-- A Charm Pack row by its id or its rarity, or nil.
function MineCharms.charmPack(idOrRarity)
	for _, row in ipairs(MineCharms.CHARM_PACKS) do
		if row.id == idOrRarity or row.rarity == idOrRarity then
			return row
		end
	end
	return nil
end

-- What one Charm Pack of `rarity` can pay: { { id, name, blurb, p } }.
function MineCharms.charmPackOdds(rarity)
	local pool = MineCharms.gradedOf(rarity)
	local out = {}
	for _, def in ipairs(pool) do
		table.insert(out, { id = def.id, name = def.name, blurb = def.blurb, p = 1 / #pool })
	end
	return out
end

function MineCharms.rollCharmPack(rarity, rng)
	local pool = MineCharms.gradedOf(rarity)
	if #pool == 0 then
		return nil
	end
	local v = (rng and rng:NextNumber()) or math.random()
	return pool[math.clamp(math.floor(v * #pool) + 1, 1, #pool)]
end

return MineCharms
