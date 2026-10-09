--[[
	MineQuests -- objective ladder, lifetime milestones, and contractor jobs.

	CHAIN: one-at-a-time ladder (~50 rungs). Progress is measured FROM WHEN the
	quest becomes active (server baselines via questBase).

	MILESTONES: lifetime / claimable any time once the absolute threshold is hit.
	Not gated by the chain index.

	CONTRACTS: rotating Job Board jobs (3 slots). Same UTC-day boundary as
	dailies so "the day rolled" means one thing.

	LOCKED skill-token economy (MineSkillData — do not invent a second faucet):
	MineSkillData.tokensFor(n) = 2 + floor((n-1)/2)
	TEMPER_ROLL_COST = 10 (flat), UNUSED_SKILL_POINT_SELL = 30
]]

local MineQuests = {}

--[[
	EVERY CHAIN GOAL IS MEASURED FROM WHEN THE QUEST BECOMES ACTIVE.

	No credits on the ladder — battle pass is where credits come from.
]]
MineQuests.CHAIN = {
	-- Early (session 1)
	{ id = "mine25",     stat = "blocks",   goal = 10,      text = "Break 10 blocks",              tip = "Hold LMB on a rock. Dig fills your bag.", reward = { coins = 200, pack = "loam_pack" } }, -- id kept: CHAIN_V1 names it
	{ id = "sell1",      stat = "sells",    goal = 1,       text = "Sell your haul at the Depot",  tip = "Sell pad by the shops. Gems/coins bank; bag empties.", reward = { coins = 400 } },
	{ id = "pick2",      stat = "picktier", goal = 1,       text = "Buy a better pickaxe",         tip = "Blacksmith. Coin tools reset on rebirth; socketed runes stay.", reward = { gems = 20 } },
	{ id = "mine100",    stat = "blocks",   goal = 100,     text = "Break 100 blocks",             tip = "Chests hide in the wall — dig deeper for better odds.", reward = { gems = 25 } },
	{ id = "chests3",    stat = "chests",   goal = 3,       text = "Open 3 chests",                tip = "Chests glow — when the dirt lights up, one is close.", reward = { gems = 60, tool = "meadow_surface_2_pick", toolName = "Bronzewedge" } },
	{ id = "depth20",    stat = "depth",    goal = 20,      text = "Gain 20 depth",                tip = "Depth unlocks harder rock and richer chests.", reward = { coins = 800 } },
	{ id = "chestsL2",   stat = "chestsL2", goal = 3,       text = "Open 3 chests below 50m (Layer 2+)", tip = "Layer 2 starts 51m down — your depth shows on the HUD.", reward = { gems = 100, tool = "meadow_surface_3_pick", toolName = "Irongrasp" } },
	{ id = "mine250",    stat = "blocks",   goal = 250,     text = "Break 250 blocks",             tip = "Packs come from chests. Cards power every swing.", reward = { pack = "clay_pack" } },
	{ id = "open3",      stat = "packs",    goal = 3,       text = "Open 3 packs",                 tip = "Open packs from your bag. Variants and shinies are permanent.", reward = { gems = 40 } },
	{ id = "chestsL3",   stat = "chestsL3", goal = 3,       text = "Open 3 chests below 100m (Layer 3+)", tip = "Deeper layers hide better chests.", reward = { gems = 150, tool = "meadow_surface_4_pick", toolName = "Coppervine" } },
	{ id = "cards10",    stat = "cards",    goal = 10,      text = "Collect 10 more cards",        tip = "Equip pets in slots. More slots unlock as you grow.", reward = { pack = "slate_pack" } },
	{ id = "sell5",      stat = "sells",    goal = 5,       text = "Sell 5 hauls",                 tip = "Coins buy tools. Gems buy zones, runes, and gear.", reward = { gems = 45 } },
	--[[
		THE FORGE, FINALLY ON THE LADDER.

		This rung is placed here because it is the first point a player HAS
		what it needs: they have mined (mine250), sold (sell5), and therefore
		banked ore in the pouch. Earlier and it asks for ore nobody has; much
		later and they have spent an hour not knowing the game's main system
		exists.
	]]
	{ id = "forge1",     stat = "oretools", goal = 1,       text = "Forge a tool out of ore",      tip = "The Forge turns ore into a tool. Every ore makes its own pickaxe, drill and charge -- 246 in all.", reward = { gems = 60 } },
	{ id = "chests10",   stat = "chests",   goal = 10,      text = "Open 10 chests",               tip = "Every tool has a rune slot — runes stay in it through rebirth.", reward = { gems = 200, tool = "meadow_surface_5_pick", toolName = "Ironvine" } },
	{ id = "zone2",      stat = "zone",     goal = 1,       text = "Unlock the next zone",         tip = "Buy portals with gems. Zones stay unlocked after rebirth.", reward = { gems = 80 } },
	{ id = "chestsL4",   stat = "chestsL4", goal = 5,       text = "Open 5 chests below 150m (Layer 4+)", tip = "Chest luck from pets, runes and skills stacks.", reward = { gems = 300, tool = "meadow_surface_6_pick", toolName = "Hillforge" } },
	-- Mid
	{ id = "mine1k",     stat = "blocks",   goal = 1000,    text = "Break 1,000 blocks",           tip = "Upgrade pick + backpack so hauls pay for the next rebirth bank.", reward = { gems = 120 } },
	{ id = "depth80",    stat = "depth",    goal = 80,      text = "Gain 80 depth",                tip = "Later layers drop better chest ranks.", reward = { gems = 100 } },
	{ id = "merge1",     stat = "merges",   goal = 1,       text = "Merge three of a kind",        tip = "Three matching cards merge into one stronger card.", reward = { pack = "iron_pack", packQty = 2 } },
	{ id = "open10",     stat = "packs",    goal = 10,      text = "Open 10 packs",                tip = "Summon tab: Runes 25g, Gear 75g.", reward = { gems = 150 } },
	{ id = "chestsL5",   stat = "chestsL5", goal = 5,       text = "Open 5 chests below 200m (Layer 5+)", tip = "Drills bore straight down — built for depth runs.", reward = { gems = 400, tool = "meadow_surface_8_drill", toolName = "Twistauger" } },
	{ id = "cards50",    stat = "cards",    goal = 50,      text = "Collect 50 more cards",        tip = "Power-up cards with stardust — power survives rebirth.", reward = { gems = 180 } },
	{ id = "sell25",     stat = "sells",    goal = 25,      text = "Sell 25 hauls",                tip = "Watch the Rebirth tab: farm to the MINIMUM bank, not just the fee.", reward = { gems = 220 } },
	{ id = "gear3",      stat = "gear",     goal = 3,       text = "Summon 3 gear pieces",         tip = "Equip gear by slot. Matching sets add bonuses.", reward = { gems = 140 } },
	-- Charms drop from chests at 0.5% and are also bought with temper tokens,
	-- so by this rung a player has almost certainly seen one and not known
	-- what it was for.
	{ id = "charm1",     stat = "charms",   goal = 1,       text = "Get a charm",                  tip = "One charm equips at a time, and it does not take a rune or pet slot. Chests drop them; the token shop sells them.", reward = { gems = 110 } },
	{ id = "chests25",   stat = "chests",   goal = 25,      text = "Open 25 chests",               tip = "Bombs clear a whole patch at once.", reward = { gems = 500, tool = "meadow_surface_10_bomb", toolName = "Clayfuse" } },
	{ id = "rune5",      stat = "runes",    goal = 5,       text = "Summon 5 runes",               tip = "Socket runes on tools, pets, and gear. They keep through rebirth.", reward = { pack = "slate_pack" } },
	--[[
		SKINS AND TRAITS, THE TWO LEAST-TAUGHT SYSTEMS IN THE GAME.

		Skins (temperaments) are fitted PER FAMILY and were invisible on the
		ladder; traits are rolled per forged tool and were mentioned exactly
		zero times across 62 rungs. Both sit after rune5 on purpose -- a
		player who has socketed a rune already understands "a thing that goes
		on a tool", so these read as more of a known idea rather than a new
		one.
	]]
	{ id = "skin1",      stat = "skins",    goal = 1,       text = "Fit a skin to a tool family",  tip = "Skins are per FAMILY, not per tool -- fit one and every pickaxe you forge wears it. Ore cases drop them.", reward = { gems = 160 } },
	{ id = "trait1",     stat = "traits",   goal = 1,       text = "Roll a trait on a forged tool", tip = "A trait is rolled onto one tool and re-rolling replaces it. 500 gems a go.", reward = { gems = 200 } },
	{ id = "zone3",      stat = "zone",     goal = 2,       text = "Unlock two more zones",        tip = "Higher zones need Rebirth rank + gems. Check the portal plaque.", reward = { pack = "night_pack", packQty = 2 } },
	{ id = "chestsL6",   stat = "chestsL6", goal = 10,      text = "Open 10 chests below 250m (Layer 6+)", tip = "Greyvein tools hit harder — this one is on the house.", reward = { gems = 800, tool = "sunscar_surface_2_pick", toolName = "Chiselspike" } },
	{ id = "mine3k",     stat = "blocks",   goal = 3000,    text = "Break 3,000 blocks",           tip = "Fuse runes at 50% success — no pity. White scrolls raise cost ×5.", reward = { gems = 64 } },
	{ id = "merge8",     stat = "merges",   goal = 8,       text = "Merge 8 times",                tip = "Merge before rebirth if you are close — cards keep.", reward = { gems = 40 } },
	{ id = "depth200",   stat = "depth",    goal = 200,     text = "Gain 200 depth",               tip = "Depth resets each rebirth. Zones do not.", reward = { gems = 56 } },
	{ id = "cards100",   stat = "cards",    goal = 100,     text = "Collect 100 more cards",       tip = "Pets + socketed pet runes stack into dig power.", reward = { pack = "iron_pack", packQty = 3 } },
	{ id = "pick5",      stat = "picktier", goal = 4,       text = "Climb 4 pickaxe tiers",        tip = "Coin ladder resets on rebirth. Don't overspend past the min bank.", reward = { gems = 72 } },
	{ id = "rebirth1",   stat = "rebirth",  goal = 1,       text = "Rebirth once",                 tip = "Rebirth at the MINIMUM coin bank. Skills + temper tokens are the prize.", reward = { gems = 400 } },
	-- Late mid
	{ id = "mine10k",    stat = "blocks",   goal = 10000,   text = "Break 10,000 blocks",          tip = "Spend skill points in the Clouds after each rebirth.", reward = { gems = 120 } },
	{ id = "sell80",     stat = "sells",    goal = 80,      text = "Sell 80 hauls",                tip = "Each rebirth adds skill points and temper tokens.", reward = { gems = 90 } },
	{ id = "open40",     stat = "packs",    goal = 40,      text = "Open 40 packs",                tip = "Forever tools roll Temperaments (10 tokens). Rolls never refund.", reward = { pack = "night_pack", packQty = 3 } },
	{ id = "merge25",    stat = "merges",   goal = 25,      text = "Merge 25 times",               tip = "Sell unused skill points for tokens if you need a temper roll.", reward = { pack = "apex_pack", packQty = 2 } },
	{ id = "zone4",      stat = "zone",     goal = 3,       text = "Unlock three more zones",      tip = "Don't dig locked zones — buy the portal first.", reward = { gems = 144 } },
	{ id = "depth500",   stat = "depth",    goal = 500,     text = "Gain 500 depth",               tip = "Temperaments ride forever tools through rebirth with the family.", reward = { gems = 106 } },
	{ id = "gear12",     stat = "gear",     goal = 12,      text = "Own 12 more gear pieces",      tip = "Gear keeps. Re-equip after a rebirth if slots look empty.", reward = { gems = 86 } },
	{ id = "cards250",   stat = "cards",    goal = 250,     text = "Collect 250 more cards",       tip = "Prestige yield +15%/rank and luck +5%/rank forever.", reward = { gems = 168 } },
	{ id = "rebirth3",   stat = "rebirth",  goal = 3,       text = "Rebirth 3 more times",         tip = "Pay wall ≠ minimum. Farm the minimum bank shown on Rebirth.", reward = { gems = 192 } },
	{ id = "mine25k",    stat = "blocks",   goal = 25000,   text = "Break 25,000 blocks",          tip = "Job Board + dailies reset on the UTC day — free gems.", reward = { gems = 240 } },
	{ id = "merge60",    stat = "merges",   goal = 60,      text = "Merge 60 times",               tip = "High merges before a big rebirth bank pays off.", reward = { pack = "apex_pack", packQty = 3 } },
	-- Late
	{ id = "zone5",      stat = "zone",     goal = 4,       text = "Unlock four more zones",       tip = "Event Horizon is free while the event runs — claim via the portal.", reward = { gems = 240 } },
	{ id = "depth1k",    stat = "depth",    goal = 1000,    text = "Gain 1,000 depth",             tip = "Charms and skins keep across rebirths — depth is what unlocks the later ones.", reward = { gems = 280 } },
	{ id = "open120",    stat = "packs",    goal = 120,     text = "Open 120 packs",               tip = "Chest luck from skills/runes/temper stacks — dig for chests.", reward = { gems = 220 } },
	{ id = "sell200",    stat = "sells",    goal = 200,     text = "Sell 200 hauls",               tip = "Coins fund the next rebirth minimum. Don't idle on a full fee.", reward = { gems = 260 } },
	{ id = "cards500",   stat = "cards",    goal = 500,     text = "Collect 500 more cards",       tip = "Collection milestones pay gems anytime — check Quests.", reward = { pack = "apex_pack", packQty = 4 } },
	{ id = "rebirth5",   stat = "rebirth",  goal = 5,       text = "Rebirth 5 more times",         tip = "Skill tree roads are XOR — commit a path, then temper.", reward = { gems = 320 } },
	{ id = "mine75k",    stat = "blocks",   goal = 75000,   text = "Break 75,000 blocks",          tip = "AFK chill pad parks you safely if you go idle.", reward = { gems = 400 } },
	{ id = "merge150",   stat = "merges",   goal = 150,     text = "Merge 150 times",              tip = "Deep rune fuses cost exponential gems — budget for them.", reward = { gems = 360 } },
	{ id = "depth2k",    stat = "depth",    goal = 2000,    text = "Gain 2,000 depth",             tip = "Push depth on your strongest zone before banking a rebirth.", reward = { gems = 480 } },
	{ id = "gear30",     stat = "gear",     goal = 30,      text = "Own 30 more gear pieces",      tip = "Socket gear runes for set-defining stats.", reward = { gems = 340 } },
	{ id = "rune40",     stat = "runes",    goal = 40,      text = "Own 40 more runes",            tip = "Pet/tool/gear rune kinds are separate — roll what you socket.", reward = { gems = 340 } },
	{ id = "rebirth10",  stat = "rebirth",  goal = 10,      text = "Rebirth 10 more times",        tip = "Past late zones, income leans on prestige yield — bank the minimum.", reward = { gems = 600 } },
	{ id = "mine200k",   stat = "blocks",   goal = 200000,  text = "Break 200,000 blocks",         tip = "Keep temper tokens for forever-tool rerolls when kits look weak.", reward = { gems = 800 } },
	{ id = "cards1k",    stat = "cards",    goal = 1000,    text = "Collect 1,000 more cards",     tip = "Shinies and variants are permanent power.", reward = { pack = "apex_pack", packQty = 6 } },
	{ id = "zone6",      stat = "zone",     goal = 5,       text = "Unlock five more zones",       tip = "Buy every zone you can afford — portals are gem sinks that keep.", reward = { gems = 720 } },
	{ id = "merge400",   stat = "merges",   goal = 400,     text = "Merge 400 times",              tip = "Merge backlog is free power before a big rebirth.", reward = { gems = 660 } },
	{ id = "rebirth20",  stat = "rebirth",  goal = 20,      text = "Rebirth 20 more times",        tip = "TokensFor grows slowly — steady rebirths beat one huge stall.", reward = { gems = 900 } },
	{ id = "mine500k",   stat = "blocks",   goal = 500000,  text = "Break 500,000 blocks",         tip = "You're deep in — keep the min-bank habit and spend skills every rebirth.", reward = { gems = 1200 } },
}

MineQuests.COUNT = #MineQuests.CHAIN

--[[
	p.quest is an INDEX into CHAIN, so inserting rungs moves everyone. This is
	the order before the chest/layer rungs went in (2026-09-19); remapV1 turns
	an old index into the new index of the same quest, so nobody is pushed
	back or forward a rung. A finished ladder stays finished.
]]
MineQuests.CHAIN_V1 = {
	"mine25", "sell1", "pick2", "mine100", "depth20", "mine250", "open3", "cards10", "sell5", "zone2",
	"mine1k", "depth80", "merge1", "open10", "cards50", "sell25", "gear3", "rune5", "zone3", "mine3k",
	"merge8", "depth200", "cards100", "pick5", "rebirth1", "mine10k", "sell80", "open40", "merge25", "zone4",
	"depth500", "gear12", "cards250", "rebirth3", "mine25k", "merge60", "zone5", "depth1k", "open120", "sell200",
	"cards500", "rebirth5", "mine75k", "merge150", "depth2k", "gear30", "rune40", "rebirth10", "mine200k", "cards1k",
	"zone6", "merge400", "rebirth20", "mine500k",
}

--[[
	THE ORDER BEFORE THE FOUR TEACHING RUNGS WENT IN (2026-10-09).

	Same contract as CHAIN_V1 above, and the same reason: p.quest is an INDEX,
	so inserting forge1, charm1, skin1 and trait1 in the middle of the ladder
	moves every saved index onto a different quest. remapV2 turns a v2 index
	into the index of the SAME quest in the new chain, so a player mid-ladder
	stays on the rung they were on.

	The four were inserted rather than appended because the point of them is
	WHEN they are taught. Appending them past rebirth20 would put "forge a
	tool out of ore" after 50 hours of play, which is the problem, not a fix
	for it.
]]
MineQuests.CHAIN_V2 = {
	"mine25", "sell1", "pick2", "mine100", "chests3", "depth20", "chestsL2", "mine250", "open3", "chestsL3",
	"cards10", "sell5", "chests10", "zone2", "chestsL4", "mine1k", "depth80", "merge1", "open10", "chestsL5",
	"cards50", "sell25", "gear3", "chests25", "rune5", "zone3", "chestsL6", "mine3k", "merge8", "depth200",
	"cards100", "pick5", "rebirth1", "mine10k", "sell80", "open40", "merge25", "zone4", "depth500", "gear12",
	"cards250", "rebirth3", "mine25k", "merge60", "zone5", "depth1k", "open120", "sell200", "cards500", "rebirth5",
	"mine75k", "merge150", "depth2k", "gear30", "rune40", "rebirth10", "mine200k", "cards1k", "zone6", "merge400",
	"rebirth20", "mine500k",
}

function MineQuests.remapV2(index)
	index = math.max(1, math.floor(tonumber(index) or 1))
	if index > #MineQuests.CHAIN_V2 then
		return #MineQuests.CHAIN + 1
	end
	local id = MineQuests.CHAIN_V2[index]
	for i, q in ipairs(MineQuests.CHAIN) do
		if q.id == id then
			return i
		end
	end
	return index
end

function MineQuests.remapV1(index)
	index = math.max(1, math.floor(tonumber(index) or 1))
	if index > #MineQuests.CHAIN_V1 then
		return #MineQuests.CHAIN + 1
	end
	local id = MineQuests.CHAIN_V1[index]
	for i, q in ipairs(MineQuests.CHAIN) do
		if q.id == id then
			return i
		end
	end
	return index
end

function MineQuests.at(index)
	return MineQuests.CHAIN[math.floor(tonumber(index) or 0)]
end

function MineQuests.indexOf(id)
	for i, q in ipairs(MineQuests.CHAIN) do
		if q.id == id then
			return i
		end
	end
	return nil
end

function MineQuests.describe(reward, gemsOverride)
	if type(reward) ~= "table" then
		return "--"
	end
	local parts = {}
	if reward.coins then
		parts[#parts + 1] = reward.coins .. " Coins"
	end
	local gems = gemsOverride or reward.gems
	if gems and gems > 0 then
		parts[#parts + 1] = gems .. " Gems"
	end
	if reward.tool then
		parts[#parts + 1] = "Unlocks " .. tostring(reward.toolName or "a tool")
	end
	if reward.dust then
		parts[#parts + 1] = reward.dust .. " Stardust"
	end
	if reward.potion then
		local okP, Potions = pcall(require, script.Parent:WaitForChild("MinePotions"))
		local def = okP and Potions and Potions.def and Potions.def(reward.potion)
		local qty = reward.potionQty or 1
		parts[#parts + 1] = ((def and def.name) or "Potion") .. ((qty > 1) and (" x" .. qty) or "")
	end
	if type(reward.luckyBlocks) == "table" then
		for _, b in ipairs(reward.luckyBlocks) do
			local nm = ({ lucky_block = "Lucky Block", super_lucky_block = "Diamond Lucky Block",
				godly_lucky_block = "Mythic Lucky Block" })[b.id] or "Lucky Block"
			local qty = b.qty or 1
			parts[#parts + 1] = nm .. ((qty > 1) and (" x" .. qty) or "")
		end
	end
	if reward.credits then
		parts[#parts + 1] = reward.credits .. " Credits"
	end
	if reward.pack then
		local qty = reward.packQty or 1
		local nm = tostring(reward.pack):gsub("_", " "):gsub("^%l", string.upper):gsub(" %l", string.upper)
		parts[#parts + 1] = (qty > 1) and (nm .. " x" .. qty) or nm
	end
	return #parts > 0 and table.concat(parts, "  +  ") or "--"
end

function MineQuests.short(n)
	n = math.floor(tonumber(n) or 0)
	if n < 1000 then
		return tostring(n)
	end
	if n < 1000000 then
		local v = n / 1000
		return string.format(v >= 100 and "%.0fK" or "%.1fK", v)
	end
	return string.format("%.1fM", n / 1000000)
end

--------------------------------------------------------------------------------
-- LIFETIME MILESTONES (absolute counters, claim anytime when met)
--------------------------------------------------------------------------------
MineQuests.MILESTONES = {
	{ id = "ms_blocks_500",   stat = "blocks",  goal = 500,     text = "Lifetime: 500 blocks",      reward = { gems = 35 } },
	{ id = "ms_blocks_5k",    stat = "blocks",  goal = 5000,    text = "Lifetime: 5,000 blocks",    reward = { gems = 150 } },
	{ id = "ms_blocks_50k",   stat = "blocks",  goal = 50000,   text = "Lifetime: 50,000 blocks",  reward = { gems = 96 } },
	{ id = "ms_blocks_250k",  stat = "blocks",  goal = 250000,  text = "Lifetime: 250,000 blocks", reward = { gems = 320 } },
	{ id = "ms_packs_10",     stat = "packs",   goal = 10,      text = "Lifetime: 10 packs opened", reward = { gems = 60 } },
	{ id = "ms_gear_15",      stat = "gear",    goal = 15,      text = "Lifetime: 15 gear pieces", reward = { gems = 72 } },
	{ id = "ms_packs_25",     stat = "packs",   goal = 25,      text = "Lifetime: 25 packs opened", reward = { gems = 32 } },
	{ id = "ms_packs_100",    stat = "packs",   goal = 100,     text = "Lifetime: 100 packs opened",reward = { gems = 120 } },
	{ id = "ms_cards_100",    stat = "cards",   goal = 100,     text = "Lifetime: 100 cards",       reward = { pack = "iron_pack", packQty = 2 } },
	{ id = "ms_cards_500",    stat = "cards",   goal = 500,     text = "Lifetime: 500 cards",       reward = { gems = 192 } },
	{ id = "ms_merges_50",    stat = "merges",  goal = 50,      text = "Lifetime: 50 merges",      reward = { gems = 90 } },
	{ id = "ms_merges_200",   stat = "merges",  goal = 200,     text = "Lifetime: 200 merges",     reward = { gems = 240 } },
	{ id = "ms_zone_3",       stat = "zone",    goal = 3,       text = "Lifetime: own 3 zones",    reward = { gems = 64 } },
	{ id = "ms_zone_5",       stat = "zone",    goal = 5,       text = "Lifetime: own 5 zones",    reward = { gems = 168 } },
	{ id = "ms_rebirth_3",    stat = "rebirth", goal = 3,       text = "Lifetime: Rebirth 3",      reward = { gems = 120 } },
	{ id = "ms_rebirth_10",   stat = "rebirth", goal = 10,      text = "Lifetime: Rebirth 10",     reward = { gems = 400 } },
	{ id = "ms_depth_250",    stat = "depth",   goal = 250,     text = "Lifetime: depth 250",      reward = { gems = 80 } },
	{ id = "ms_depth_1500",   stat = "depth",   goal = 1500,    text = "Lifetime: depth 1,500",    reward = { gems = 300 } },
}

function MineQuests.milestoneById(id)
	for _, m in ipairs(MineQuests.MILESTONES) do
		if m.id == id then
			return m
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- DAILY QUESTS (unchanged shape)
--------------------------------------------------------------------------------
--[[
	Daily quests are a real session, not accidental 30-second ticks.
	Three fixed tiers every day:
	  A) ~10 min   — dig work
	  B) ~25-30 min — one rebirth
	  C) ~45 min   — chest farm or pack opens
	Gear / rune opens never count toward the packs tier (server-side).
]]
MineQuests.DAILY_TIERS = {
	{
		{ id = "d_blocks_500", stat = "blocks", goal = 500, text = "Break 500 blocks", gems = 45 },
	},
	{
		{ id = "d_rebirth_1", stat = "rebirth", goal = 1, text = "Rebirth once", gems = 90 },
	},
	{
		{ id = "d_chests_50", stat = "chests", goal = 50, text = "Mine 50 chests", gems = 120 },
		{ id = "d_packs_50",  stat = "packs",  goal = 50, text = "Open 50 packs",  gems = 120 },
	},
}

-- Flat pool kept for dailyById lookups (claim UI / gem payout).
MineQuests.DAILY_POOL = {}
for _, tier in ipairs(MineQuests.DAILY_TIERS) do
	for _, q in ipairs(tier) do
		table.insert(MineQuests.DAILY_POOL, q)
	end
end
MineQuests.DAILY_COUNT = 3
MineQuests.DAILY_ZONE_SCALE = 0.6

function MineQuests.dailyById(id)
	for _, q in ipairs(MineQuests.DAILY_POOL) do
		if q.id == id then
			return q
		end
	end
	return nil
end

function MineQuests.dailyGems(q, zone)
	if not q then
		return 0
	end
	local z = math.max(1, math.floor(tonumber(zone) or 1))
	return math.floor((q.gems or 0) * (1 + (z - 1) * MineQuests.DAILY_ZONE_SCALE))
end

--[[
	Never a daily or a job, whatever lands in the pools later: buying a tool
	("buy a better pickaxe") is a one-off on the main ladder, not something
	everyone can do every day.
]]
MineQuests.NOT_DAILY = { picktier = true, tool = true, buyTool = true }

local function dailyOk(row)
	return type(row) == "table" and not MineQuests.NOT_DAILY[row.stat]
end

function MineQuests.rollDaily(dayIndex, userId)
	local rng = Random.new((tonumber(dayIndex) or 0) * 100003 + (tonumber(userId) or 0))
	local out = {}
	for _, fullTier in ipairs(MineQuests.DAILY_TIERS) do
		local tier = {}
		for _, row in ipairs(fullTier) do
			if dailyOk(row) then
				table.insert(tier, row)
			end
		end
		if #tier == 0 then
			tier = { MineQuests.DAILY_TIERS[1][1] }
		end
		local pick = tier[rng:NextInteger(1, #tier)]
		table.insert(out, {
			id = pick.id,
			stat = pick.stat,
			goal = pick.goal,
			progress = 0,
			claimed = false,
		})
	end
	return out
end

--------------------------------------------------------------------------------
-- CONTRACTOR / JOB BOARD (rotating contracts)
--------------------------------------------------------------------------------
MineQuests.CONTRACT_POOL = {
	{ id = "c_blocks_s",  stat = "blocks", goal = 200,  text = "Break 200 blocks",        gems = 40 },
	{ id = "c_blocks_m",  stat = "blocks", goal = 600,  text = "Break 600 blocks",        gems = 70 },
	{ id = "c_blocks_l",  stat = "blocks", goal = 1200, text = "Break 1,200 blocks",      gems = 110 },
	{ id = "c_sell_s",    stat = "sells",  goal = 4,    text = "Sell 4 hauls",            gems = 45 },
	{ id = "c_sell_m",    stat = "sells",  goal = 8,    text = "Sell 8 hauls",            gems = 80 },
	{ id = "c_packs_s",   stat = "packs",  goal = 5,    text = "Open 5 packs",            gems = 50 },
	{ id = "c_packs_m",   stat = "packs",  goal = 12,   text = "Open 12 packs",           gems = 95 },
	{ id = "c_merge_s",   stat = "merges", goal = 3,    text = "Merge 3 cards",           gems = 55 },
	{ id = "c_merge_m",   stat = "merges", goal = 7,    text = "Merge 7 cards",           gems = 100 },
	{ id = "c_cards_s",   stat = "cards",  goal = 15,   text = "Collect 15 cards",        gems = 60 },
	{ id = "c_cards_m",   stat = "cards",  goal = 40,   text = "Collect 40 cards",        gems = 120 },
	{ id = "c_depth_s",   stat = "depth",  goal = 50,   text = "Gain 50 depth",           gems = 55 },
	{ id = "c_depth_m",   stat = "depth",  goal = 150,  text = "Gain 150 depth",          gems = 105 },
	{ id = "c_gear_s",    stat = "gear",   goal = 2,    text = "Summon 2 gear",           gems = 65 },
	{ id = "c_rune_s",    stat = "runes",  goal = 3,    text = "Summon 3 runes",          gems = 65 },
}
MineQuests.CONTRACT_COUNT = 3
MineQuests.CONTRACT_ZONE_SCALE = 0.55

function MineQuests.contractById(id)
	for _, q in ipairs(MineQuests.CONTRACT_POOL) do
		if q.id == id then
			return q
		end
	end
	return nil
end

function MineQuests.contractGems(q, zone)
	if not q then
		return 0
	end
	local z = math.max(1, math.floor(tonumber(zone) or 1))
	return math.floor((q.gems or 0) * (1 + (z - 1) * MineQuests.CONTRACT_ZONE_SCALE))
end

-- Same day seed family as dailies, offset so the sets differ.
function MineQuests.rollContracts(dayIndex, userId)
	local rng = Random.new((tonumber(dayIndex) or 0) * 91711 + (tonumber(userId) or 0) + 91)
	local pool = {}
	for _, row in ipairs(MineQuests.CONTRACT_POOL) do
		if dailyOk(row) then
			table.insert(pool, row)
		end
	end
	for i = #pool, 2, -1 do
		local j = rng:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local used = {}
	local out = {}
	for _, pick in ipairs(pool) do
		if not used[pick.stat] then
			used[pick.stat] = true
			table.insert(out, {
				id = pick.id,
				stat = pick.stat,
				goal = pick.goal,
				progress = 0,
				claimed = false,
			})
			if #out >= MineQuests.CONTRACT_COUNT then
				break
			end
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- PLAYTIME GIFTS
--------------------------------------------------------------------------------
--[[
	Minutes played today (UTC), across rejoins, open these one by one. The
	first lands inside the first few minutes so a new player sees how it works;
	the last is worth sitting out a long session for. Gems scale with the
	deepest zone owned, like the daily. No credits: those are what people buy.
]]
MineQuests.PLAYTIME = {
	{ min = 2,  reward = { gems = 100 } },
	{ min = 5,  reward = { pack = "clay_pack" } },
	{ min = 10, reward = { gems = 250 } },
	{ min = 15, reward = { potion = "fortune_sip" } },
	{ min = 25, reward = { gems = 500, pack = "slate_pack" } },
	{ min = 40, reward = { luckyBlocks = { { id = "lucky_block", startGrade = "D", qty = 1 } } } },
	{ min = 60, reward = { gems = 1000, pack = "iron_pack", packQty = 2 } },
	{ min = 90, reward = { potion = "haste_flask", pack = "night_pack" } },
}
MineQuests.PLAYTIME_ZONE_SCALE = 0.6

function MineQuests.playtimeGems(reward, zone)
	if type(reward) ~= "table" or not reward.gems then
		return 0
	end
	local z = math.max(1, math.floor(tonumber(zone) or 1))
	return math.floor(reward.gems * (1 + (z - 1) * MineQuests.PLAYTIME_ZONE_SCALE))
end

return MineQuests
