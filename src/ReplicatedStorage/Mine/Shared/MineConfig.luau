-- MineConfig: zones, tools, variants, blocks. Print rarity never changes.
-- Variant naming: a card has one base variant plus an optional `shiny` flag.
-- Display it with PetModelFactory.variantLabel, which yields e.g. "Shiny Golden".
local MineConfig = {}

local Depth = require(script.Parent:WaitForChild("MineDepth"))
MineConfig.Depth = Depth
MineConfig.SECTIONS = Depth.SECTIONS
-- The mine floor. Raised 5000 -> 10000 so depth reaches the last seam (10000)
-- and keeps going past it; MineDepth.SECTIONS already authors HP out to layer
-- 10040, so the curve was always ready for this. Generation is on demand
-- (ensureZone builds to deepest + a window), so this is a ceiling, not an
-- allocation -- nothing is built until somebody digs there.
MineConfig.MINE1_LAYERS = 10000
MineConfig.LAYERS = 10000

--[[
	STUDIO NEVER TOUCHES LIVE DATA.

	Studio playtests used to read and write the real stores, so every test
	session -- admin grants, 200M test gems, zone 10 unlocks -- landed in the
	owner's live save and on the live leaderboards. In Studio every store name
	now carries "_Studio": the same code, a separate copy of the data. Published
	servers are unchanged ("Mine_v1" and friends).
]]
MineConfig.DATASTORE_SUFFIX = game:GetService("RunService"):IsStudio() and "_Studio" or ""
MineConfig.DATASTORE = "Mine_v1" .. MineConfig.DATASTORE_SUFFIX
function MineConfig.storeName(name)
	return tostring(name) .. MineConfig.DATASTORE_SUFFIX
end
MineConfig.BLOCK = 5
-- Pit is GRID x GRID blocks per layer. 21 gives 441 per layer -- 2.6x the
-- floor area of the old 13, so a layer is somewhere to explore rather than
-- a room you clear in a few swings.
MineConfig.GRID = 21
MineConfig.LAYERS = 5000
-- Layers are generated in a window below the deepest point reached, not all
-- at once: 50 layers x 13 x 13 is 8,450 parts per zone, and building that in
-- one synchronous loop freezes the server for seconds.
MineConfig.LAYER_WINDOW = 8
-- Seconds before a broken block grows back. **0 means never**, which is the
-- default, because the game is about digging DOWN.
--
-- It was 14. At that rate the hole refilled behind you faster than you could
-- clear its neighbours, so there was no descent at all -- you stood in one
-- spot farming a cell that kept handing you fresh rolls. It is also why
-- containers were effectively infinite in a single square metre.
--
-- The cost of 0: a zone is finite. 21 x 21 x 50 is 22,050 blocks, about 2.5
-- hours of solo mining, and the pit is shared by everyone on the server, so a
-- busy server strips it faster. The real answers are per-player mine instances
-- or a slow refill from the top down; both are bigger jobs. Until then, raising
-- this to something long (600+) is the safety valve, NOT going back to 14.
MineConfig.REGEN_SEC = 0
MineConfig.SWING_SEC = 0.42
MineConfig.MAX_POWER = 25
MineConfig.STARTER_PET_SLOTS = 3
--[[
	THREE PET SLOTS, AND THAT IS ALL OF THEM.

	It used to climb to eight -- three free and five sold, the fourth for gems
	and two for Robux. A fourth pet is not a small thing: every pet's boost is
	multiplied by every hat you wear, so each seat added is a multiplier on the
	whole gear stack rather than a flat step, and the ladder to eight was the
	single largest power gap in the game sitting behind a till.

	Three is now the number for everybody. STARTER and MAX being equal is the
	point: every clamp in the game already reads MAX, so there is no seat four
	to buy, no seat four to migrate into, and nothing to hide in the shop. A save
	that bought its way to eight is clamped back down on load -- the pets are all
	still owned, only three come out at a time.
]]
MineConfig.MAX_PET_SLOTS = 3
MineConfig.CAMP_RADIUS = 180
-- Quality of life: the walk from the plaza to the far counters and back
-- down the mine is the most repeated action in the game.
MineConfig.BASE_WALK_SPEED = 78
-- Divide only movement. Dig / swing / cooldowns stay untouched.
MineConfig.WALK_PACE = 3
-- How far a charge can be lobbed. Reach is how far your ARM goes and is a
-- pickaxe concept; a thrown charge is limited by the throw, not the arm.
MineConfig.THROW_RANGE = 160
MineConfig.CAMP = Vector3.new(0, 6, 0)

-- AFK chill pad (east of plaza). Idle players park here and chip one endless block.
-- Entry is deliberate: 2 minutes of no input (not Roblox Idled alone).
MineConfig.AFK_IDLE_SEC = 2 * 60
-- Retired: AFK never grants gems. Kept at 0 so old reads stay harmless.
MineConfig.AFK_GEMS = 0
-- Coins per AFK tick — tuned so leaving the PC on feels worth it.
-- AFK income ~1/4 of prior (packs + coins). Interval unchanged so pads still tick.
MineConfig.AFK_COINS_BASE = 2
MineConfig.AFK_COINS_PER_ZONE = 1
MineConfig.AFK_COINS_PER_PICK = 1
-- Pack drip: ~1/4 prior chance/cap.
MineConfig.AFK_PACK_BASE = 1 / 180
MineConfig.AFK_PACK_CAP = 0.045
MineConfig.AFK_SEC_STARTER = 32
MineConfig.AFK_SEC_ENDGAME = 12
MineConfig.AFK_PAD = Vector3.new(-260, 72, -300) -- private elevated lounge, teleport-only
-- Same-place teleport while AFK so Roblox's ~20m idle disconnect cannot stick.
-- 10m leaves headroom; VirtualUser alone is no longer enough on modern clients.
-- Roblox kicks at twenty minutes of no input; rejoin well before that.
MineConfig.AFK_REFRESH_SEC = 7 * 60
-- Far ring default. Per-zone `radius` overrides this. Adjacent origins on the
-- progression ring sit ~36° apart; at R≈6000 that is ~3700+ studs, so you cannot
-- see the next mine from an island (and 2 x ISLAND still clears).
MineConfig.ZONE_RADIUS = 6000
-- Island radius must clear the pit: pitW = GRID * BLOCK = 105, so the island
-- needs a radius well above ~53. Oversized pads leave room for later content.
MineConfig.ISLAND = 180
-- Walk-to threshold: only Dirt Meadow stays on a road from the lobby.
MineConfig.WALK_TO_MAX = 800

-- Stone camp / spawn courtyard. Plaza is ~48×48 at origin, fountain at center.
-- Padding so 5-stud voxel edges cannot clip stalls or the fountain.
MineConfig.LOBBY_MIN = Vector3.new(-150, -16, -150)
MineConfig.LOBBY_MAX = Vector3.new(150, 32, 150)
-- Fountain look-at target (lobby center). Spawns ring this point.
MineConfig.FOUNTAIN = Vector3.new(0, 8, 0)
MineConfig.SPAWN_RING = 22

function MineConfig.zoneIndex(id)
	if type(id) == "table" then
		id = id.id
	end
	for i, z in ipairs(MineConfig.ZONES) do
		if z.id == id then return i end
	end
	return 1
end

-- The lobby is the surface. This used to be a 52-stud circle round the world
-- origin, which excluded every shop in the lobby (they stand at radius 80-94)
-- and so refused sales and purchases at the counters selling them.
function MineConfig.atSurface(pos)
	local lo, hi = MineConfig.LOBBY_MIN, MineConfig.LOBBY_MAX
	if lo and hi then
		return pos.X >= lo.X and pos.X <= hi.X
			and pos.Y >= lo.Y and pos.Y <= hi.Y
			and pos.Z >= lo.Z and pos.Z <= hi.Z
	end
	local flat = Vector3.new(pos.X, 0, pos.Z)
	return flat.Magnitude <= (MineConfig.CAMP_RADIUS or 150)
end


--------------------------------------------------------------------------------
-- REBIRTH, GEMS AND RELICS
--------------------------------------------------------------------------------

-- Rebirth used to be gated on touching the bottom of the map, which is a chore
-- rather than a decision: you either did the lap or you did not, and no choice
-- was involved. It is a purchase now -- coins for the work you did, gems for the
-- ore you kept -- so it competes with everything else you could spend on.
function MineConfig.rebirthGems(r)
	r = math.max(1, math.floor(r or 1))
	return math.floor(12500 * math.pow(2.08, r - 1) / 100 + 0.5) * 100
end

-- The Charter is the long game for gems: it never resets, so gems stay worth
-- banking after a rebirth wipes your coins. Backpacks
-- are a coin ladder again (runes will be the next gem sink).
MineConfig.CHARTER = {
	{ id = "survey",  name = "Survey Rights",  stat = "oreYield",  per = 0.04, max = 10, base = 14000, step = 1.62 },
	{ id = "assay",   name = "Assay Licence",  stat = "gemFind",   per = 0.05, max = 10, base = 20000, step = 1.66 },
	{ id = "salvage", name = "Salvage Writ",   stat = "chestLuck", per = 0.06, max = 8,  base = 34000, step = 1.74 },
	{ id = "haulage", name = "Haulage Permit", stat = "backpack",  per = 0.05, max = 8,  base = 27000, step = 1.7 },
}

function MineConfig.charterCost(row, level)
	return math.floor(row.base * math.pow(row.step, level) / 100 + 0.5) * 100
end

function MineConfig.charterById(id)
	for _, row in ipairs(MineConfig.CHARTER) do
		if row.id == id then return row end
	end
	return nil
end

-- Relics are the rare chest drop that is NOT a pack: real items, kept through
-- rebirth. They are the reason to keep breaking chests once your binder is full.
MineConfig.RELICS = {
	{ id = "ironheart",  name = "Ironheart Core",   stat = "power",     amount = 0.06, tint = Color3.fromRGB(206, 122, 84) },
	{ id = "lodestone",  name = "Miner's Lodestone", stat = "luck",     amount = 0.08, tint = Color3.fromRGB(150, 200, 255) },
	{ id = "deepvein",   name = "Deepvein Shard",   stat = "oreYield",  amount = 0.07, tint = Color3.fromRGB(140, 226, 168) },
	{ id = "coffer",     name = "Bottomless Coffer", stat = "backpack", amount = 0.09, tint = Color3.fromRGB(226, 190, 96) },
	{ id = "tallytoken", name = "Tally Token",      stat = "coinBonus", amount = 0.07, tint = Color3.fromRGB(255, 214, 120) },
	{ id = "gemglass",   name = "Gemglass Lens",    stat = "gemFind",   amount = 0.08, tint = Color3.fromRGB(184, 140, 255) },
	{ id = "quickstep",  name = "Quickstep Charm",  stat = "walkSpeed", amount = 0.05, tint = Color3.fromRGB(120, 244, 226) },
	{ id = "keyring",    name = "Warden's Keyring", stat = "chestLuck", amount = 0.10, tint = Color3.fromRGB(255, 150, 150) },
}

function MineConfig.relicById(id)
	for _, r in ipairs(MineConfig.RELICS) do
		if r.id == id then return r end
	end
	return nil
end

-- What a broken chest turns into. Weights are relative; luck pushes the good
-- rows up and the filler rows down.
--[[
	WHAT A CHEST PAYS.

	Gems are gone from this table on purpose. Gems are minted by selling scrap
	ore now, which is the whole point of the ore roster -- a currency whose
	price we set rather than one that leaks out of every chest in the game.

	Hats and charms both arrive here, and the gap between them is the design:
	a hat is something you see often enough to go looking for sets, a charm is
	a real find. Hats run about 8x the rate of charms.

	Per 1000 chests, roughly: 701 packs, 170 coins, 90 hats, 22 dust,
	11 charms, 6 relics.
]]
MineConfig.CHEST_LOOT = {
	{ kind = "pack",   weight = 70 },
	{ kind = "coins",  weight = 17 },
	{ kind = "hat",    weight = 9 },
	{ kind = "dust",   weight = 2.2 },
	{ kind = "charm",  weight = 1.1, lucky = true },
	{ kind = "relic",  weight = 0.6, lucky = true },
}

--[[
	HOW MANY PACKS A PACK CHEST PAYS.

	Not one. A chest can come up empty and a chest can bury you, and there is
	no cap on the good end -- that open tail is the entire reason the empty end
	is allowed to exist. No pity, no floor, no "guaranteed after N".

	The haul is base + a geometric run: each extra pack keeps the run going
	with probability STREAK, scaled by luck. At luck 1 that averages under two
	packs and comes up empty about one time in ten. Stack enough luck and
	STREAK approaches its ceiling, where hauls of 10-20 stop being remarkable.
	The ceiling is on the per-step probability, never on the count.
]]
MineConfig.CHEST_PACK_BASE = 1
MineConfig.CHEST_PACK_EMPTY = 0.10
MineConfig.CHEST_PACK_STREAK = 0.42
MineConfig.CHEST_PACK_STREAK_MAX = 0.94

function MineConfig.chestPackCount(luck, rng)
	rng = rng or Random.new()
	local l = math.max(1, tonumber(luck) or 1)
	if rng:NextNumber() < (MineConfig.CHEST_PACK_EMPTY / l) then
		return 0
	end
	local n = MineConfig.CHEST_PACK_BASE
	local p = math.min(MineConfig.CHEST_PACK_STREAK_MAX, MineConfig.CHEST_PACK_STREAK * l)
	while rng:NextNumber() < p do
		n += 1
	end
	return n
end

function MineConfig.zoneOrigin(zone)
	local rad = math.rad(zone.angle or 0)
	-- `zone.radius` overrides the ring. Zone 1 sits just outside the lobby so
	-- the starter mine is somewhere you WALK to, not somewhere you teleport.
	local r = zone.radius or MineConfig.ZONE_RADIUS
	return Vector3.new(math.sin(rad) * r, 4, math.cos(rad) * r)
end

function MineConfig.blockOverlapsLobby(pos, half)
	local a, b = MineConfig.LOBBY_MIN, MineConfig.LOBBY_MAX
	if not a or not b or not pos then
		return false
	end
	local h = half or ((MineConfig.BLOCK or 5) * 0.5)
	return (pos.X + h) >= a.X and (pos.X - h) <= b.X
		and (pos.Y + h) >= a.Y and (pos.Y - h) <= b.Y
		and (pos.Z + h) >= a.Z and (pos.Z - h) <= b.Z
end

--[[
	The merge ladder. Three of a kind climbs it: Normal -> Golden -> Prism ->
	Rainbow.

	Shiny is NOT on it. Shiny and Shadow are luck -- they ride on top of
	whatever variant a card rolled, so a Golden card can be shiny too. Cards
	minted before this still carry variant "Shiny"; nextVariant treats that as
	Normal so they can still be merged.
]]
MineConfig.VARIANTS = { "Normal", "Golden", "Prism", "Rainbow" }

MineConfig.SHINY_CHANCE = 0.04
MineConfig.SHINY_MULT = 1.5

--[[
	SHADOW. The rarest finish in the game.

	A shiny roll has a ONE IN A HUNDRED chance of coming out Shadow instead --
	black with a red burn rather than foil -- which is one in twenty-five
	hundred cards at the usual 4% shiny rate.

	The Shiny Pack is the exception, and the only one: one shiny in twenty
	there (MinePackConfig.SHADOW_OF_SHINY). That is what the pack is for --
	it does not just pay more shinies, it is the one place shadow is worth
	hunting.

	Tools roll their own share, MineTools.SHADOW_OF_SHINY, still one in twenty
	of a chest tool's shinies.
]]
MineConfig.SHADOW_OF_SHINY = 1 / 100
MineConfig.SHADOW_MULT = 3
MineConfig.NIGHTMARE_OF_SHADOW = 1 / 20
MineConfig.NIGHTMARE_MAX_LAYER = 2500
MineConfig.NIGHTMARE_MULT = 4.5
MineConfig.VARIANT_MULT = {
	Normal = 1,
	-- Legacy: cards minted while Shiny was a rung still price off it.
	Shiny = 1.5,
	Golden = 2.25,
	Prism = 3.5,
	Rainbow = 5.5,
}
-- Eight rungs, matching MineCards.RARITY_ORDER. The old seven-rung ids are
-- kept as aliases so a card minted before the change still prices correctly.
MineConfig.RARITY_MULT = {
	Common = 1,
	Uncommon = 1.15,
	Rare = 1.35,
	Epic = 1.6,
	Legendary = 2,
	Mythic = 2.6,
	Divine = 3.4,
	Exotic = 4.4,
	HoloRare = 1.6,
	UltraRare = 2,
	HyperRare = 2.6,
	SecretRare = 4.4,
}
MineConfig.RARITY_DUST = {
	-- Low tiers stay cheap scrap (market pressure to open/keep chase cards).
	-- High tiers keep strong buyback (~60–80% of CARD_STARDUST_COST).
	Common = 6,
	Uncommon = 12,
	Rare = 28,
	Epic = 90,
	Legendary = 1600,
	Mythic = 4000,
	Divine = 11200,
	Exotic = 32000,
	HoloRare = 90,
	UltraRare = 1600,
	HyperRare = 4000,
	SecretRare = 32000,
}
MineConfig.TYPE_BOOST = {
	Fire = "mineSpeed",
	Rock = "oreYield",
	Metal = "oreYield",
	Crystal = "luck",
	Mystic = "luck", -- legacy alias for Crystal
	Electric = "zap",
	Earth = "dirtBreak",
	Water = "backpack",
	Shadow = "rareOre",
}
MineConfig.BOOST_LABELS = {
	mineSpeed = "Mine speed",
	oreYield = "Blast",
	luck = "Luck",
	walkSpeed = "Walk speed",
	dirtBreak = "Dirt break",
	backpack = "Backpack",
	rareOre = "Rare ore",
	swingSec = "Swing time",
	echo = "Echo hit",
	zap = "Zap",
}

MineConfig.PICKAXES = {
	{ id = 1, name = "Wood Pickaxe", power = 1, price = 0, color = Color3.fromRGB(160, 118, 70) },
	{ id = 2, name = "Stone Pickaxe", power = 2, price = 250, color = Color3.fromRGB(130, 130, 138) },
	{ id = 3, name = "Iron Pickaxe", power = 3, price = 900, color = Color3.fromRGB(190, 198, 210) },
	{ id = 4, name = "Crystal Pickaxe", power = 5, price = 2800, color = Color3.fromRGB(160, 120, 255) },
	{ id = 5, name = "Void Pickaxe", power = 8, price = 8000, color = Color3.fromRGB(70, 40, 110) },
}

--[[
	EMPTY HANDS.

	The free first pickaxe is collected from the Blacksmith, so between
	spawning in and running that errand a player genuinely holds nothing.

	equippedTool used to fall back to rung 1 whenever you owned nothing in a
	family, which is exactly what made the old "go and get your first
	pickaxe" step impossible to obey -- the game handed you the tool it was
	asking you to go and fetch.

	A real def rather than nil: fourteen call sites read fields straight off
	the result, and half of them would throw on a nil.
]]
MineConfig.BARE_HANDS = {
	id = "bare_hands",
	name = "Bare Hands",
	power = 0,
	price = 0,
	rate = 1,
	radius = 0,
	cooldown = 0.5,
	range = 12,
	none = true,
	color = Color3.fromRGB(150, 130, 110),
}

MineConfig.BACKPACKS = require(script.Parent:WaitForChild("MineBags")).LIST

-- Kept so an old shop row or an old save resolves rather than erroring. Nothing
-- is purchasable: MAX_PET_SLOTS is 3, so every price here is for a seat that
-- cannot exist.
MineConfig.PET_SLOT_PRICE = { 0, 0, 0 }
MineConfig.CRATE_PRICE = 200
--[[
	Limited event mine (Event Horizon — Matter± / Cosmo / Albert Minestein).

	US Eastern midnights (EDT, UTC-4). Biggest Roblox audience, and the
	battle pass uses the same clock.
	    opens  2026-09-22 00:00 ET  (1790049600)
	    closes 2026-11-01 00:00 ET  (1793505600)  -- Oct 31 is a full day

	This was 0, which `limitedActive` reads as "live forever" -- fine while the
	place was only ever running in Studio, and a lie the moment it is published,
	because every screen that calls the zone LIMITED would have been advertising
	a deadline that did not exist.

	Closing takes the zone off the shelf; it does not take it off anyone who
	claimed it. `bigbangOwned` is on the profile, and both enterZone and the
	Wormhole Bag check ownership rather than the window, so a player who claimed
	Event Horizon during the event keeps the mine, the bag and the pets afterwards.
	That is what makes it worth claiming rather than worth resenting.
]]
MineConfig.LIMITED_START_UNIX = 1790049600
-- 40 + 7: every rotating offer was extended by a week, and the portal clock
-- has to say the same thing the shelf does.
MineConfig.LIMITED_DAYS = 47

function MineConfig.limitedActive()
	local start = MineConfig.LIMITED_START_UNIX or 0
	if start <= 0 then
		return true
	end
	return os.time() < start + (MineConfig.LIMITED_DAYS or 35) * 86400
end

function MineConfig.limitedEndsAt()
	local start = MineConfig.LIMITED_START_UNIX or 0
	if start <= 0 then
		return nil
	end
	return start + (MineConfig.LIMITED_DAYS or 35) * 86400
end

--[[
	How long is left, as something a player can read.

	Coarse on purpose: weeks and days while it is far away, hours and minutes
	once it is close. A countdown that shows seconds five weeks out is noise,
	and one that shows "34d" in the last hour is a countdown that stops
	counting exactly when it starts mattering.

	Returns nil when there is no deadline at all, so a caller can tell "no
	event configured" apart from "no time left".
]]
function MineConfig.limitedCountdown()
	local ends = MineConfig.limitedEndsAt()
	if not ends then
		return nil
	end
	local left = ends - os.time()
	if left <= 0 then
		return "closed"
	end
	local d = math.floor(left / 86400)
	local h = math.floor((left % 86400) / 3600)
	local m = math.floor((left % 3600) / 60)
	if d >= 1 then
		return d .. "d " .. h .. "h"
	end
	if h >= 1 then
		return h .. "h " .. m .. "m"
	end
	return math.max(1, m) .. "m"
end

-- Live portal clock (includes seconds). `now` should be workspace:GetServerTimeNow()
-- on the client so every player ticks the same second.
function MineConfig.limitedLeftSec(now)
	local ends = MineConfig.limitedEndsAt()
	if not ends then
		return nil
	end
	now = tonumber(now) or os.time()
	return math.max(0, math.floor(ends - now))
end

function MineConfig.limitedClock(now)
	local left = MineConfig.limitedLeftSec(now)
	if left == nil then
		return nil
	end
	if left <= 0 then
		return "CLOSED"
	end
	local d = math.floor(left / 86400)
	local h = math.floor((left % 86400) / 3600)
	local m = math.floor((left % 3600) / 60)
	local s = left % 60
	if d > 0 then
		return string.format("%dd %02d:%02d:%02d", d, h, m, s)
	end
	return string.format("%02d:%02d:%02d", h, m, s)
end

--[[
	Events tab catalog.
	bannerImage: set to rbxassetid://… after uploading the cartoon banner PNG
	(assets/event-horizon-banner.png). Empty uses the procedural cartoon banner.
]]
MineConfig.EVENTS = {
	{
		id = "event_horizon",
		zoneId = "bigbang",
		name = "Event Horizon",
		blurb = "Claim a moonlit mine at the edge of a black hole. Unlock the Wormhole Bag and hunt limited pets Matter+, Matter−, Cosmo, and Albert Minestein while the timer runs.",
		bannerImage = "rbxassetid://84324385292112",
		ownedFlag = "bigbangOwned",
	},
}

--[[
	THE CLOUDS.

	The skill tree only changes here. "Here" is where your character is
	standing -- the cloud deck WorldBuilder builds high above the lobby -- and
	not a flag on the profile.

	It used to be a flag: set true on rebirth, cleared on your first broken
	block, and never set again. Nothing else touched it, so jumping off the deck
	into the lobby left you "in the Clouds" while walking around downstairs, and
	mining one block locked your tree until the next rebirth with no way back.
	Asking where the character actually is has no exit to forget: walking off,
	jumping down, respawning and teleporting away all end it by themselves.

	Shared so the server (authority, from its own view of the character) and
	the client (what the wheel shows) use one definition.
]]
MineConfig.CLOUD_RADIUS = 70

function MineConfig.cloudDeck()
	local world = workspace:FindFirstChild("MineWorld")
	local clouds = world and world:FindFirstChild("Clouds")
	return clouds and clouds:FindFirstChild("Deck")
end

function MineConfig.inCloudsAt(pos)
	local deck = MineConfig.cloudDeck()
	if typeof(pos) ~= "Vector3" or not deck then
		return false
	end
	local d = pos - deck.Position
	-- Generous sideways (the puffs overhang the deck), tight vertically: the
	-- lobby is four hundred studs straight down, so height alone separates them.
	return (d.X * d.X + d.Z * d.Z) <= MineConfig.CLOUD_RADIUS * MineConfig.CLOUD_RADIUS
		and d.Y > -40 and d.Y < 120
end

function MineConfig.playerInClouds(plr)
	local character = plr and plr.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and MineConfig.inCloudsAt(root.Position)
end

function MineConfig.isProgressionZone(zone)
	if type(zone) == "string" then
		zone = MineConfig.zoneById(zone)
	end
	return zone ~= nil and not zone.limited
end
MineConfig.POWER_DUST = 25
-- VIP gamepass. No shop discount, bag, walk, or luck.
-- Perks: remote sell (cooldown), AFK coins/gems, [VIP] tag. (It used to add a
-- pet seat; three seats is everybody's number now, so it no longer can.)
MineConfig.VIP_GAMEPASS_ID = 1977363670
MineConfig.VIP_PRICE_MULT = 1
MineConfig.VIP_PAYOUT_MULT = 1
MineConfig.VIP_NAME_PREFIX = "[VIP] "
MineConfig.FOUNDERS_NAME_PREFIX = "[Founder] "
MineConfig.VIP_AFK_MULT = 1.50
MineConfig.VIP_AFK_GEMS = 1
-- Paste Creator Dashboard ids when the passes exist. 0 = credits-only / hidden Robux.
MineConfig.COIN_DOUBLE_GAMEPASS_ID = 0
MineConfig.COIN_DOUBLE_ROBUX = 299
MineConfig.AUTO_MINE_GAMEPASS_ID = 0
MineConfig.AUTO_MINE_ROBUX = 499
MineConfig.AUTO_MINE_LICENSE_RATE = 1

--[[
	Three, for everyone, always.

	VIP used to add a fourth seat here and a saved petSlots could climb to eight.
	Both are gone: a pet seat is a multiplier on the whole gear stack, not a flat
	step, so selling them was the largest power gap in the game. The clamp is
	what retires them -- STARTER and MAX are both 3, so a save that bought its
	way up comes back down on load with every pet still owned.

	Kept as a function because every caller goes through it; when a seat count
	becomes situational again, this is where it belongs.
]]
function MineConfig.effectivePetSlots(p)
	return math.clamp(math.floor(tonumber(p and p.petSlots) or 3), 3, MineConfig.MAX_PET_SLOTS)
end

--[[
	THE ITEM BAG.

	Not the backpack -- that carries dirt and is a different ladder entirely.
	This is the shelf the Inventory screen draws from: pets and cards (a pet
	IS a card here, p.equipped holds pet card ids), packs, runes, temperaments
	and every found tool.

	500 slots to start, 100 more per upgrade, paid in gems on the same 1.08
	curve the bag ladder uses.
]]
MineConfig.ITEM_SLOTS_BASE = 500
MineConfig.ITEM_SLOTS_STEP = 100
MineConfig.ITEM_SLOT_GEM_BASE = 100
MineConfig.ITEM_SLOT_GEM_RATE = 1.08

-- One list, so adding a category later is a single line rather than a hunt
-- through three files. Gear, charms and potions are deliberately NOT here:
-- they are equipment slots, not shelf stock.
MineConfig.ITEM_BAG_FIELDS = {
	"cards", "packs", "runes", "tempers",
	"chestTools", "eventTools",
}

function MineConfig.itemSlotsUsed(p)
	if type(p) ~= "table" then
		return 0
	end
	local used = 0
	for _, field in ipairs(MineConfig.ITEM_BAG_FIELDS) do
		local t = p[field]
		if type(t) == "table" then
			-- Three shapes in play: arrays (cards, packs, runes, chestTools),
			-- id-keyed maps (eventTools) and maps whose value
			-- carries a copy count (tempers). Length first, then entries.
			local n = #t
			if n > 0 then
				used += n
			else
				for _, v in pairs(t) do
					local copies = (type(v) == "table" and tonumber(v.n))
						or (type(v) == "number" and v)
						or 1
					used += math.max(1, math.floor(copies))
				end
			end
		end
	end
	return used
end

function MineConfig.itemSlotUpgrades(p)
	return math.max(0, math.floor(tonumber(p and p.itemSlotUpgrades) or 0))
end

function MineConfig.itemSlotCap(p)
	return MineConfig.ITEM_SLOTS_BASE
		+ MineConfig.ITEM_SLOTS_STEP * MineConfig.itemSlotUpgrades(p)
end

-- Gems for the NEXT rung.
function MineConfig.itemSlotPrice(p)
	local x = MineConfig.itemSlotUpgrades(p)
	return math.floor(MineConfig.ITEM_SLOT_GEM_BASE * (MineConfig.ITEM_SLOT_GEM_RATE ^ x) + 0.5)
end

-- Founders Pack (limited membership). Dashboard: swap list to R$999.
-- Credits face 1000 — Vault (1200 cr / R$749) leaves ~200 cr after buying Founders.
MineConfig.FOUNDERS_GAMEPASS_ID = 1982786367
MineConfig.FOUNDERS_CREDITS = 799
MineConfig.FOUNDERS_ROBUX = 799
-- Community group for the lobby Group Wheel (free spin every 6h).
-- Paste your Roblox group id here or the wheel only works in Studio.
-- The Roblox group the wheel's free spin is gated on. 0 disables the gate.
MineConfig.GROUP_ID = 35326298
-- Max backpack multiplier from pets (1.80 = +80% capacity). Extra slots use ceil(base * mult).
MineConfig.WATER_BACKPACK_CAP = 1.80

-- Launch limiteds. productId = 0 until Creator Dashboard IDs are pasted.
-- Sale opens 2026-09-22 00:00 ET, same midnight as the season.
--
-- Face price is 1:1 — creditsPrice == robuxPrice. The deal is NOT an undercut:
-- bigger credit packs grant bonus credits, so the same face costs less real Robux
-- when you top up in bulk, then spend credits here.
MineConfig.LIMITED_SALE_OPENS_AT = 1790049600
--[[
	How many times one player may buy any single dev product with credits, ever.

	Most products refuse a second purchase on their own ("you already own Lucky
	Charm"), but the repeatable ones -- weekend_haul, pet_slot -- had no ceiling
	at all, and a credit balance is not a ceiling. The counter is per product key
	and survives rebirth (MineServer Verbs.KEEP_ON_REBIRTH), because a limit you
	can wipe by rebirthing is not a limit.
]]
MineConfig.CREDIT_BUY_LIMIT = 3

MineConfig.PRODUCTS = {
	patron_rig = { productId = 0, robuxPrice = 799, creditsPrice = 799 },
	lucky_charm = { productId = 0, robuxPrice = 599, creditsPrice = 599 },
	lucky_block_pet = { productId = 0, robuxPrice = 599, creditsPrice = 599 },
	deal_lucky_week = { productId = 0, robuxPrice = 599, creditsPrice = 599 },
	deal_pot_gold = { productId = 0, robuxPrice = 599, creditsPrice = 599 },
	-- One-time starter bundle, offered right after a player's first pack
	-- opening. Create a developer product at robuxPrice on the Creator
	-- Dashboard and paste its id here; at 0 the offer never shows.
	starter_bundle = {
		productId = 0,
		robuxPrice = 129,
		creditsPrice = 129,
		name = "Starter Crate",
		bagRung = 2,
		coins = 8000,
		commonPet = 1,
	},
	weekend_haul = {
		productId = 0,
		robuxPrice = 349,
		creditsPrice = 349,
		name = "Weekend Haul",
		packs = { { id = "heirloom_pack", qty = 1 }, { id = "shiny_pack", qty = 1 }, { id = "omen_pack", qty = 1 } },
		blocks = { { id = "lucky_block", qty = 1 } },
		potionId = "pot_t3_haul",
		potionQty = 1,
	},
	-- Group Wheel paid spins (1-week limited). Paste Creator Dashboard product ids.
	group_wheel_1 = { productId = 0, robuxPrice = 20, creditsPrice = 20, spins = 1, name = "1 Group Wheel Spin" },
	group_wheel_5 = { productId = 0, robuxPrice = 80, creditsPrice = 80, spins = 5, name = "5 Group Wheel Spins" },
	group_wheel_10 = { productId = 0, robuxPrice = 150, creditsPrice = 150, spins = 10, name = "10 Group Wheel Spins" },
	-- RETIRED. Three pet seats for everyone, so there is no seat to sell. Kept
	-- so an old client's row still resolves to a name instead of erroring; the
	-- buy path refuses it, and productId was never set, so nothing was ever sold.
	pet_slot = { productId = 0, robuxPrice = 199, creditsPrice = 199, name = "Extra Pet Seat (retired)" },
	coin_double = { productId = 0, gamePassId = 0, robuxPrice = 299, creditsPrice = 299, name = "2x Coins" },
	auto_mine = { productId = 0, gamePassId = 0, robuxPrice = 499, creditsPrice = 499, name = "Auto-Mine License" },
	-- Gamepass path uses FOUNDERS_GAMEPASS_ID; credits path uses creditsPrice.
	founders = {
		gamePassId = 1982786367,
		robuxPrice = 799,
		creditsPrice = 799,
	},
}

function MineConfig.product(key)
	return MineConfig.PRODUCTS and MineConfig.PRODUCTS[tostring(key or "")] or nil
end

-- Credits face for a product (defaults to Robux list — always 1:1 unless overridden).
function MineConfig.productCredits(key)
	local prod = MineConfig.product(key)
	if not prod then
		return nil
	end
	return tonumber(prod.creditsPrice) or tonumber(prod.robuxPrice)
end

function MineConfig.limitedSaleOpen()
	local t = tonumber(MineConfig.LIMITED_SALE_OPENS_AT) or 0
	if t <= 0 then
		return game:GetService("RunService"):IsStudio()
	end
	return os.time() >= t
end

do
	local prod = MineConfig.PRODUCTS and MineConfig.PRODUCTS.patron_rig
	if prod then
		for _, bp in ipairs(MineConfig.BACKPACKS or {}) do
			if bp.robux or bp.productKey == "patron_rig" then
				bp.productId = tonumber(prod.productId) or bp.productId or 0
				bp.robuxPrice = prod.robuxPrice or bp.robuxPrice
			end
		end
	end
end

-- Every value here is FIXED. A block's HP, coins and gems never depend on how
-- deep you are -- depth changes WHICH block you meet, not what it is worth.
-- Scaling both at once is what made a zone-6 clod of dirt worth 1,465 coins and
-- made every stat in the game impossible to reason about.
--
-- `rock = true` marks the base material of a zone: an obstacle, worth nothing.
-- You cut through it to reach ore, and ore is the entire economy.
-- Every value here is FIXED. A block's HP, coins and gems never depend on how
-- deep you are -- depth changes WHICH block you meet, not what it is worth.
-- Scaling both at once is what made a zone-6 clod of dirt worth 1,465 coins and
-- made every stat in the game impossible to reason about.
--
-- `rock = true` marks a zone's base material. Rock is the bulk of your haul and
-- about 70% of your income; the three ores in each zone are the other 30%, and
-- they are rare enough to be worth stopping for.
-- Every value here is FIXED. A block's HP and coins never depend on how deep
-- you are -- depth changes WHICH rock you are cutting, not what it is worth.
--
-- Rock is the whole of the bag economy. There are no ore blocks: the thing you
-- hope to see in the wall is a chest, and those are defined in MinePackConfig.
-- Rock HP doubles as its coin value, which keeps the old "one coin per point of
-- HP" rule as the single invariant in the economy.
MineConfig.BLOCKS = {
	-- Every ore shares one kind; WHICH ore is an attribute, exactly as a
	-- chest block carries which chest it is.
	-- Colour, material and HP are overridden per ore at spawn.
	ore = { name = "Ore", rock = true, hp = 3, coins = 3, gems = 0,
		color = Color3.fromRGB(150, 140, 110), material = Enum.Material.Metal },
	dirt = { name = "Dirt", rock = true, hp = 3, coins = 3, gems = 0,
		color = Color3.fromRGB(150, 110, 72), material = Enum.Material.Ground },
	stone = { name = "Stone", rock = true, hp = 18, coins = 18, gems = 0,
		color = Color3.fromRGB(126, 126, 130), material = Enum.Material.Slate },
	shale = { name = "Shale", rock = true, hp = 95, coins = 95, gems = 0,
		color = Color3.fromRGB(84, 96, 104), material = Enum.Material.Rock },
	granite = { name = "Granite", rock = true, hp = 520, coins = 520, gems = 0,
		color = Color3.fromRGB(118, 104, 96), material = Enum.Material.Concrete },
	basalt = { name = "Basalt", rock = true, hp = 2900, coins = 2900, gems = 0,
		color = Color3.fromRGB(58, 54, 60), material = Enum.Material.Basalt },
	obsidian = { name = "Obsidian", rock = true, hp = 16000, coins = 16000, gems = 0,
		color = Color3.fromRGB(34, 28, 44), material = Enum.Material.Glass },
	riftstone = { name = "Riftstone", rock = true, hp = 88000, coins = 88000, gems = 0,
		color = Color3.fromRGB(160, 150, 130), material = Enum.Material.Rock },
	stariron = { name = "Stariron", rock = true, hp = 484000, coins = 484000, gems = 0,
		color = Color3.fromRGB(90, 100, 140), material = Enum.Material.Metal },
	mythral = { name = "Mythral", rock = true, hp = 2660000, coins = 2660000, gems = 0,
		color = Color3.fromRGB(180, 190, 210), material = Enum.Material.Foil },
	primordium = { name = "Primordium", rock = true, hp = 14600000, coins = 14600000, gems = 0,
		color = Color3.fromRGB(40, 20, 50), material = Enum.Material.Basalt },
	aether = { name = "Aether", rock = true, hp = 8, coins = 8, gems = 0,
		color = Color3.fromRGB(220, 230, 255), material = Enum.Material.Glass },

	-- The generic chest block. Its LOOK is overridden per chest type at spawn,
	-- so a Void Chest and a Magpie Nest read differently in the wall.
	chest = { name = "Chest", chest = true, hp = 5, coins = 0, gems = 0,
		color = Color3.fromRGB(196, 140, 62), material = Enum.Material.WoodPlanks },
	lucky_block = { name = "Lucky Block", noHaul = true, hp = 8, coins = 0, gems = 0,
		color = Color3.fromRGB(255, 196, 64), material = Enum.Material.Neon },
	-- Bottom-of-mine core. 100 trillion HP; chips grant a core sample, full break
	-- grants the Geothermal Nuke. Does not fill the haul bag.
	core = { name = "Geothermal Core", rock = true, hp = 100000000000000, coins = 0, gems = 0,
		noHaul = true, color = Color3.fromRGB(20, 8, 28), material = Enum.Material.Neon },
}

-- Every 50 layers is a new zone, and a new zone is a new base rock.
MineConfig.STRATA = {
	{ zone = "meadow", rock = "dirt" },
	{ zone = "sunscar", rock = "stone" },
	{ zone = "mistreef", rock = "shale" },
	{ zone = "arcwork", rock = "granite" },
	{ zone = "bloodmoon", rock = "basalt" },
	{ zone = "eclipse", rock = "obsidian" },
	{ zone = "riftmarch", rock = "riftstone" },
	{ zone = "starfall", rock = "stariron" },
	{ zone = "mythral", rock = "mythral" },
	{ zone = "primordium", rock = "primordium" },
	{ zone = "bigbang", rock = "aether" },
}

-- Chest roster. GENERATED BY skills-src/genchests.js -- edit that, not this.
--
-- Thirty-six chests, six per zone, each declaring its own roll table in absolute
-- numbers. The directory shows these to the player once they have found one, so
-- they have to be readable: the ranges below are rounded to friendly steps
-- rather than left as raw arithmetic.
--
-- A chest is worth about 180x the rock around it on average, which is what
-- holds the 70/30 split between the bag you haul up and the chests you find.
-- Within a zone the six archetypes split that budget differently: a Piggybank is
-- almost all coins, a Geode almost all gems, and a Vault is a rare monster that
-- is mostly packs.
-- The three generic rungs, named from the real pack roster in Mine1PacksData.
-- "Common / Gilded / Astral" was the old system and nothing drops it now.
MineConfig.PACK_TIERS = { "Hopper Pack", "Magma Pack", "Apex Pack" }
MineConfig.PACK_TIER_ID = { "hopper_pack", "magma_pack", "apex_pack" }

MineConfig.CHEST_TYPES = {
	-- meadow
	{ id = "meadow_cache", name = "Sunken Cache", kind = "native", zone = 1, weight = 100,
		coins = { 100, 450 }, gems = { 5, 10 },
		packs = { { tier = 1, chance = 4 }, { tier = 2, chance = 0.8 }, { tier = 3, chance = 0.05 } } },
	{ id = "meadow_coffer", name = "Loam Coffer", kind = "native", zone = 1, weight = 64,
		coins = { 125, 475 }, gems = { 10, 40 },
		packs = { { tier = 1, chance = 6 }, { tier = 2, chance = 1.4 }, { tier = 3, chance = 0.1 } } },
	{ id = "meadow_bank", name = "Meadow Piggybank", kind = "currency", zone = 1, weight = 30,
		coins = { 350, 1500 }, gems = { 5, 15 },
		packs = { { tier = 1, chance = 0.5 }, { tier = 2, chance = 0.1 }, { tier = 3, chance = 0.01 } } },
	{ id = "meadow_geode", name = "Thistle Geode", kind = "currency", zone = 1, weight = 24,
		coins = { 60, 250 }, gems = { 45, 150 },
		packs = { { tier = 1, chance = 1 }, { tier = 2, chance = 0.2 }, { tier = 3, chance = 0.02 } } },
	{ id = "meadow_reliq", name = "Barrow Reliquary", kind = "variant", zone = 1, weight = 9,
		coins = { 375, 1500 }, gems = { 55, 200 },
		packs = { { tier = 1, chance = 14 }, { tier = 2, chance = 4.5 }, { tier = 3, chance = 0.6 } } },
	{ id = "meadow_vault", name = "Rootbound Vault", kind = "shape", zone = 1, weight = 3,
		coins = { 900, 3750 }, gems = { 125, 425 },
		packs = { { tier = 1, chance = 26 }, { tier = 2, chance = 9 }, { tier = 3, chance = 1.8 } } },
	-- sunscar
	{ id = "sunscar_cache", name = "Kiln Cache", kind = "native", zone = 2, weight = 100,
		coins = { 650, 2750 }, gems = { 5, 20 },
		packs = { { tier = 1, chance = 4 }, { tier = 2, chance = 0.8 }, { tier = 3, chance = 0.05 } } },
	{ id = "sunscar_coffer", name = "Cinder Coffer", kind = "native", zone = 2, weight = 64,
		coins = { 675, 3000 }, gems = { 15, 65 },
		packs = { { tier = 1, chance = 6 }, { tier = 2, chance = 1.4 }, { tier = 3, chance = 0.1 } } },
	{ id = "sunscar_bank", name = "Sunscar Piggybank", kind = "currency", zone = 2, weight = 30,
		coins = { 2250, 9000 }, gems = { 5, 20 },
		packs = { { tier = 1, chance = 0.5 }, { tier = 2, chance = 0.1 }, { tier = 3, chance = 0.01 } } },
	{ id = "sunscar_geode", name = "Ashfall Geode", kind = "currency", zone = 2, weight = 24,
		coins = { 375, 1500 }, gems = { 65, 250 },
		packs = { { tier = 1, chance = 1 }, { tier = 2, chance = 0.2 }, { tier = 3, chance = 0.02 } } },
	{ id = "sunscar_reliq", name = "Emberlit Reliquary", kind = "variant", zone = 2, weight = 9,
		coins = { 2250, 9500 }, gems = { 85, 300 },
		packs = { { tier = 1, chance = 14 }, { tier = 2, chance = 4.5 }, { tier = 3, chance = 0.6 } } },
	{ id = "sunscar_vault", name = "Slagborn Vault", kind = "shape", zone = 2, weight = 3,
		coins = { 5500, 22500 }, gems = { 175, 625 },
		packs = { { tier = 1, chance = 26 }, { tier = 2, chance = 9 }, { tier = 3, chance = 1.8 } } },
	-- mistreef
	{ id = "mistreef_cache", name = "Tidelocked Cache", kind = "native", zone = 3, weight = 100,
		coins = { 3500, 15000 }, gems = { 5, 25 },
		packs = { { tier = 1, chance = 4 }, { tier = 2, chance = 0.8 }, { tier = 3, chance = 0.05 } } },
	{ id = "mistreef_coffer", name = "Mistreef Coffer", kind = "native", zone = 3, weight = 64,
		coins = { 3500, 15000 }, gems = { 25, 95 },
		packs = { { tier = 1, chance = 6 }, { tier = 2, chance = 1.4 }, { tier = 3, chance = 0.1 } } },
	{ id = "mistreef_bank", name = "Brackish Piggybank", kind = "currency", zone = 3, weight = 30,
		coins = { 12500, 47500 }, gems = { 10, 30 },
		packs = { { tier = 1, chance = 0.5 }, { tier = 2, chance = 0.1 }, { tier = 3, chance = 0.01 } } },
	{ id = "mistreef_geode", name = "Coralcut Geode", kind = "currency", zone = 3, weight = 24,
		coins = { 2000, 8250 }, gems = { 100, 350 },
		packs = { { tier = 1, chance = 1 }, { tier = 2, chance = 0.2 }, { tier = 3, chance = 0.02 } } },
	{ id = "mistreef_reliq", name = "Fogbound Reliquary", kind = "variant", zone = 3, weight = 9,
		coins = { 12500, 50000 }, gems = { 125, 475 },
		packs = { { tier = 1, chance = 14 }, { tier = 2, chance = 4.5 }, { tier = 3, chance = 0.6 } } },
	{ id = "mistreef_vault", name = "Saltworn Vault", kind = "shape", zone = 3, weight = 3,
		coins = { 30000, 122500 }, gems = { 250, 925 },
		packs = { { tier = 1, chance = 26 }, { tier = 2, chance = 9 }, { tier = 3, chance = 1.8 } } },
	-- arcwork
	{ id = "arcwork_cache", name = "Live-Wire Cache", kind = "native", zone = 4, weight = 100,
		coins = { 17500, 77500 }, gems = { 10, 40 },
		packs = { { tier = 1, chance = 4 }, { tier = 2, chance = 0.8 }, { tier = 3, chance = 0.05 } } },
	{ id = "arcwork_coffer", name = "Arcwork Coffer", kind = "native", zone = 4, weight = 64,
		coins = { 20000, 82500 }, gems = { 40, 150 },
		packs = { { tier = 1, chance = 6 }, { tier = 2, chance = 1.4 }, { tier = 3, chance = 0.1 } } },
	{ id = "arcwork_bank", name = "Dynamo Piggybank", kind = "currency", zone = 4, weight = 30,
		coins = { 62500, 262500 }, gems = { 15, 50 },
		packs = { { tier = 1, chance = 0.5 }, { tier = 2, chance = 0.1 }, { tier = 3, chance = 0.01 } } },
	{ id = "arcwork_geode", name = "Filament Geode", kind = "currency", zone = 4, weight = 24,
		coins = { 10000, 45000 }, gems = { 150, 550 },
		packs = { { tier = 1, chance = 1 }, { tier = 2, chance = 0.2 }, { tier = 3, chance = 0.02 } } },
	{ id = "arcwork_reliq", name = "Overvolt Reliquary", kind = "variant", zone = 4, weight = 9,
		coins = { 65000, 272500 }, gems = { 200, 700 },
		packs = { { tier = 1, chance = 14 }, { tier = 2, chance = 4.5 }, { tier = 3, chance = 0.6 } } },
	{ id = "arcwork_vault", name = "Coilspun Vault", kind = "shape", zone = 4, weight = 3,
		coins = { 157500, 667500 }, gems = { 375, 1500 },
		packs = { { tier = 1, chance = 26 }, { tier = 2, chance = 9 }, { tier = 3, chance = 1.8 } } },
	-- bloodmoon
	{ id = "bloodmoon_cache", name = "Carrion Cache", kind = "native", zone = 5, weight = 100,
		coins = { 102500, 437500 }, gems = { 15, 60 },
		packs = { { tier = 1, chance = 4 }, { tier = 2, chance = 0.8 }, { tier = 3, chance = 0.05 } } },
	{ id = "bloodmoon_coffer", name = "Bloodmoon Coffer", kind = "native", zone = 5, weight = 64,
		coins = { 110000, 462500 }, gems = { 60, 225 },
		packs = { { tier = 1, chance = 6 }, { tier = 2, chance = 1.4 }, { tier = 3, chance = 0.1 } } },
	{ id = "bloodmoon_bank", name = "Gravebound Piggybank", kind = "currency", zone = 5, weight = 30,
		coins = { 345000, 1500000 }, gems = { 20, 70 },
		packs = { { tier = 1, chance = 0.5 }, { tier = 2, chance = 0.1 }, { tier = 3, chance = 0.01 } } },
	{ id = "bloodmoon_geode", name = "Hollowed Geode", kind = "currency", zone = 5, weight = 24,
		coins = { 60000, 252500 }, gems = { 225, 800 },
		packs = { { tier = 1, chance = 1 }, { tier = 2, chance = 0.2 }, { tier = 3, chance = 0.02 } } },
	{ id = "bloodmoon_reliq", name = "Ruinous Reliquary", kind = "variant", zone = 5, weight = 9,
		coins = { 360000, 1500000 }, gems = { 275, 1000 },
		packs = { { tier = 1, chance = 14 }, { tier = 2, chance = 4.5 }, { tier = 3, chance = 0.6 } } },
	{ id = "bloodmoon_vault", name = "Wailing Vault", kind = "shape", zone = 5, weight = 3,
		coins = { 880000, 3750000 }, gems = { 575, 2000 },
		packs = { { tier = 1, chance = 26 }, { tier = 2, chance = 9 }, { tier = 3, chance = 1.8 } } },
	-- eclipse
	{ id = "eclipse_cache", name = "Eclipse Cache", kind = "native", zone = 6, weight = 100,
		coins = { 570000, 2500000 }, gems = { 25, 95 },
		packs = { { tier = 1, chance = 4 }, { tier = 2, chance = 0.8 }, { tier = 3, chance = 0.05 } } },
	{ id = "eclipse_coffer", name = "Umbral Coffer", kind = "native", zone = 6, weight = 64,
		coins = { 605000, 2500000 }, gems = { 85, 325 },
		packs = { { tier = 1, chance = 6 }, { tier = 2, chance = 1.4 }, { tier = 3, chance = 0.1 } } },
	{ id = "eclipse_bank", name = "Starless Piggybank", kind = "currency", zone = 6, weight = 30,
		coins = { 2000000, 8000000 }, gems = { 30, 100 },
		packs = { { tier = 1, chance = 0.5 }, { tier = 2, chance = 0.1 }, { tier = 3, chance = 0.01 } } },
	{ id = "eclipse_geode", name = "Voidcut Geode", kind = "currency", zone = 6, weight = 24,
		coins = { 330000, 1500000 }, gems = { 325, 1250 },
		packs = { { tier = 1, chance = 1 }, { tier = 2, chance = 0.2 }, { tier = 3, chance = 0.02 } } },
	{ id = "eclipse_reliq", name = "Lastlight Reliquary", kind = "variant", zone = 6, weight = 9,
		coins = { 2000000, 8250000 }, gems = { 425, 1500 },
		packs = { { tier = 1, chance = 14 }, { tier = 2, chance = 4.5 }, { tier = 3, chance = 0.6 } } },
	{ id = "eclipse_vault", name = "Endfall Vault", kind = "shape", zone = 6, weight = 3,
		coins = { 4750000, 20500000 }, gems = { 850, 3250 },
		packs = { { tier = 1, chance = 26 }, { tier = 2, chance = 9 }, { tier = 3, chance = 1.8 } } },
	-- riftmarch
	{ id = "riftmarch_cache", name = "Rift Cache", kind = "native", zone = 7, weight = 100,
		coins = { 3250000, 13250000 }, gems = { 40, 150 },
		packs = { { tier = 1, chance = 4 }, { tier = 2, chance = 0.8 }, { tier = 3, chance = 0.05 } } },
	{ id = "riftmarch_coffer", name = "Scar Coffer", kind = "native", zone = 7, weight = 64,
		coins = { 3250000, 14000000 }, gems = { 125, 475 },
		packs = { { tier = 1, chance = 6 }, { tier = 2, chance = 1.4 }, { tier = 3, chance = 0.1 } } },
	{ id = "riftmarch_bank", name = "Fault Piggybank", kind = "currency", zone = 7, weight = 30,
		coins = { 10500000, 44250000 }, gems = { 45, 150 },
		packs = { { tier = 1, chance = 0.5 }, { tier = 2, chance = 0.1 }, { tier = 3, chance = 0.01 } } },
	{ id = "riftmarch_geode", name = "Schism Geode", kind = "currency", zone = 7, weight = 24,
		coins = { 1750000, 7750000 }, gems = { 500, 1750 },
		packs = { { tier = 1, chance = 1 }, { tier = 2, chance = 0.2 }, { tier = 3, chance = 0.02 } } },
	{ id = "riftmarch_reliq", name = "Tearbound Reliquary", kind = "variant", zone = 7, weight = 9,
		coins = { 11000000, 46000000 }, gems = { 650, 2250 },
		packs = { { tier = 1, chance = 14 }, { tier = 2, chance = 4.5 }, { tier = 3, chance = 0.6 } } },
	{ id = "riftmarch_vault", name = "Marchvault Vault", kind = "shape", zone = 7, weight = 3,
		coins = { 26750000, 112750000 }, gems = { 1250, 4750 },
		packs = { { tier = 1, chance = 26 }, { tier = 2, chance = 9 }, { tier = 3, chance = 1.8 } } },
	-- starfall
	{ id = "starfall_cache", name = "Meteor Cache", kind = "native", zone = 8, weight = 100,
		coins = { 17250000, 72750000 }, gems = { 55, 200 },
		packs = { { tier = 1, chance = 4 }, { tier = 2, chance = 0.8 }, { tier = 3, chance = 0.05 } } },
	{ id = "starfall_coffer", name = "Barrens Coffer", kind = "native", zone = 8, weight = 64,
		coins = { 18250000, 77500000 }, gems = { 200, 725 },
		packs = { { tier = 1, chance = 6 }, { tier = 2, chance = 1.4 }, { tier = 3, chance = 0.1 } } },
	{ id = "starfall_bank", name = "Nova Piggybank", kind = "currency", zone = 8, weight = 30,
		coins = { 57750000, 243750000 }, gems = { 65, 250 },
		packs = { { tier = 1, chance = 0.5 }, { tier = 2, chance = 0.1 }, { tier = 3, chance = 0.01 } } },
	{ id = "starfall_geode", name = "Stardust Geode", kind = "currency", zone = 8, weight = 24,
		coins = { 10000000, 42250000 }, gems = { 750, 2750 },
		packs = { { tier = 1, chance = 1 }, { tier = 2, chance = 0.2 }, { tier = 3, chance = 0.02 } } },
	{ id = "starfall_reliq", name = "Orbit Reliquary", kind = "variant", zone = 8, weight = 9,
		coins = { 60000000, 253250000 }, gems = { 950, 3500 },
		packs = { { tier = 1, chance = 14 }, { tier = 2, chance = 4.5 }, { tier = 3, chance = 0.6 } } },
	{ id = "starfall_vault", name = "Skyvault Vault", kind = "shape", zone = 8, weight = 3,
		coins = { 147000000, 620750000 }, gems = { 2000, 7000 },
		packs = { { tier = 1, chance = 26 }, { tier = 2, chance = 9 }, { tier = 3, chance = 1.8 } } },
	-- mythral
	{ id = "mythral_cache", name = "Mythral Cache", kind = "native", zone = 9, weight = 100,
		coins = { 94750000, 400250000 }, gems = { 85, 325 },
		packs = { { tier = 1, chance = 4 }, { tier = 2, chance = 0.8 }, { tier = 3, chance = 0.05 } } },
	{ id = "mythral_coffer", name = "Catacomb Coffer", kind = "native", zone = 9, weight = 64,
		coins = { 100750000, 425250000 }, gems = { 300, 1000 },
		packs = { { tier = 1, chance = 6 }, { tier = 2, chance = 1.4 }, { tier = 3, chance = 0.1 } } },
	{ id = "mythral_bank", name = "Silver Piggybank", kind = "currency", zone = 9, weight = 30,
		coins = { 317250000, 1250000000 }, gems = { 100, 375 },
		packs = { { tier = 1, chance = 0.5 }, { tier = 2, chance = 0.1 }, { tier = 3, chance = 0.01 } } },
	{ id = "mythral_geode", name = "Relic Geode", kind = "currency", zone = 9, weight = 24,
		coins = { 55000000, 232000000 }, gems = { 1000, 4000 },
		packs = { { tier = 1, chance = 1 }, { tier = 2, chance = 0.2 }, { tier = 3, chance = 0.02 } } },
	{ id = "mythral_reliq", name = "Choir Reliquary", kind = "variant", zone = 9, weight = 9,
		coins = { 329750000, 1500000000 }, gems = { 1500, 5250 },
		packs = { { tier = 1, chance = 14 }, { tier = 2, chance = 4.5 }, { tier = 3, chance = 0.6 } } },
	{ id = "mythral_vault", name = "Cryptvault Vault", kind = "shape", zone = 9, weight = 3,
		coins = { 808000000, 3500000000 }, gems = { 3000, 10000 },
		packs = { { tier = 1, chance = 26 }, { tier = 2, chance = 9 }, { tier = 3, chance = 1.8 } } },
	-- primordium
	{ id = "primordium_cache", name = "Primordium Cache", kind = "native", zone = 10, weight = 100,
		coins = { 520250000, 2250000000 }, gems = { 125, 475 },
		packs = { { tier = 1, chance = 4 }, { tier = 2, chance = 0.8 }, { tier = 3, chance = 0.05 } } },
	{ id = "primordium_coffer", name = "Heart Coffer", kind = "native", zone = 10, weight = 64,
		coins = { 552750000, 2250000000 }, gems = { 450, 1750 },
		packs = { { tier = 1, chance = 6 }, { tier = 2, chance = 1.4 }, { tier = 3, chance = 0.1 } } },
	{ id = "primordium_bank", name = "First Piggybank", kind = "currency", zone = 10, weight = 30,
		coins = { 1750000000, 7250000000 }, gems = { 150, 550 },
		packs = { { tier = 1, chance = 0.5 }, { tier = 2, chance = 0.1 }, { tier = 3, chance = 0.01 } } },
	{ id = "primordium_geode", name = "Bloodore Geode", kind = "currency", zone = 10, weight = 24,
		coins = { 301500000, 1250000000 }, gems = { 1750, 6250 },
		packs = { { tier = 1, chance = 1 }, { tier = 2, chance = 0.2 }, { tier = 3, chance = 0.02 } } },
	{ id = "primordium_reliq", name = "Genesis Reliquary", kind = "variant", zone = 10, weight = 9,
		coins = { 1750000000, 7750000000 }, gems = { 2250, 8000 },
		packs = { { tier = 1, chance = 14 }, { tier = 2, chance = 4.5 }, { tier = 3, chance = 0.6 } } },
	{ id = "primordium_vault", name = "Endvault Vault", kind = "shape", zone = 10, weight = 3,
		coins = { 4500000000, 18750000000 }, gems = { 4250, 15000 },
		packs = { { tier = 1, chance = 26 }, { tier = 2, chance = 9 }, { tier = 3, chance = 1.8 } } },
	-- bigbang
	{ id = "bigbang_cache", name = "Proto Cache", kind = "native", zone = 11, weight = 100,
		coins = { 275, 1250 }, gems = { 5, 15 },
		packs = { { tier = 1, chance = 4 }, { tier = 2, chance = 0.8 }, { tier = 3, chance = 0.05 } } },
	{ id = "bigbang_coffer", name = "Spark Coffer", kind = "native", zone = 11, weight = 64,
		coins = { 300, 1250 }, gems = { 15, 55 },
		packs = { { tier = 1, chance = 6 }, { tier = 2, chance = 1.4 }, { tier = 3, chance = 0.1 } } },
	{ id = "bigbang_bank", name = "Genesis Piggybank", kind = "currency", zone = 11, weight = 30,
		coins = { 950, 4000 }, gems = { 5, 20 },
		packs = { { tier = 1, chance = 0.5 }, { tier = 2, chance = 0.1 }, { tier = 3, chance = 0.01 } } },
	{ id = "bigbang_geode", name = "Firstlight Geode", kind = "currency", zone = 11, weight = 24,
		coins = { 175, 700 }, gems = { 60, 225 },
		packs = { { tier = 1, chance = 1 }, { tier = 2, chance = 0.2 }, { tier = 3, chance = 0.02 } } },
	{ id = "bigbang_reliq", name = "Singularity Reliquary", kind = "variant", zone = 11, weight = 9,
		coins = { 1000, 4250 }, gems = { 75, 275 },
		packs = { { tier = 1, chance = 14 }, { tier = 2, chance = 4.5 }, { tier = 3, chance = 0.6 } } },
	{ id = "bigbang_vault", name = "Bangvault Vault", kind = "shape", zone = 11, weight = 3,
		coins = { 2500, 10000 }, gems = { 150, 550 },
		packs = { { tier = 1, chance = 26 }, { tier = 2, chance = 9 }, { tier = 3, chance = 1.8 } } },
}

function MineConfig.chestsIn(zoneTier)
	local out = {}
	for _, c in ipairs(MineConfig.CHEST_TYPES) do
		if c.zone == zoneTier then
			table.insert(out, c)
		end
	end
	return out
end

function MineConfig.chestType(id)
	for _, c in ipairs(MineConfig.CHEST_TYPES) do
		if c.id == id then
			return c
		end
	end
	return nil
end

--[[
	Pick a chest for this zone. `luck` lifts the rare archetypes, which are the
	ones with the small weights and the big budgets.
]]
function MineConfig.rollChestType(zoneTier, rng, luck)
	local pool = MineConfig.chestsIn(zoneTier)
	if #pool == 0 then
		pool = MineConfig.chestsIn(1)
	end
	luck = luck or 1
	local total, weights = 0, {}
	for i, c in ipairs(pool) do
		-- A weight under 40 is a rare chest; luck bites there and nowhere else,
		-- so luck cannot simply print more of the common ones.
		local wgt = c.weight < 40 and (c.weight * luck) or c.weight
		weights[i] = wgt
		total += wgt
	end
	local pick = (rng and rng:NextNumber() or math.random()) * total
	for i, c in ipairs(pool) do
		pick -= weights[i]
		if pick <= 0 then
			return c
		end
	end
	return pool[1]
end

function MineConfig.strataFor(zoneId)
	for _, s in ipairs(MineConfig.STRATA) do
		if s.zone == zoneId then
			return s
		end
	end
	return MineConfig.STRATA[1]
end

-- How a chest block looks, by the kind of chest it is. Colour is the only tell
-- you get from across a shaft, so the four kinds have to be distinct.
MineConfig.CHEST_LOOK = {
	native = { color = Color3.fromRGB(186, 132, 60), material = Enum.Material.WoodPlanks },
	shape = { color = Color3.fromRGB(90, 170, 255), material = Enum.Material.Metal },
	currency = { color = Color3.fromRGB(255, 206, 92), material = Enum.Material.Foil },
	variant = { color = Color3.fromRGB(178, 110, 255), material = Enum.Material.Neon },
}

-- One block in two hundred is a chest. Rarer than the ore it replaces, because
-- a chest is meant to be the thing you stop for.
MineConfig.CHEST_CHANCE = 0.003 -- ~1.3 chests / layer on 21x21; ~20 an hour of steady digging (see MineZoneChests GEM PACING)
-- Shallow Meadow (first 100 layers) doubles it again: the tutorial asks for three chests,
-- and a new player should meet them inside their first ten minutes.
MineConfig.MEADOW_SHALLOW_CHEST_MULT = 2
-- Pit lucky cubes. 1 in 5,000. Mix 80/15/5 gold/diamond/mythic. Not 3× in bigbang.
MineConfig.LUCKY_BLOCK_CHANCE = 0.00020
--[[
	Cap on the ORE FINDER a legacy ore pack may apply when it is banked or
	opened.

	A pack stamped its finder at break time, so the number it carries can be
	whatever a pet stack was worth that day -- and upgrade costs are sized in
	HOURS of supply, so an uncapped multiplier on an old pack is a shortcut past
	the cost curve rather than a nicer drop. 1.0 holds the best case to 2x
	unboosted (the payout is `amount * (1 + find)`).

	MineServer read this with an `or 1` fallback while the constant did not
	exist, so the behaviour is unchanged -- the knob is just real now.
]]
MineConfig.ORE_PACK_FIND_CAP = 1.0

--[[
	Most items one bulk-recycle batch may carry.

	Shared because BOTH SIDES need it. The server truncates the id list at this
	many before pricing, and the Select UI has to clamp to the same number --
	otherwise a player ticks a stack of 300, is quoted 200, and the two disagree
	about what they just approved. One number, read by both.
]]
MineConfig.SCRAP_MAX = 200




MineConfig.ZONES = {
	{
		-- Sit the starter pit out on the lobby lawn's +Z side so spawn-to-mine
		-- is a walk, not a teleport. `island` is smaller than the far-zone
		-- plates so the dirt does not swallow the shops.
		--
		-- Was 200, which put the island edge at Z 128 against a lobby deck
		-- that ends at 135 -- the two overlapped, and WorldBuilder's gate
		-- (origin - dir * (island - 8)) landed at Z 136, right on the deck
		-- rim. The pit's near edge was also being clipped by LOBBY_MAX.Z=150.
		-- At 300 the gate sits at 236 and the island starts at 228, clear of
		-- both, and the approach reads as a road instead of a doorstep.
		radius = 300,
		island = 72,
		id = "meadow",
		name = "Dirt Meadow",
		prestige = 0,
		minRebirth = 0,
		buyCost = 0,
		sets = { "dragons_dawn", "grass_glimmer", "prism_meadow" },
		color = Color3.fromRGB(150, 110, 72),
		dirt = Color3.fromRGB(150, 110, 72),
		ground = Enum.Material.Ground,
		accent = Enum.Material.Slate,
		decor = "trees",
		angle = 0,
	},
	{
		radius = 6000,
		id = "sunscar",
		-- Player-facing: Greyvein Quarry (stone after meadow). Id stays sunscar for saves.
		name = "Greyvein Quarry",
		prestige = 0,
		minRebirth = 0,
		buyCost = 7500,
		sets = { "iron_empire", "fire_sunscar", "cinder_vault" },
		color = Color3.fromRGB(120, 132, 148),
		dirt = Color3.fromRGB(88, 94, 104),
		ground = Enum.Material.Slate,
		accent = Enum.Material.Rock,
		decor = "spikes",
		angle = 36,
	},
	{
		radius = 6400,
		id = "mistreef",
		name = "Mistreef Depths",
		prestige = 1,
		minRebirth = 1,
		buyCost = 11500,
		sets = { "water_mistreef", "rock_verdantthrone", "deepwave_surge" },
		color = Color3.fromRGB(60, 170, 200),
		dirt = Color3.fromRGB(50, 110, 140),
		ground = Enum.Material.Glacier,
		accent = Enum.Material.Ice,
		decor = "pools",
		angle = 72,
	},
	{
		radius = 6200,
		id = "arcwork",
		name = "Arcwork Veins",
		prestige = 2,
		minRebirth = 2,
		buyCost = 27500,
		sets = { "electric_arcwork", "crystal_astralbloom", "nova_circuit" },
		color = Color3.fromRGB(255, 220, 70),
		dirt = Color3.fromRGB(80, 70, 40),
		ground = Enum.Material.Salt,
		accent = Enum.Material.Limestone,
		decor = "bolts",
		angle = 108,
	},
	{
		radius = 6600,
		id = "bloodmoon",
		name = "Bloodmoon Hollow",
		prestige = 3,
		minRebirth = 3,
		buyCost = 55000,
		sets = { "metal_steelforge", "shadow_bloodmoon", "stormreach" },
		color = Color3.fromRGB(180, 70, 200),
		dirt = Color3.fromRGB(50, 30, 70),
		ground = Enum.Material.Slate,
		accent = Enum.Material.CrackedLava,
		decor = "orbs",
		angle = 144,
	},
	{
		radius = 6300,
		id = "eclipse",
		name = "Eclipse Core",
		prestige = 4,
		minRebirth = 4,
		buyCost = 105000,
		sets = { "aurora_crown", "nebula_vault", "eclipse_ascendant" },
		color = Color3.fromRGB(30, 20, 40),
		dirt = Color3.fromRGB(20, 16, 28),
		ground = Enum.Material.Basalt,
		accent = Enum.Material.Asphalt,
		decor = "ring",
		angle = 180,
	},
	{
		radius = 6800,
		id = "riftmarch",
		name = "Riftmarch Scarps",
		prestige = 5,
		minRebirth = 5,
		buyCost = 170000,
		sets = { "rift_chorus", "scar_legion", "faultline_opera" },
		color = Color3.fromRGB(160, 150, 130),
		dirt = Color3.fromRGB(140, 120, 100),
		ground = Enum.Material.Rock,
		accent = Enum.Material.Slate,
		decor = "spikes",
		angle = 216,
	},
	{
		radius = 7000,
		id = "starfall",
		name = "Starfall Barrens",
		prestige = 6,
		minRebirth = 6,
		buyCost = 360000,
		sets = { "starfall_siege", "void_meteor", "astral_drysea" },
		color = Color3.fromRGB(90, 100, 140),
		dirt = Color3.fromRGB(70, 80, 120),
		ground = Enum.Material.Asphalt,
		accent = Enum.Material.Foil,
		decor = "ring",
		angle = 252,
	},
	{
		radius = 7200,
		id = "mythral",
		name = "Mythral Catacombs",
		prestige = 7,
		minRebirth = 7,
		buyCost = 520000,
		sets = { "brutalcrusher", "catacomb_kings", "silver_afterlife" },
		color = Color3.fromRGB(180, 190, 210),
		dirt = Color3.fromRGB(160, 170, 190),
		ground = Enum.Material.Limestone,
		accent = Enum.Material.Foil,
		decor = "orbs",
		angle = 288,
	},
	{
		radius = 7400,
		id = "primordium",
		name = "Primordium Heart",
		prestige = 8,
		minRebirth = 8,
		buyCost = 880000,
		sets = { "first_flame", "heartblood", "end_of_ore" },
		color = Color3.fromRGB(40, 20, 50),
		dirt = Color3.fromRGB(30, 12, 40),
		ground = Enum.Material.Basalt,
		accent = Enum.Material.CrackedLava,
		decor = "ring",
		angle = 324,
	},
	-- Limited 30-day event mine: start of the world. Free while live; not on the gem buy ladder.
	{
		radius = 9000,
		id = "bigbang",
		name = "Event Horizon",
		prestige = 0,
		minRebirth = 0,
		buyCost = 0,
		limited = true,
		-- Chests three times as common as anywhere else: it is an event.
		chestMult = 3,
		sets = { "genesis_spark", "first_light", "proto_ore" },
		color = Color3.fromRGB(220, 230, 255),
		dirt = Color3.fromRGB(200, 210, 240),
		ground = Enum.Material.Glacier,
		accent = Enum.Material.Glass,
		decor = "ring",
		angle = 18,
	},
}

MineConfig.MACHINES = {
	{ id = "sell", name = "Sell Ores", color = Color3.fromRGB(255, 210, 70) },
	{ id = "open", name = "Open Packs", color = Color3.fromRGB(255, 110, 160) },
	{ id = "binder", name = "Binder", color = Color3.fromRGB(120, 180, 255) },
	{ id = "merge", name = "Merge", color = Color3.fromRGB(180, 120, 255) },
	{ id = "dust", name = "Salvage / Power", color = Color3.fromRGB(160, 220, 120) },
	{ id = "shop", name = "Shop", color = Color3.fromRGB(255, 160, 80) },
	{ id = "prestige", name = "Prestige", color = Color3.fromRGB(255, 80, 140) },
}

function MineConfig.zoneById(id)
	for _, z in ipairs(MineConfig.ZONES) do
		if z.id == id then
			return z
		end
	end
	return MineConfig.ZONES[1]
end

function MineConfig.setForLayer(zone, layer)
	local idx = 1
	local deep = MineConfig.LAYERS
	if layer >= deep * 0.6 then
		idx = 3
	elseif layer >= deep * 0.25 then
		idx = 2
	end
	return zone.sets[idx] or zone.sets[1]
end

function MineConfig.nextVariant(variant)
	if variant == "Shiny" then
		-- Shiny stopped being a rung; an old Shiny card merges into Golden.
		variant = "Normal"
	end
	for i, v in ipairs(MineConfig.VARIANTS) do
		if v == variant then
			return MineConfig.VARIANTS[i + 1]
		end
	end
	return nil
end

function MineConfig.prestigeYield(prestige)
	return 1 + 0.15 * (prestige or 0)
end

function MineConfig.prestigeLuck(prestige)
	return 1 + 0.05 * (prestige or 0)
end

function MineConfig.cardPower(card)
	local r = MineConfig.RARITY_MULT[card.rarityId] or 1
	local v = MineConfig.VARIANT_MULT[card.variant or "Normal"] or 1
	local s = (card.shadow and MineConfig.SHADOW_MULT) or (card.shiny and MineConfig.SHINY_MULT) or 1
	local p = 1 + 0.04 * ((card.powerLevel or 1) - 1)
	return r * v * s * p
end

function MineConfig.salvageDust(card)
	local base = MineConfig.RARITY_DUST[card.rarityId] or 8
	local v = MineConfig.VARIANT_MULT[card.variant or "Normal"] or 1
	local s = (card.shadow and MineConfig.SHADOW_MULT) or (card.shiny and MineConfig.SHINY_MULT) or 1
	return math.floor(base * v * s * (1 + 0.1 * ((card.powerLevel or 1) - 1)))
end

function MineConfig.powerDustCost(level)
	return MineConfig.POWER_DUST * (level or 1)
end

-- VIP spend: cost × 0.9, floor at 1 when cost > 0.
function MineConfig.vipPrice(cost, _isVip)
	return math.max(0, math.floor(tonumber(cost) or 0))
end

-- VIP earn (scrap/sell dust or credits): payout × 1.1, floored.
function MineConfig.vipPayout(amount, _isVip)
	return math.max(0, math.floor(tonumber(amount) or 0))
end

--------------------------------------------------------------------------------
-- BLOCK HP SCALING
--
-- BLOCKS carries a BASE hp -- the value for zone 1, layer 1. Without scaling it
-- the ore table tops out at 28, so every tool from about the eighth rung up
-- one-shots everything and the top of a 25-step ladder mines at exactly the
-- speed of a 3,400-coin Steel Pick. Depth is what makes the ladder mean
-- anything.
--------------------------------------------------------------------------------

-- Dead constants. Do not revive 2.5^(tier-1)*(1+14*(layer-1)/49).
-- Meadow + Event Horizon HP is dirtHp / sectionHpMult (see below).
MineConfig.HP_ZONE = 2.5
MineConfig.HP_DEPTH = 14.0

-- Zones carry `prestige` (0-based) rather than a tier, and sit in order.
function MineConfig.zoneTier(zone)
	if type(zone) == "number" then
		return zone
	end
	if type(zone) == "table" then
		if zone.tier then
			return zone.tier
		end
		if zone.prestige then
			return zone.prestige + 1
		end
	end
	return 1
end

-- Multiplier vs layer-1 dirt. Replaces 2.5^(tier-1)*(1+14*(layer-1)/49).
function MineConfig.hpScale(_zone, layer)
	local base = MineConfig.DIRT_HP_BASE or 10
	return MineConfig.dirtHp(layer or 1) / base
end

-- `mult` is the zone's own blockHp mod, if it has one (Fastcut Seam runs 0.4).
function MineConfig.blockHp(kind, zone, layer)
	if kind == "core" then
		local spec = MineConfig.BLOCKS.core
		return math.max(1, (spec and spec.hp) or 100000000000000)
	end
	local zoneId = type(zone) == "table" and zone.id or zone
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local zi = 1
	for i, z in ipairs(MineConfig.ZONES or {}) do
		if z.id == zoneId then zi = i break end
	end
	--[[
		Event Horizon sits ABOVE Primordium, not beside Meadow.

		This read `zi = 1`, which pinned the limited event mine to meadow
		hardness. Harmless when ore did not exist; not harmless now, because the
		ore roll reads hardness -- so the endgame event zone was handing out
		Stone and Cobblestone while its own ore list runs Bridgmanite to
		Oganesson. Index 11 puts its rock one zone step past Primordium, which
		is what the rest of its content already assumes.
	]]
	if zoneId == "bigbang" then
		zi = 11
	end
	local dirt = Depth.dirtHp(zi, layer)
	if kind == "chest" or kind == "crate" or kind == "lucky_block" then
		return math.max(1, math.floor(dirt * (MineConfig.CHEST_HP_MULT or 2) + 0.5))
	end
	return dirt
end

--------------------------------------------------------------------------------
-- WHAT A BLOCK PAYS
--
-- Two currencies, two jobs:
--
--   COINS are payment for WORK -- exactly one coin per point of block HP, on
--   every block including plain dirt. Dig a 41,000 HP crystal and you are paid
--   41,000, dig a 52 HP clod of dirt and you are paid 52. Coins buy tools, so
--   tool prices are really "how much rock is this worth".
--
--   GEMS are what ore is FOR. Only ore drops them, and they scale faster with
--   depth than HP does (2.2/14 against HP's 2.5/14 per zone), so hunting ore
--   stays worth the detour instead of being a slower way to earn coins.
--
-- `hp` and `sell` in BLOCKS are both the zone 1, layer 1 values. Depth is what
-- makes a 25-rung tool ladder mean anything.
--------------------------------------------------------------------------------

MineConfig.VAL_ZONE = 2.2
MineConfig.VAL_DEPTH = 14.0

function MineConfig.valueScale(zone, layer)
	local tier = math.max(1, MineConfig.zoneTier(zone))
	local deep = math.max(2, MineConfig.LAYERS)
	local t = (math.clamp(layer or 1, 1, deep) - 1) / (deep - 1)
	return (MineConfig.VAL_ZONE ^ (tier - 1)) * (1 + t * MineConfig.VAL_DEPTH)
end

-- One coin per point of HP. Every block, no exceptions -- this is the whole
-- coin economy. Coins used to come only from dirt, and the ore mix squeezes
-- dirt out entirely by layer 50, so a deep player earned nothing at all.
function MineConfig.coinsFor(kind, mult)
	-- Base rock pays nothing: it is the obstacle, not the reward.
	local spec = MineConfig.BLOCKS[kind]
	local base = (spec and spec.coins) or 0
	if base <= 0 then
		return 0
	end
	return math.max(1, math.floor(base * (mult or 1) + 0.5))
end
-- Gems, paid only when the block is fully broken. Dirt has no `sell`, so it
-- pays none.
function MineConfig.gemsFor(kind, mult)
	local spec = MineConfig.BLOCKS[kind]
	local base = (spec and spec.gems) or 0
	if base <= 0 then
		return 0
	end
	return math.max(1, math.floor(base * (mult or 1) + 0.5))
end

--------------------------------------------------------------------------------
-- CONTAINER SPAWN
--
-- Chance that any given block generates as a chest or a crate. These are the
-- dials for the entire pack economy, so they live here rather than as literals
-- buried inside rollKind where nobody would find them.
--
-- They were 0.018 and 0.007 -- 2.5% of every block -- which is 225 containers
-- an hour with a starter pickaxe and 596 with a top explosive, because a blast
-- breaks 33 blocks at once. At roughly 900 packs to finish a set, that
-- completes the game in an evening.
--
-- Tuned to about 20 an hour with a pickaxe. Note this is per BLOCK BROKEN, so a
-- player clearing 8 blocks a second still earns ~2.6x a pickaxe player. That is
-- deliberate -- better tools should find more -- but if it ever has to be flat,
-- the fix is a per-player timed credit, not a per-block roll.
--------------------------------------------------------------------------------


-- Containers an hour at a given blocks-per-second. Check this before changing
-- the two numbers above.
function MineConfig.containersPerHour(blocksPerSecond)
	return (blocksPerSecond or 2.5) * 3600 * (MineConfig.CHEST_CHANCE + MineConfig.CRATE_CHANCE)
end

MineConfig.MINE1_LAYERS = 10000
-- Also Event Horizon's black hole: it collapses on this beat. MineServer resets
-- the mines and MineAmbience plays the blast off the same server clock.
MineConfig.MINE_RESET_SEC = 20 * 60
MineConfig.CHEST_HP_MULT = 2 -- default/native fallback
-- Better chests hurt more; currency/native are lighter than risk/variant.
MineConfig.CHEST_KIND_HP = {
	currency = 1.25,
	native = 2,
	shape = 2.5,
	set = 2.5,
	variant = 3.25,
	risk = 4.5,
}

-- One SECTION = 25 layers. Meadow: 100 sections (layers 1-2500).
-- Event Horizon: 2 sections (layers 1-50), same dirtHp ladder.
-- Start 10 HP. Vs the section above: 7x, then 5x, then 3x, then 2x through
-- layer 500 (68,812,800). After 500: 1.1x per section.
-- Proof: L1=10  L25=10  L26=70  L500=68812800  L501=75694080.
MineConfig.SECTION_SPAN = 25
MineConfig.DIRT_HP_BASE = 10

function MineConfig.sectionIndex(layer)
	local span = MineConfig.SECTION_SPAN or 25
	return math.floor((math.max(1, math.floor(layer or 1)) - 1) / span)
end

-- Lowercase roman for p.xxix / chest stamps. HUD: big roman, tiny arabic.
local ROMAN_MAP = {
	{ 1000, "m" }, { 900, "cm" }, { 500, "d" }, { 400, "cd" },
	{ 100, "c" }, { 90, "xc" }, { 50, "l" }, { 40, "xl" },
	{ 10, "x" }, { 9, "ix" }, { 5, "v" }, { 4, "iv" }, { 1, "i" },
}

function MineConfig.toRoman(n)
	n = math.max(1, math.floor(tonumber(n) or 1))
	local s = ""
	for _, pair in ipairs(ROMAN_MAP) do
		while n >= pair[1] do
			s ..= pair[2]
			n -= pair[1]
		end
	end
	return s
end

function MineConfig.sectionNumber(layer)
	return MineConfig.sectionIndex(layer) + 1
end

function MineConfig.sectionStamp(layer)
	local n = MineConfig.sectionNumber(layer)
	local roman = MineConfig.toRoman(n)
	return {
		n = n,
		roman = roman,
		label = roman .. ".",
		arabic = tostring(n),
	}
end

function MineConfig.sectionHpMult(fromIndex)
	fromIndex = math.max(0, math.floor(fromIndex or 0))
	if fromIndex <= 0 then
		return 7
	elseif fromIndex == 1 then
		return 5
	elseif fromIndex == 2 then
		return 3
	elseif fromIndex <= 18 then
		return 2
	end
	return 1.1
end

function MineConfig.sectionBaseHp(zeroIndex)
	zeroIndex = math.max(0, math.floor(zeroIndex or 0))
	local hp = MineConfig.DIRT_HP_BASE or 10
	for i = 0, zeroIndex - 1 do
		hp *= MineConfig.sectionHpMult(i)
	end
	return hp
end

local SECTION_PALETTE = {
	{ id = "loam", name = "Loam", color = Color3.fromRGB(150, 110, 72) },
	{ id = "ashen", name = "Ashen", color = Color3.fromRGB(120, 120, 124) },
	{ id = "clay", name = "Clay", color = Color3.fromRGB(168, 98, 72) },
	{ id = "ochre", name = "Ochre", color = Color3.fromRGB(180, 140, 70) },
	{ id = "slate", name = "Slate", color = Color3.fromRGB(90, 102, 118) },
	{ id = "umber", name = "Umber", color = Color3.fromRGB(86, 58, 42) },
	{ id = "verdant", name = "Verdant", color = Color3.fromRGB(70, 96, 64) },
	{ id = "cinder", name = "Cinder", color = Color3.fromRGB(78, 52, 52) },
	{ id = "rime", name = "Rime", color = Color3.fromRGB(140, 160, 175) },
	{ id = "crimson", name = "Crimson", color = Color3.fromRGB(110, 48, 48) },
	{ id = "basalt_loam", name = "Basalt Loam", color = Color3.fromRGB(55, 55, 62) },
	{ id = "ironsoil", name = "Ironsoil", color = Color3.fromRGB(110, 95, 88) },
	{ id = "nightclay", name = "Nightclay", color = Color3.fromRGB(40, 36, 58) },
	{ id = "pyre_dust", name = "Pyre Dust", color = Color3.fromRGB(120, 55, 35) },
	{ id = "gloomar", name = "Gloomar", color = Color3.fromRGB(48, 42, 70) },
	{ id = "aether_silt", name = "Aether Silt", color = Color3.fromRGB(90, 120, 160) },
	{ id = "voidloam", name = "Voidloam", color = Color3.fromRGB(28, 22, 40) },
	{ id = "starash", name = "Starash", color = Color3.fromRGB(70, 70, 95) },
	{ id = "mythril_dirt", name = "Mythril Dirt", color = Color3.fromRGB(100, 130, 150) },
	{ id = "endsoil", name = "Endsoil", color = Color3.fromRGB(22, 18, 28) },
}

MineConfig.SECTIONS = Depth.SECTIONS

function MineConfig.sectionFor(layer)
	return Depth.sectionFor(layer)
end

function MineConfig.sectionIndex(layer)
	return Depth.sectionIndex(layer)
end

function MineConfig.sectionNumber(layer)
	return Depth.sectionNumber(layer)
end

--[[
	Strata for a zone of its own, top to bottom, so its mine is not one block the
	whole way down. Only rock takes them; chests and the core keep their looks.
	Dirt Meadow keeps its long SECTIONS ladder above.
]]
MineConfig.ZONE_SECTIONS = {}

do
	local function depthNow()
		local mod = script.Parent:WaitForChild("MineDepth")
		local snap = mod:Clone()
		snap.Name = "_CfgDepthSnap"
		snap.Parent = script
		local ok, Depth = pcall(require, snap)
		snap:Destroy()
		if ok and Depth then return Depth end
		return require(mod)
	end
	local Depth = depthNow()
	local THEME = {
		meadow = { word = "", hue = Color3.fromRGB(150, 110, 72) },
		sunscar = { word = "Quarry", hue = Color3.fromRGB(210, 200, 175) },
		mistreef = { word = "Reef", hue = Color3.fromRGB(40, 110, 120) },
		arcwork = { word = "Gear", hue = Color3.fromRGB(160, 120, 70) },
		bloodmoon = { word = "Crimson", hue = Color3.fromRGB(140, 40, 40) },
		eclipse = { word = "Umbral", hue = Color3.fromRGB(50, 50, 70) },
		riftmarch = { word = "Scar", hue = Color3.fromRGB(120, 80, 160) },
		starfall = { word = "Meteor", hue = Color3.fromRGB(90, 120, 180) },
		mythral = { word = "Ossuary", hue = Color3.fromRGB(200, 180, 120) },
		primordium = { word = "Magma", hue = Color3.fromRGB(180, 70, 30) },
		bigbang = { word = "Horizon", hue = Color3.fromRGB(200, 210, 255) },
	}
	-- No "dust". Prefer stone / rock / ite (and a few hard rock words).
	local TAIL = { "stone", "rock", "ite", "shale", "basalt", "flint", "ore", "slate", "granite", "vein" }
	local PLANET_DIRT = {
		sunscar = {"Blisterloam","Cindersod","Scorchclay","Glassmarl","Duneseam"},
		mistreef = {"Brineloam","Kelpsod","Foamclay","Coralmarl","Tideseam"},
		arcwork = {"Greaseloam","Rustsod","Oilclay","Cogmarl","Sparksod"},
		bloodmoon = {"Crimsonloam","Clotsod","Veinclay","Carmarmar","Gorepeat"},
		eclipse = {"Umbraloam","Voidsod","Shadeclay","Duskmarl","Nightpeat"},
		riftmarch = {"Scarloam","Tearsod","Warpclay","Riftmarl","Fractpeat"},
		starfall = {"Meteorloam","Skysod","Cometclay","Starmarl","Ashpeat"},
		mythral = {"Boneloam","Relicsod","Tombclay","Ossumarl","Cryptpeat"},
		primordium = {"Magmaloam","Lavasod","Emberclay","Coremarl","Pyrepeat"},
		bigbang = {"Protozoam","Sparksod","Nullclay","Aethermarl","Genesispeat"},
	}
	local PLANET_ROCK = {
		sunscar = {"Glassite","Dunestone","Solrock","Scorchite","Mirageflint"},
		mistreef = {"Brinestone","Kelpite","Abyssflint","Coralrock","Tideite"},
		arcwork = {"Gearstone","Rustite","Cogflint","Sparkslate","Ironcoil"},
		bloodmoon = {"Bloodstone","Clotite","Veinrock","Carmaro","Goreflint"},
		eclipse = {"Umbrastone","Shadeite","Voidflint","Duskrock","Nightite"},
		riftmarch = {"Scarstone","Warpite","Tearflint","Riftrock","Fractite"},
		starfall = {"Meteorite","Cometstone","Skyflint","Starrock","Nebulite"},
		mythral = {"Ossistone","Relicite","Tombflint","Boneite","Cryptrock"},
		primordium = {"Magmite","Lavastone","Emberflint","Coreite","Pyrock"},
		bigbang = {"Protostone","Nullite","Aetherflint","Horizite","Genesisrock"},
	}
	for zoneId, theme in pairs(THEME) do
		local list = {}
		for i, sec in ipairs(Depth.SECTIONS or {}) do
			local name
			if zoneId == "meadow" then
				name = sec.name
			elseif i <= 25 then
				local pool = PLANET_DIRT[zoneId]
				if pool then
					local base = pool[((i - 1) % #pool) + 1]
					local tier = math.floor((i - 1) / #pool)
					name = (tier <= 0) and base or (base .. " " .. tostring(tier + 1))
				else
					name = (theme.word or "Deep") .. " " .. sec.name
				end
			else
				local pool = PLANET_ROCK[zoneId]
				local ri = i - 25
				if pool then
					local base = pool[((ri - 1) % #pool) + 1]
					local tier = math.floor((ri - 1) / #pool)
					local tail = TAIL[(tier % #TAIL) + 1]
					name = (tier <= 0) and base or (base .. " " .. tail)
				else
					local tail = TAIL[((i - 1) % #TAIL) + 1]
					name = (theme.word or "Deep") .. " " .. tostring(sec.name) .. " " .. tail
				end
			end
			local t = (i - 1) / math.max(1, #Depth.SECTIONS - 1)
			local hue = theme.hue
			list[i] = {
				id = zoneId .. "_" .. tostring(sec.id),
				name = name,
				layers = { sec.layers[1], sec.layers[2] },
				dirtHp = sec.dirtHp,
				band = sec.band,
				color = Color3.new(hue.R * (1 - 0.45 * t), hue.G * (1 - 0.45 * t), hue.B * (0.55 + 0.45 * t)),
				material = (zoneId == "bigbang") and Enum.Material.Glass or Enum.Material.Slate,
			}
		end
		MineConfig.ZONE_SECTIONS[zoneId] = list
	end
end

function MineConfig.refreshZoneSections()
	-- Rebuild if Depth section count changed (Studio Source edits).
	local mod = script.Parent:WaitForChild("MineDepth")
	local snap = mod:Clone()
	snap.Name = "_DepthSnap"
	snap.Parent = script
	local okD, Depth = pcall(require, snap)
	snap:Destroy()
	if not okD then Depth = require(mod) end
	local need = #(Depth.SECTIONS or {})
	local meadow = MineConfig.ZONE_SECTIONS and MineConfig.ZONE_SECTIONS.meadow
	if meadow and #meadow == need and need > 0 and MineConfig._zoneSecFrom == need then
		return
	end
	MineConfig._zoneSecFrom = 0
	-- Force the module's initial builder pattern by clearing and copying from Depth again.
	local THEME_WORD = {
		meadow = "", sunscar = "Sunscar", mistreef = "Tide", arcwork = "Cog",
		bloodmoon = "Blood", eclipse = "Umbral", riftmarch = "Rift",
		starfall = "Starfall", mythral = "Myth", primordium = "Primordial", bigbang = "Horizon",
	}
	local PLANET_DIRT = {
		sunscar = {"Blisterloam","Cindersod","Scorchclay","Glassmarl","Duneseam"},
		mistreef = {"Brineloam","Kelpsod","Foamclay","Coralmarl","Tideseam"},
		arcwork = {"Greaseloam","Rustsod","Oilclay","Cogmarl","Sparksod"},
		bloodmoon = {"Crimsonloam","Clotsod","Veinclay","Carmarmar","Gorepeat"},
		eclipse = {"Umbraloam","Voidsod","Shadeclay","Duskmarl","Nightpeat"},
		riftmarch = {"Scarloam","Tearsod","Warpclay","Riftmarl","Fractpeat"},
		starfall = {"Meteorloam","Skysod","Cometclay","Starmarl","Ashpeat"},
		mythral = {"Boneloam","Relicsod","Tombclay","Ossumarl","Cryptpeat"},
		primordium = {"Magmaloam","Lavasod","Emberclay","Coremarl","Pyrepeat"},
		bigbang = {"Protozoam","Sparksod","Nullclay","Aethermarl","Genesispeat"},
	}
	local PLANET_ROCK = {
		sunscar = {"Glassite","Dunestone","Solrock","Scorchite","Mirageflint"},
		mistreef = {"Brinestone","Kelpite","Abyssflint","Coralrock","Tideite"},
		arcwork = {"Gearstone","Rustite","Cogflint","Sparkslate","Ironcoil"},
		bloodmoon = {"Bloodstone","Clotite","Veinrock","Carmaro","Goreflint"},
		eclipse = {"Umbrastone","Shadeite","Voidflint","Duskrock","Nightite"},
		riftmarch = {"Scarstone","Warpite","Tearflint","Riftrock","Fractite"},
		starfall = {"Meteorite","Cometstone","Skyflint","Starrock","Nebulite"},
		mythral = {"Ossistone","Relicite","Tombflint","Boneite","Cryptrock"},
		primordium = {"Magmite","Lavastone","Emberflint","Coreite","Pyrock"},
		bigbang = {"Protostone","Nullite","Aetherflint","Horizite","Genesisrock"},
	}
	local THEME_HUE = {
		meadow = Color3.fromRGB(150, 110, 72), sunscar = Color3.fromRGB(210, 200, 175),
		mistreef = Color3.fromRGB(40, 110, 120), arcwork = Color3.fromRGB(160, 120, 70),
		bloodmoon = Color3.fromRGB(140, 40, 40), eclipse = Color3.fromRGB(50, 50, 70),
		riftmarch = Color3.fromRGB(120, 80, 160), starfall = Color3.fromRGB(90, 120, 180),
		mythral = Color3.fromRGB(200, 180, 120), primordium = Color3.fromRGB(180, 70, 30),
		bigbang = Color3.fromRGB(200, 210, 255),
	}
	local TAIL = { "stone", "rock", "ite", "shale", "basalt", "flint", "ore", "slate", "granite", "vein" }
	MineConfig.ZONE_SECTIONS = {}
	for zoneId, word in pairs(THEME_WORD) do
		local hue = THEME_HUE[zoneId] or Color3.fromRGB(100, 100, 100)
		local list = {}
		for i, sec in ipairs(Depth.SECTIONS or {}) do
			local name
			if zoneId == "meadow" then
				name = sec.name
			elseif i <= 25 then
				local pool = PLANET_DIRT[zoneId]
				if pool then
					local base = pool[((i - 1) % #pool) + 1]
					local tier = math.floor((i - 1) / #pool)
					name = (tier <= 0) and base or (base .. " " .. tostring(tier + 1))
				else
					name = (word or "Deep") .. " " .. sec.name
				end
			else
				local pool = PLANET_ROCK[zoneId]
				local ri = i - 25
				if pool then
					local base = pool[((ri - 1) % #pool) + 1]
					local tier = math.floor((ri - 1) / #pool)
					name = (tier <= 0) and base or (base .. " " .. TAIL[(tier % #TAIL) + 1])
				else
					name = (word or "Deep") .. " " .. tostring(sec.name) .. " " .. TAIL[((i - 1) % #TAIL) + 1]
				end
			end
			local t = (i - 1) / math.max(1, #Depth.SECTIONS - 1)
			list[i] = {
				id = zoneId .. "_" .. tostring(sec.id),
				name = name,
				layers = { sec.layers[1], sec.layers[2] },
				dirtHp = sec.dirtHp,
				band = sec.band,
				color = Color3.new(hue.R * (1 - 0.45 * t), hue.G * (1 - 0.45 * t), hue.B * (0.55 + 0.45 * t)),
				material = (zoneId == "bigbang") and Enum.Material.Glass or Enum.Material.Slate,
			}
		end
		MineConfig.ZONE_SECTIONS[zoneId] = list
	end
	MineConfig._zoneSecFrom = 0 -- rebuilt
	MineConfig._zoneSecFrom = need
end

function MineConfig.zoneSectionFor(zoneId, layer)
	MineConfig.refreshZoneSections()
	local list = MineConfig.ZONE_SECTIONS[zoneId]
	if not list then
		return nil
	end
	layer = math.max(1, math.floor(layer or 1))
	for _, s in ipairs(list) do
		if layer >= s.layers[1] and layer <= s.layers[2] then
			return s
		end
	end
	return list[#list]
end

function MineConfig.dirtHp(layer)
	return Depth.meadowDirtHp(layer)
end

function MineConfig.depthBand(layer)
	return Depth.bandForLayer(layer)
end

function MineConfig.chestHp(layer, chest)
	local kind = "native"
	local mult
	if type(chest) == "table" then
		kind = chest.kind or "native"
		mult = chest.hpMult
	elseif type(chest) == "string" then
		kind = chest
	end
	if not mult then
		local map = MineConfig.CHEST_KIND_HP or {}
		mult = map[kind] or MineConfig.CHEST_HP_MULT or 2
	end
	return math.max(1, math.floor(MineConfig.dirtHp(layer) * mult + 0.5))
end

function MineConfig.zoneLayers(zone)
	local id = type(zone) == "table" and zone.id or zone
	if id == "meadow" then
		return MineConfig.MINE1_LAYERS or MineConfig.LAYERS
	end
	return MineConfig.LAYERS
end

MineConfig.EH_SETS = {
	genesis_spark = true,
	first_light = true,
	proto_ore = true,
}

function MineConfig.isEventHorizonSet(setId)
	return MineConfig.EH_SETS[setId] == true
end

-- LUCKY LAYERS
--
-- A 25-layer band that is worth stopping for: every block in it is worth ten
-- times the zone's own dirt, and it is the only place a shiny, shadow or
-- rainbow finish exists at all.
--
-- The roll is a HASH of (zone, band), not a Random. Blocks spawn lazily, one
-- at a time, as a player digs into them -- a Random.new() per block would make
-- every block its own coin flip instead of the whole band one answer, and a
-- player leaving and coming back would get a different world. A hash gives the
-- same answer for the same band forever, on every server, with nothing stored.
--------------------------------------------------------------------------------
MineConfig.LUCKY_LAYER_SPAN = 25
MineConfig.LUCKY_LAYER_CHANCE_MIN = 0.0005 -- zone 1
MineConfig.LUCKY_LAYER_CHANCE_MAX = 0.0025 -- zone 10
MineConfig.LUCKY_LAYER_HP_MULT = 10
MineConfig.LUCKY_LAYER_COLOR = Color3.fromRGB(255, 214, 92)
-- Inside a seam a finish is the point, not a lottery: 30% shiny, 1% shadow
-- (nightmare stays a sub-roll of shadow). Outside one, nothing rolls at all.
MineConfig.LUCKY_SHINY_CHANCE = 0.30
MineConfig.LUCKY_SHADOW_CHANCE = 0.01

function MineConfig.luckyBandOf(y)
	local span = MineConfig.LUCKY_LAYER_SPAN or 25
	return math.floor((math.max(1, math.floor(tonumber(y) or 1)) - 1) / span)
end

function MineConfig.luckyChanceFor(zoneId)
	local zi = (MineConfig.zoneIndex and MineConfig.zoneIndex(zoneId)) or 1
	local lo = MineConfig.LUCKY_LAYER_CHANCE_MIN or 0.0005
	local hi = MineConfig.LUCKY_LAYER_CHANCE_MAX or 0.0025
	return lo + (hi - lo) * ((math.clamp(zi, 1, 10) - 1) / 9)
end

function MineConfig.isLuckyLayer(zoneId, y)
	if not zoneId or not y then
		return false
	end
	local key = tostring(zoneId) .. ":" .. tostring(MineConfig.luckyBandOf(y))
	local h = 2166136261
	for i = 1, #key do
		h = bit32.bxor(h, string.byte(key, i))
		h = (h * 16777619) % 4294967296
	end
	return (h % 1000003) / 1000003 < MineConfig.luckyChanceFor(zoneId)
end

-- Inclusive layer bounds of the band `y` sits in, for anything that wants to
-- describe the seam rather than test one block.
function MineConfig.luckyBandRange(y)
	local span = MineConfig.LUCKY_LAYER_SPAN or 25
	local band = MineConfig.luckyBandOf(y)
	return band * span + 1, (band + 1) * span
end



--[[
	ORE.

	rollKind used to say there is no ore -- a chest was the only thing worth
	hoping for, so one loot table carried the whole game. Ore is the reliable
	half of that split.

	An ore is NOT tied to a zone or a depth. It is tied to HARDNESS, and zone
	and depth both feed that: a zone step is 6x, but 500 layers is ~192x, so
	Meadow at L1500 is about as hard as Primordium's surface. Placing ore by
	zone alone would let someone farm deep Meadow and one-shot zone 10.

	So every ore sits on one axis, D = log6(blockHp / 20), running 0 at Meadow
	Loam to ~23.4 at Primordium Finalite, and the 121 ores spread evenly across
	it. An ore turns up wherever the rock's D is near its own.

	Nothing is ever gated and nothing is ever zero: Stone at the bottom of
	Primordium is 1 in 3.7e9, Oganesson in Meadow Loam is 1 in 8.7e14.

	Glow colour and brightness come straight from the tool generator's LOOKS
	table, so a glowing ore block and the tool made from it light the same.
	Oganesson carries `rainbow` and cycles its hue instead of sitting on one.
]]
--[[
	ORE PER PACK, BY RARITY BAND. Before the ore finder.

	A bell peaking on Epic, the same band the cost bell peaks on. Yield used to
	be a straight ramp from 6 down to 1 across the roster, which meant the ores
	that cost the most to use also handed over the least.

	The finder multiplies these AFTER the roll, and it is stamped on the pack
	when the block breaks rather than read at open -- see openPack.
]]
MineConfig.ORE_YIELD_BANDS = {
	{ upTo = 18, lo = 8, hi = 10 },   -- common     1-18
	{ upTo = 29, lo = 10, hi = 12 },  -- uncommon  19-29
	{ upTo = 49, lo = 11, hi = 13 },  -- rare      30-49
	{ upTo = 60, lo = 12, hi = 15 },  -- epic      50-60  (peak)
	{ upTo = 69, lo = 8, hi = 10 },   -- legendary 61-69
	{ upTo = 75, lo = 6, hi = 8 },    -- mythic    70-75
	{ upTo = 79, lo = 4, hi = 6 },    -- divine    76-79
	{ upTo = 82, lo = 2, hi = 4 },    -- exotic    80-82
}

function MineConfig.oreYieldFor(tier)
	local t = math.max(1, math.floor(tonumber(tier) or 1))
	for _, b in ipairs(MineConfig.ORE_YIELD_BANDS) do
		if t <= b.upTo then
			return b.lo, b.hi
		end
	end
	local last = MineConfig.ORE_YIELD_BANDS[#MineConfig.ORE_YIELD_BANDS]
	return last.lo, last.hi
end

MineConfig.ORE_HP_MULT = 3
MineConfig.ORE_CHANCE = 1 / 200

--[[
	ORE CASE. A 2% drop per ore block broken, before luck.

	The case IS the rare drop, and the whole rare line: tools are not found in
	walls any more, and the old 0.6%-down-to-0.0012% wall-drop ladder is gone.

	Opening one is GUARANTEED. A case pays a skin or a charm -- never a tool,
	never ore, never a dud. There is no second roll deciding whether the case
	was worth picking up; the only question left is which of the two it is.

	The split is a quarter charms, three quarters skins, and the quarter is not
	a taste call: 2% x 25% = 0.5%, which is exactly the charm drop rate the
	design asks for. The two numbers are one decision. Move either and the
	other stops meaning what it was chosen to mean.
]]
MineConfig.ORE_CASE_CHANCE = 0.02
MineConfig.ORE_CASE_CHARM_SHARE = 0.25

--[[
	THE SHAPE, in three terms. Each does one job.

	  x = ore.d - localD   (positive = ore is harder than this rock)

	  1 / (1 + e^((x - X0) / K))   a CLIFF above local hardness. This is what
	                              keeps endgame ore rare in endgame rock:
	                              Oganesson is 1 in 82k even in Finalite.
	  * e^(x / S)                 gentle decay just below, so nearby tiers
	                              stay varied instead of one ore dominating.
	  * e^(-(x / W)^2)            the TAIL. Barely touches the first 20 tiers
	                              down, then bites hard -- ore you outgrew
	                              stops following you down. At 60 tiers below
	                              stops following you down. Ten tiers under
	                              the peak it is already 15% of it, twenty
	                              tiers under 0.4%.

	The peak lands ~21 tiers under local hardness and is SHARP: the top five
	ores carry ~38% of everything you dig there, so a seam is worth travelling
	for. Past that it falls away fast, and the very top of the list -- harder
	than the rock it sits in -- is the prize: Oganesson is 1 in 687k even in
	Finalite.
]]
MineConfig.ORE_X0 = -4.2
MineConfig.ORE_K = 0.45
MineConfig.ORE_S = 4.0
MineConfig.ORE_W = 3.0

MineConfig.ORES = {
	{ id = "stone", name = "Stone", tier = 1, color = Color3.fromRGB(131, 131, 131), material = Enum.Material.Rock, met = 0, rough = .9 },
	{ id = "clay", name = "Clay", tier = 2, color = Color3.fromRGB(184, 93, 48), material = Enum.Material.Mud, met = 0, rough = .95 },
	{ id = "limestone", name = "Limestone", tier = 3, color = Color3.fromRGB(240, 229, 191), material = Enum.Material.Limestone, met = 0, rough = .9 },
	{ id = "pumice", name = "Pumice", tier = 4, color = Color3.fromRGB(200, 195, 185), material = Enum.Material.Concrete, met = 0, rough = 1 },
	{ id = "halite", name = "Halite", tier = 5, color = Color3.fromRGB(255, 196, 196), material = Enum.Material.Salt, met = 0, rough = .4 },
	{ id = "coal", name = "Coal", tier = 6, color = Color3.fromRGB(40, 40, 46), material = Enum.Material.Slate, met = 0, rough = .7 },
	{ id = "flint", name = "Flint", tier = 7, color = Color3.fromRGB(138, 119, 100), material = Enum.Material.Slate, met = 0, rough = .35 },
	{ id = "basalt", name = "Basalt", tier = 8, color = Color3.fromRGB(55, 57, 70), material = Enum.Material.Basalt, met = 0, rough = .85 },
	{ id = "slate", name = "Slate", tier = 9, color = Color3.fromRGB(41, 81, 138), material = Enum.Material.Slate, met = 0, rough = .6 },
	{ id = "bone", name = "Bone", tier = 10, color = Color3.fromRGB(243, 211, 140), material = Enum.Material.Plaster, met = 0, rough = .7 },
	{ id = "granite", name = "Granite", tier = 11, color = Color3.fromRGB(189, 131, 128), material = Enum.Material.Granite, met = 0, rough = .5 },
	{ id = "copper", name = "Copper", tier = 12, color = Color3.fromRGB(205, 87, 5), material = Enum.Material.Metal, met = 1, rough = .3 },
	{ id = "tin", name = "Tin", tier = 13, color = Color3.fromRGB(210, 212, 218), material = Enum.Material.CorrodedMetal, met = 1, rough = .45 },
	{ id = "ember", name = "Ember", tier = 14, color = Color3.fromRGB(80, 32, 18), material = Enum.Material.CrackedLava, met = 0, rough = .8, glow = Color3.fromRGB(255, 100, 20), glowBright = 0.5 },
	{ id = "sulfur", name = "Sulfur", tier = 15, color = Color3.fromRGB(254, 226, 0), material = Enum.Material.Sand, met = 0, rough = .6 },
	{ id = "lead", name = "Lead", tier = 16, color = Color3.fromRGB(71, 91, 138), material = Enum.Material.CorrodedMetal, met = 1, rough = .6 },
	{ id = "zinc", name = "Zinc", tier = 17, color = Color3.fromRGB(137, 178, 211), material = Enum.Material.Foil, met = 1, rough = .5 },
	{ id = "aluminum", name = "Aluminum", tier = 18, color = Color3.fromRGB(200, 210, 225), material = Enum.Material.Metal, met = 1, rough = .35 },
	{ id = "iron", name = "Iron", tier = 19, color = Color3.fromRGB(166, 166, 172), material = Enum.Material.Metal, met = 1, rough = .5 },
	{ id = "graphite", name = "Graphite", tier = 20, color = Color3.fromRGB(102, 113, 138), material = Enum.Material.Metal, met = .5, rough = .35 },
	{ id = "pyrite", name = "Pyrite", tier = 21, color = Color3.fromRGB(227, 206, 75), material = Enum.Material.DiamondPlate, met = 1, rough = .15 },
	{ id = "marble", name = "Marble", tier = 22, color = Color3.fromRGB(254, 252, 246), material = Enum.Material.Marble, met = 0, rough = .25 },
	{ id = "pearl", name = "Pearl", tier = 23, color = Color3.fromRGB(252, 245, 236), material = Enum.Material.SmoothPlastic, met = .2, rough = .15 },
	{ id = "rime", name = "Rime", tier = 24, color = Color3.fromRGB(140, 225, 255), material = Enum.Material.Ice, met = 0, rough = .05, glow = Color3.fromRGB(170, 235, 255), glowBright = 0.4 },
	{ id = "quartz", name = "Quartz", tier = 25, color = Color3.fromRGB(249, 249, 255), material = Enum.Material.Glass, met = 0, rough = .05 },
	{ id = "amber", name = "Amber", tier = 26, color = Color3.fromRGB(255, 152, 0), material = Enum.Material.Glass, met = 0, rough = .12 },
	{ id = "petrifact", name = "Petrifact", tier = 27, color = Color3.fromRGB(151, 79, 45), material = Enum.Material.Wood, met = 0, rough = .4 },
	{ id = "nickel", name = "Nickel", tier = 28, color = Color3.fromRGB(227, 195, 131), material = Enum.Material.Foil, met = 1, rough = .3 },
	{ id = "onyx", name = "Onyx", tier = 29, color = Color3.fromRGB(15, 15, 15), material = Enum.Material.Marble, met = 0, rough = .04 },
	{ id = "bloodstone", name = "Bloodstone", tier = 30, color = Color3.fromRGB(20, 95, 50), material = Enum.Material.Marble, met = 0, rough = .3 },
	{ id = "garnet", name = "Garnet", tier = 31, color = Color3.fromRGB(151, 0, 15), material = Enum.Material.Glass, met = 0, rough = .07 },
	{ id = "citrine", name = "Citrine", tier = 32, color = Color3.fromRGB(255, 212, 0), material = Enum.Material.Glass, met = 0, rough = .07 },
	{ id = "chromium", name = "Chromium", tier = 33, color = Color3.fromRGB(171, 201, 255), material = Enum.Material.Metal, met = 1, rough = .04 },
	{ id = "turquoise", name = "Turquoise", tier = 34, color = Color3.fromRGB(11, 216, 201), material = Enum.Material.Marble, met = 0, rough = .4 },
	{ id = "bismuth", name = "Bismuth", tier = 35, color = Color3.fromRGB(188, 156, 238), material = Enum.Material.Foil, met = 1, rough = .1, rainbow = true },
	{ id = "silver", name = "Silver", tier = 36, color = Color3.fromRGB(250, 248, 242), material = Enum.Material.Metal, met = 1, rough = .12 },
	{ id = "amethyst", name = "Amethyst", tier = 37, color = Color3.fromRGB(112, 8, 186), material = Enum.Material.Glass, met = 0, rough = .07 },
	{ id = "tigereye", name = "Tigereye", tier = 38, color = Color3.fromRGB(189, 112, 0), material = Enum.Material.Marble, met = .3, rough = .2 },
	{ id = "lapis", name = "Lapis", tier = 39, color = Color3.fromRGB(0, 39, 184), material = Enum.Material.Marble, met = 0, rough = .3 },
	{ id = "geode", name = "Geode", tier = 40, color = Color3.fromRGB(150, 80, 240), material = Enum.Material.Glass, met = 0, rough = .2 },
	{ id = "topaz", name = "Topaz", tier = 41, color = Color3.fromRGB(255, 113, 57), material = Enum.Material.Glass, met = 0, rough = .05 },
	{ id = "phosphorus", name = "Phosphorus", tier = 42, color = Color3.fromRGB(255, 252, 175), material = Enum.Material.SmoothPlastic, met = 0, rough = .4, glow = Color3.fromRGB(80, 255, 108), glowBright = 0.7 },
	{ id = "peridot", name = "Peridot", tier = 43, color = Color3.fromRGB(176, 229, 0), material = Enum.Material.Glass, met = 0, rough = .07 },
	{ id = "jade", name = "Jade", tier = 44, color = Color3.fromRGB(58, 194, 104), material = Enum.Material.Marble, met = 0, rough = .35 },
	{ id = "emberglass", name = "Emberglass", tier = 45, color = Color3.fromRGB(255, 90, 0), material = Enum.Material.Glass, met = .3, rough = .1, glow = Color3.fromRGB(255, 140, 30), glowBright = 1 },
	{ id = "tungsten", name = "Tungsten", tier = 46, color = Color3.fromRGB(113, 118, 138), material = Enum.Material.Metal, met = 1, rough = .35 },
	{ id = "lithium", name = "Lithium", tier = 47, color = Color3.fromRGB(215, 222, 235), material = Enum.Material.Metal, met = 1, rough = .3, glow = Color3.fromRGB(255, 60, 80), glowBright = 0.2 },
	{ id = "titanium", name = "Titanium", tier = 48, color = Color3.fromRGB(103, 58, 216), material = Enum.Material.Metal, met = 1, rough = .32 },
	{ id = "obsidian", name = "Obsidian", tier = 49, color = Color3.fromRGB(26, 9, 48), material = Enum.Material.Glass, met = 0, rough = .06 },
	{ id = "cobalt", name = "Cobalt", tier = 50, color = Color3.fromRGB(0, 73, 248), material = Enum.Material.Metal, met = 1, rough = .28 },
	{ id = "gold", name = "Gold", tier = 51, color = Color3.fromRGB(255, 186, 0), material = Enum.Material.Metal, met = 1, rough = .15 },
	{ id = "regolith", name = "Regolith", tier = 52, color = Color3.fromRGB(175, 175, 188), material = Enum.Material.Pebble, met = 0, rough = .8 },
	{ id = "sunstone", name = "Sunstone", tier = 53, color = Color3.fromRGB(255, 97, 0), material = Enum.Material.Foil, met = .3, rough = .1, glow = Color3.fromRGB(255, 112, 0), glowBright = 0.9 },
	{ id = "emerald", name = "Emerald", tier = 54, color = Color3.fromRGB(0, 173, 86), material = Enum.Material.Glass, met = 0, rough = .05 },
	{ id = "moonstone", name = "Moonstone", tier = 55, color = Color3.fromRGB(132, 168, 255), material = Enum.Material.Glass, met = 0, rough = .1, glow = Color3.fromRGB(132, 175, 255), glowBright = 0.5 },
	{ id = "sapphire", name = "Sapphire", tier = 56, color = Color3.fromRGB(0, 79, 201), material = Enum.Material.Glass, met = 0, rough = .03 },
	{ id = "ruby", name = "Ruby", tier = 57, color = Color3.fromRGB(242, 0, 91), material = Enum.Material.Glass, met = 0, rough = .03, glow = Color3.fromRGB(255, 0, 68), glowBright = 0.6 },
	{ id = "palladium", name = "Palladium", tier = 58, color = Color3.fromRGB(118, 164, 255), material = Enum.Material.Metal, met = 1, rough = .18 },
	{ id = "aquamarine", name = "Aquamarine", tier = 59, color = Color3.fromRGB(123, 224, 251), material = Enum.Material.Ice, met = 0, rough = .05 },
	{ id = "opal", name = "Opal", tier = 60, color = Color3.fromRGB(240, 240, 255), material = Enum.Material.ForceField, met = 0, rough = .1, rainbow = true },
	{ id = "platinum", name = "Platinum", tier = 61, color = Color3.fromRGB(232, 223, 185), material = Enum.Material.Metal, met = 1, rough = .1 },
	{ id = "stormstone", name = "Stormstone", tier = 62, color = Color3.fromRGB(60, 85, 160), material = Enum.Material.Slate, met = .3, rough = .3, glow = Color3.fromRGB(140, 190, 255), glowBright = 0.6 },
	{ id = "diamond", name = "Diamond", tier = 63, color = Color3.fromRGB(199, 240, 255), material = Enum.Material.Glass, met = 0, rough = 0, glow = Color3.fromRGB(197, 238, 255), glowBright = 0.4 },
	{ id = "starmetal", name = "Starmetal", tier = 64, color = Color3.fromRGB(55, 65, 130), material = Enum.Material.Metal, met = 1, rough = .1, glow = Color3.fromRGB(200, 220, 255), glowBright = 0.5 },
	{ id = "aetherite", name = "Aetherite", tier = 65, color = Color3.fromRGB(225, 245, 255), material = Enum.Material.Glass, met = 0, rough = .02, glow = Color3.fromRGB(200, 240, 255), glowBright = 0.9 },
	{ id = "meteorite", name = "Meteorite", tier = 66, color = Color3.fromRGB(138, 94, 66), material = Enum.Material.CrackedLava, met = .6, rough = .5, glow = Color3.fromRGB(255, 95, 0), glowBright = 0.3 },
	{ id = "soulstone", name = "Soulstone", tier = 67, color = Color3.fromRGB(70, 255, 200), material = Enum.Material.Glass, met = 0, rough = .1, glow = Color3.fromRGB(80, 255, 200), glowBright = 0.9 },
	{ id = "galaxite", name = "Galaxite", tier = 68, color = Color3.fromRGB(40, 20, 90), material = Enum.Material.Basalt, met = .2, rough = .3, glow = Color3.fromRGB(140, 90, 255), glowBright = 0.8 },
	{ id = "frostfire", name = "Frostfire", tier = 69, color = Color3.fromRGB(120, 200, 255), material = Enum.Material.Glass, met = 0, rough = .03, glow = Color3.fromRGB(255, 120, 60), glowBright = 1 },
	{ id = "umbrite", name = "Umbrite", tier = 70, color = Color3.fromRGB(20, 10, 32), material = Enum.Material.Glass, met = .3, rough = .05, glow = Color3.fromRGB(130, 40, 255), glowBright = 1 },
	{ id = "celestine", name = "Celestine", tier = 71, color = Color3.fromRGB(255, 228, 140), material = Enum.Material.Glass, met = .2, rough = .02, glow = Color3.fromRGB(255, 240, 180), glowBright = 1.2 },
	{ id = "orichalcum", name = "Orichalcum", tier = 72, color = Color3.fromRGB(255, 145, 0), material = Enum.Material.Metal, met = 1, rough = .15 },
	{ id = "spectrite", name = "Spectrite", tier = 73, color = Color3.fromRGB(255, 255, 255), material = Enum.Material.ForceField, met = 0, rough = .02, glow = Color3.fromRGB(255, 255, 255), glowBright = 1.2, rainbow = true },
	{ id = "mythril", name = "Mythril", tier = 74, color = Color3.fromRGB(132, 207, 255), material = Enum.Material.Metal, met = 1, rough = .08, glow = Color3.fromRGB(106, 191, 255), glowBright = 0.8 },
	{ id = "dragonstone", name = "Dragonstone", tier = 75, color = Color3.fromRGB(185, 10, 20), material = Enum.Material.Slate, met = .4, rough = .15, glow = Color3.fromRGB(255, 60, 0), glowBright = 1.3 },
	{ id = "adamantite", name = "Adamantite", tier = 76, color = Color3.fromRGB(184, 0, 32), material = Enum.Material.Metal, met = 1, rough = .18 },
	{ id = "thorium", name = "Thorium", tier = 77, color = Color3.fromRGB(191, 191, 181), material = Enum.Material.Metal, met = 1, rough = .3, glow = Color3.fromRGB(171, 171, 255), glowBright = 0.6 },
	{ id = "uranium", name = "Uranium", tier = 78, color = Color3.fromRGB(255, 226, 0), material = Enum.Material.Neon, met = .6, rough = .3, glow = Color3.fromRGB(255, 236, 40), glowBright = 1.2 },
	{ id = "plutonium", name = "Plutonium", tier = 79, color = Color3.fromRGB(222, 150, 105), material = Enum.Material.Metal, met = .85, rough = .25, glow = Color3.fromRGB(255, 120, 30), glowBright = 1.2 },
	{ id = "fermium", name = "Fermium", tier = 80, color = Color3.fromRGB(255, 2, 70), material = Enum.Material.Metal, met = .8, rough = .12, glow = Color3.fromRGB(255, 15, 97), glowBright = 1.5 },
	{ id = "lawrencium", name = "Lawrencium", tier = 81, color = Color3.fromRGB(255, 235, 177), material = Enum.Material.Metal, met = 1, rough = .05, glow = Color3.fromRGB(255, 239, 190), glowBright = 1.7 },
	{ id = "oganesson", name = "Oganesson", tier = 82, color = Color3.fromRGB(17, 0, 42), material = Enum.Material.ForceField, met = 1, rough = .05, glow = Color3.fromRGB(137, 54, 255), glowBright = 2, rainbow = true },
}

--[[
	Ore ids that no longer exist, and what a save holding one becomes.

	Ore ids are load-bearing in two places: p.ores[id] is banked stardust-worth
	of material, and every ore pack is "<id>_ore_pack". Dropping an id without a
	map silently deletes both, so the roster swap ships with this table and a
	one-time pass over the profile on load.

	Chains are already resolved -- charcoal went to halite and halite went to
	rock_salt, so charcoal maps straight to rock_salt.
]]
--[[
	THE BLACKSMITH UPGRADE MODEL.

	Every tool runs its own 1..TOOL_MAX_LEVEL scale. Ore tier does not set a
	tool's starting level any more -- it sets the band the tool plays in, and
	the level is the whole climb inside it. A tier-121 pick used to be BORN at
	level 700, which made finding one the end of its story rather than the
	start, and left nothing worth spending stardust on.

	Tier is therefore a multiplier: TOOL_TIER_SPAN says how many x6 steps
	separate tier 1 from tier 121, the same unit the mine measures depth in.

	A level costs ORE and STARDUST. Ore is the real gate -- you cannot level
	what you cannot dig -- and stardust is the throttle. Both scale with the
	tool's tier and type, anchored so a tier-1 pickaxe is the 1x baseline and
	nothing in the game is ever cheaper to level than that.

	Numbers come from the balance model in tools/upgrade-calculator.html; the
	harnesses under tools/verify assert on them.
]]
--[[
	THE CAP IS ONE LINE, ON PURPOSE.

	Raising TOOL_MAX_LEVEL used to mean re-tuning three growth rates by hand,
	and getting it wrong was silent: at a 10,000 cap the old per-level rates put
	max damage at 1.1e100, which is 5.6e79 times the deepest block in the game,
	and the cost of a full climb at 1.76e37 ore. Nothing overflowed -- it just
	stopped meaning anything.

	So the per-level rates are DERIVED from what a whole climb is worth instead
	of being stated directly. Move the cap and the curve restretches:

	  DAMAGE holds exactly. A full climb is worth 3.9e8 at any cap, so a maxed
	  tool lands 222x over the deepest block whether that took 1,000 levels or
	  10,000. This is the property that matters, because it is what keeps tools
	  in step with the mine.

	  COST scales with the cap, roughly linearly -- about 1.5e10 stardust for a
	  full climb at 1,000 and 1.5e11 at 10,000. That is not a leak, it is
	  arithmetic: stretch the same curve over ten times more steps and the sum
	  of those steps is ten times larger. Ten times the levels for ten times the
	  investment, at the same final power. If a bigger cap should NOT cost more,
	  drop TOOL_CLIMB_ORE and TOOL_CLIMB_DUST by the same factor as the cap rose.

	At 1000 these reproduce the hand-tuned originals exactly -- 1.02 damage,
	1.0075 ore, 1.011 dust -- so this is a refactor, not a rebalance. At 10,000
	they become 1.00198, 1.00075 and 1.00109.
]]
MineConfig.TOOL_MAX_LEVEL = 100       -- the one line to move

-- What a full 1 -> max climb multiplies by. Cap-independent.
MineConfig.TOOL_CLIMB_DAMAGE = 3.9e8
MineConfig.TOOL_CLIMB_ORE = 1747      -- last level costs this many x the first
MineConfig.TOOL_CLIMB_DUST = 55800

local function perLevel(total)
	local steps = math.max(1, MineConfig.TOOL_MAX_LEVEL - 1)
	return total ^ (1 / steps)
end

MineConfig.TOOL_TIER_SPAN = 16        -- 6^16 from tier 1 to tier 121
MineConfig.TOOL_DMG_BASE = 10
MineConfig.TOOL_DMG_STEP = perLevel(MineConfig.TOOL_CLIMB_DAMAGE)
MineConfig.TOOL_ORE_BASE = 4
MineConfig.TOOL_ORE_GROW = perLevel(MineConfig.TOOL_CLIMB_ORE)
MineConfig.TOOL_DUST_BASE = 25
MineConfig.TOOL_DUST_GROW = perLevel(MineConfig.TOOL_CLIMB_DUST)
MineConfig.TOOL_COST_TIER = 0.85      -- cost exponent on ore tier
MineConfig.TOOL_COST_TYPE = 0.5       -- cost exponent on type rarity
MineConfig.TOOL_RECYCLE_PCT = 0.5     -- flat cut of what went in

local function clampLevel(level)
	local n = math.floor(tonumber(level) or 1)
	return math.clamp(n, 1, MineConfig.TOOL_MAX_LEVEL)
end
local function clampTier(tier)
	local n = math.floor(tonumber(tier) or 1)
	return math.clamp(n, 1, #MineConfig.ORES)
end

--[[
	COST TO MAX IS A BELL, NOT A CLIMB.

	This was tier^0.85: strictly rising, so the deepest ore always made the
	dearest tool. Pack yield ran the other way, 6 a pack at tier 1 down to 1 at
	tier 121. Together that is a ~360x double penalty pointed straight at the
	endgame tools, and it is why maxing a tier-74 pick priced out at 82 years of
	mining at ten blocks a second.

	Anchored per rarity band now, peaking on Epic and falling away on BOTH
	sides, with the far end landing below the near one:

	    exotic     1.0   cheapest to finish
	    common     2.0   second cheapest
	    divine     4.0
	    uncommon   6.0
	    mythic     7.0
	    legendary 11.0
	    rare      12.0
	    epic      18.0   dearest to finish

	So a better pick takes LESS ore to max, and its packs pay less per find to
	match -- the two curves peak on the same band and work together rather than
	multiplying against each other.

	Anchors are band CENTRES and the value is interpolated linearly between
	them, so there is no cliff at a band boundary: tier 72 and tier 73 differ by
	a hair, not by a step.
]]
MineConfig.TOOL_COST_BANDS = {
	{ tier = 9.5, mult = 2.0 },     -- common     1-18
	{ tier = 24.0, mult = 6.0 },    -- uncommon  19-29
	{ tier = 39.5, mult = 12.0 },   -- rare      30-49
	{ tier = 55.0, mult = 18.0 },   -- epic      50-60  (peak)
	{ tier = 65.0, mult = 11.0 },   -- legendary 61-69
	{ tier = 72.5, mult = 7.0 },    -- mythic    70-75
	{ tier = 77.5, mult = 4.0 },    -- divine    76-79
	{ tier = 81.0, mult = 1.0 },    -- exotic    80-82  (floor)
}

-- typeMult is the tool type's rarity weight (1 for a plain pickaxe); a rarer
-- frame still costs more per level, on top of wherever the bell puts it.
function MineConfig.toolCostMult(tier, typeMult)
	local t = clampTier(tier)
	local m = math.max(1, tonumber(typeMult) or 1)
	local B = MineConfig.TOOL_COST_BANDS
	local bell
	if t <= B[1].tier then
		bell = B[1].mult
	elseif t >= B[#B].tier then
		bell = B[#B].mult
	else
		for i = 1, #B - 1 do
			local a, b = B[i], B[i + 1]
			if t >= a.tier and t <= b.tier then
				local f = (t - a.tier) / (b.tier - a.tier)
				bell = a.mult + (b.mult - a.mult) * f
				break
			end
		end
	end
	return (bell or 1) * (m ^ MineConfig.TOOL_COST_TYPE)
end

-- What tier alone is worth, before any levelling.
function MineConfig.toolTierPower(tier)
	local t = clampTier(tier)
	return 6 ^ (MineConfig.TOOL_TIER_SPAN * (t - 1) / 120)
end

function MineConfig.toolPower(tier, level, typeMult)
	local L = clampLevel(level)
	return MineConfig.TOOL_DMG_BASE
		* MineConfig.toolTierPower(tier)
		* math.max(0.01, tonumber(typeMult) or 1)
		* (MineConfig.TOOL_DMG_STEP ^ (L - 1))
end

-- Cost of the step from `level` to `level + 1`. Returns nil at the cap so a
-- caller cannot accidentally charge for a level that does not exist.
function MineConfig.toolUpgradeCost(tier, level, typeMult)
	local L = clampLevel(level)
	if L >= MineConfig.TOOL_MAX_LEVEL then
		return nil, nil
	end
	local mult = MineConfig.toolCostMult(tier, typeMult)
	local ore = math.ceil(MineConfig.TOOL_ORE_BASE * (MineConfig.TOOL_ORE_GROW ^ (L - 1)) * mult)
	local dust = math.ceil(MineConfig.TOOL_DUST_BASE * (MineConfig.TOOL_DUST_GROW ^ (L - 1)) * mult)
	return ore, dust
end

--[[
	RESTORED AFTER A BAD MERGE. c59bec5 took main's MineConfig wholesale and
	dropped this whole block, but every caller of it stayed. The result was not
	a quiet regression -- `C.toolBreakingPower` is called on EVERY tool grant
	(MineServer, "BreakPower" attribute) and `C.toolCraftCost` on every craft,
	so forging and handing out tools both threw on a nil call. Four commits
	shipped over the top of it.

	It is restored here rather than reinvented, with one change: nothing in it
	re-enforces the swing gate. Main's `Dig.Breaking.canBreak` does that now and
	weighs zone and layer as well as ore tier; the merge was right to keep one
	gate. These are the RULE and the numbers behind it, which main never had.

	BREAKING POWER. The ore a tool is forged from IS its breaking power.

	Owner's rule (TODO 0.1), not derived from anything in this repo:

	  - A tool forged from ore tier T has breaking power T.
	  - It reaches T + ORE_REACH tiers of ore.
	  - Breaking power is NOT upgradeable. Levelling raises damage, never reach.
	    The only way to reach deeper ore is to forge from a better ore.

	Breaking power is NOT damage, and the two must never be collapsed into one
	number. A tool can hit for billions and still be unable to scratch an ore
	fifteen tiers above the rock it was made from.

	Across 82 ores a +15 reach is about six forges from the first tool to the
	last ore, which is the progression ladder the rule exists to create.
]]
MineConfig.ORE_REACH = 15

--[[
	Breaking power for a tool with no ore behind it -- a shop rung, the starter
	pickaxe, a chest flagship.

	Zero, so such a tool still reaches ORE_REACH tiers (0 + 15) and the rule
	stays uniform rather than exempting every non-forged tool from it. If ore
	should instead be mineable with anything until a player forges their first
	tool, this is the one line to change.
]]
MineConfig.NO_ORE_BREAKING_POWER = 0

--[[
	Breaking power from a tool's BASE STATS.

	Every tool has a tier, and that tier is its breaking power -- an ore tool's
	tier is its ore, a shop rung's tier is its rung. One rule, no special case,
	so the wooden pickaxe and a forged Oganesson pick are measured the same way.

	Reads `oreTier` before `tier` on purpose: `tier` on a given Tool instance is
	`lookTier`, a cosmetic ladder value clamped to the shop family's length, and
	gating on it is silently wrong.
]]
function MineConfig.toolBreakingPower(tool)
	if type(tool) == "table" then
		local t = tonumber(tool.oreTier) or tonumber(tool.tier)
		if t then
			return math.max(0, math.floor(t))
		end
		return MineConfig.NO_ORE_BREAKING_POWER or 0
	end
	return math.max(0, math.floor(tonumber(tool) or 0))
end

-- The rule, stated. The live refusal is main's Dig.Breaking.canBreak, which
-- also weighs zone and layer; this is here so the reach rule has one home and
-- the UI below can show the same ceiling the rule implies.
function MineConfig.canBreakOre(breakingPower, oreTier)
	local bp = math.max(1, math.floor(tonumber(breakingPower) or 1))
	local t = math.max(1, math.floor(tonumber(oreTier) or 1))
	return t <= bp + (MineConfig.ORE_REACH or 15)
end

-- The deepest ore tier a tool can reach, for UI that wants to show the ceiling.
function MineConfig.oreReachCap(breakingPower)
	local bp = math.max(1, math.floor(tonumber(breakingPower) or 1))
	return math.min(bp + (MineConfig.ORE_REACH or 15), MineConfig.ORE_COUNT or 82)
end

MineConfig.TOOL_CRAFT_BASE = 250

function MineConfig.toolCraftCost(tier, typeMult)
	return math.ceil(MineConfig.TOOL_CRAFT_BASE * MineConfig.toolCostMult(tier, typeMult))
end

--[[
	The wooden pickaxe is a TUTORIAL pick and nothing else.

	It exists to get a new player to the stone pick, which is handed over in the
	tutorial, and then it is done. Five levels is the length of that errand; it
	is not a tool anybody should still be levelling afterwards, and its coin
	ladder is priced to be finished rather than lived in.

	It is also the one tool that levels on COINS. Charging ore for the thing
	whose whole job is to carry a player who has no ore yet would gate the
	ungating.
]]
MineConfig.WOOD_PICK_ID = "wood_pick"
MineConfig.WOOD_PICK_MAX_LEVEL = 5
MineConfig.TUTORIAL_GRADUATION_TOOL = "stone_pick"
MineConfig.WOOD_PICK_COIN_BASE = 35
MineConfig.WOOD_PICK_COIN_GROW = 1.55

-- Cost of the step from `level` to `level + 1`, in coins. nil at the cap, the
-- same contract toolUpgradeCost uses, so a caller cannot charge for a level
-- that does not exist.
function MineConfig.woodPickCoinCost(level)
	local L = math.max(1, math.floor(tonumber(level) or 1))
	if L >= MineConfig.WOOD_PICK_MAX_LEVEL then
		return nil
	end
	return math.ceil(MineConfig.WOOD_PICK_COIN_BASE * (MineConfig.WOOD_PICK_COIN_GROW ^ (L - 1)))
end

-- True when this tool levels on coins rather than ore + stardust.
function MineConfig.isCoinTool(tool)
	return type(tool) == "table" and tool.typeId == MineConfig.WOOD_PICK_ID
end

-- Everything poured in to reach `level` from 1. Geometric, so it stays exact
-- at level 1000 instead of drifting the way a loop would.
function MineConfig.toolSpent(tier, level, typeMult)
	local L = clampLevel(level)
	if L <= 1 then
		return 0, 0
	end
	local mult = MineConfig.toolCostMult(tier, typeMult)
	local ro, rd = MineConfig.TOOL_ORE_GROW, MineConfig.TOOL_DUST_GROW
	local ore = math.ceil(MineConfig.TOOL_ORE_BASE * ((ro ^ (L - 1)) - 1) / (ro - 1) * mult)
	local dust = math.ceil(MineConfig.TOOL_DUST_BASE * ((rd ^ (L - 1)) - 1) / (rd - 1) * mult)
	return ore, dust
end

--[[
	Scrapping returns a flat cut of what was actually spent -- no tier falloff,
	no type falloff, no level tax.

	All of that machinery existed to stop a tool FOUND in a wall from being a
	payout, because a found tool used to arrive at level 700 with a huge
	notional build cost behind it. On this scale it arrives at level 1 with
	nothing behind it, so the exploit is gone by construction and the rate can
	be generous and legible instead of defensive.
]]
function MineConfig.toolRecycle(tier, level, typeMult)
	local ore, dust = MineConfig.toolSpent(tier, level, typeMult)
	local pct = MineConfig.TOOL_RECYCLE_PCT
	return math.floor(ore * pct), math.floor(dust * pct)
end

--[[
	Which hand-made ore face each ore wears, by index into MineOreArt.

	Thirty tiles, every one of them used. Matching is on hue first and lightness
	second rather than raw RGB, so a navy ore and a pale sky-blue one land on
	different tiles instead of both collapsing onto whichever blue is nearest in
	straight distance; a desaturated ore ignores hue entirely, which is what
	keeps greys on grey tiles.

	Generated by tools/map-ores-to-tiles.js from build/ore-sheet/tiles.json.
]]
MineConfig.ORE_FACE = {
	stone = 10,
	clay = 3,
	limestone = 18,
	pumice = 30,
	halite = 27,
	coal = 10,
	flint = 18,
	basalt = 10,
	slate = 21,
	bone = 28,
	granite = 30,
	copper = 3,
	tin = 30,
	ember = 23,
	sulfur = 28,
	lead = 10,
	zinc = 26,
	aluminum = 30,
	iron = 30,
	graphite = 10,
	pyrite = 28,
	marble = 28,
	pearl = 28,
	rime = 26,
	quartz = 8,
	amber = 28,
	petrifact = 6,
	nickel = 18,
	onyx = 10,
	bloodstone = 15,
	garnet = 27,
	citrine = 28,
	chromium = 26,
	turquoise = 12,
	bismuth = 24,
	silver = 18,
	amethyst = 24,
	tigereye = 28,
	lapis = 14,
	geode = 24,
	topaz = 20,
	phosphorus = 28,
	peridot = 7,
	jade = 22,
	emberglass = 3,
	tungsten = 10,
	lithium = 30,
	titanium = 11,
	obsidian = 17,
	cobalt = 14,
	gold = 28,
	regolith = 30,
	sunstone = 3,
	emerald = 15,
	moonstone = 14,
	sapphire = 14,
	ruby = 4,
	palladium = 26,
	aquamarine = 26,
	opal = 8,
	platinum = 18,
	stormstone = 10,
	diamond = 26,
	starmetal = 10,
	aetherite = 26,
	meteorite = 18,
	soulstone = 22,
	galaxite = 1,
	frostfire = 26,
	umbrite = 1,
	celestine = 28,
	orichalcum = 28,
	spectrite = 30,
	mythril = 26,
	dragonstone = 9,
	adamantite = 27,
	thorium = 30,
	uranium = 28,
	plutonium = 3,
	fermium = 27,
	lawrencium = 28,
	oganesson = 17,
}

MineConfig.ORE_MIGRATION = {
	agate = "quartz",
	alexandrite = "moonstone",
	alumina = "pyrite",
	anthracite = "pearl",
	apatite = "amethyst",
	azurite = "nickel",
	bauxite = "rime",
	beryllium = "gold",
	bituminous_coal = "ember",
	boron_carbide = "emberglass",
	boron_nitride = "starmetal",
	brass = "tigereye",
	brick = "pumice",
	bridgmanite = "dragonstone",
	bronze = "onyx",
	cassiterite = "tin",
	cast_iron = "sulfur",
	chalcopyrite = "marble",
	charcoal = "halite",
	chert = "flint",
	chromite = "onyx",
	cinnabar = "onyx",
	cobblestone = "stone",
	coesite = "umbrite",
	damascus_steel = "cobalt",
	diorite = "copper",
	dunite = "bloodstone",
	electrum = "obsidian",
	fluorite = "onyx",
	fulgurite = "gold",
	galena = "lead",
	graphene = "galaxite",
	hematite = "iron",
	ilmenite = "lithium",
	impactite = "regolith",
	iridium = "galaxite",
	jasper = "amber",
	kimberlite = "onyx",
	labradorite = "cobalt",
	lignite = "coal",
	magnetite = "nickel",
	malachite = "nickel",
	manganese = "nickel",
	meteoric_iron = "galaxite",
	moissanite = "tigereye",
	moldavite = "regolith",
	monazite = "aetherite",
	niobium = "gold",
	osmium = "soulstone",
	pallasite = "soulstone",
	petrified_wood = "petrifact",
	pewter = "lapis",
	prismarine = "frostfire",
	quartzite = "pyrite",
	rhodium = "stormstone",
	rhodochrosite = "turquoise",
	ringwoodite = "spectrite",
	sandstone = "clay",
	selenite = "pyrite",
	shungite = "geode",
	silicon_carbide = "tigereye",
	silicon_nitride = "turquoise",
	sphalerite = "aluminum",
	spinel = "sunstone",
	steel = "bismuth",
	stishovite = "celestine",
	tanzanite = "aquamarine",
	tektite = "gold",
	tourmaline = "emerald",
	vanadium_steel = "soulstone",
	wolframite = "stormstone",
	zircon = "moonstone",
	zirconium = "cobalt",
}

--[[
	RESTORED AFTER THE SAME BAD MERGE as the breaking-power block below.
	c59bec5 dropped all three of these while MineServer's load path kept
	reading them, and the failure mode was the quiet kind: the lookup came back
	nil, the type(map) == "table" guard skipped the whole remap, and the stamp
	at the bottom still wrote p.oreRosterV = 2.
	So the 121 -> 82 migration marked itself done having moved nothing, once,
	permanently, for every save that loaded.

	Restored verbatim, after checking it against the roster that actually
	shipped from the merge rather than the one it was written for: all 39
	targets exist in the current MineConfig.ORES, no source id is a live ore,
	and every v1 target either lives or chains through v2.
]]
--[[
	Second roster pass: the 121 became 82 and 39 ids went away.

	v1 above still has to work for a save that never ran it, so this is a
	separate table and a separate stamp rather than an edit: v0 goes 0 -> 1 -> 2,
	v1 goes 1 -> 2. Every v1 target that pointed at one of the 39 has been
	re-pointed to its final home, so no chain ends on an id that no longer
	exists even if only one pass runs.

	Each removed ore goes to the nearest KEPT ore at or below it in the old
	121 order -- downhill, so nobody is handed something they had not earned.
]]
MineConfig.ORE_ROSTER_V = 2
MineConfig.ORE_MIGRATION_V2 = {
	agate = "quartz",
	alexandrite = "moonstone",
	apatite = "amethyst",
	azurite = "nickel",
	beryllium = "cobalt",
	cassiterite = "tin",
	chalcopyrite = "pyrite",
	chert = "flint",
	chromite = "nickel",
	cinnabar = "nickel",
	cobblestone = "stone",
	diorite = "copper",
	electrum = "obsidian",
	fluorite = "nickel",
	fulgurite = "gold",
	galena = "lead",
	hematite = "iron",
	iridium = "galaxite",
	jasper = "quartz",
	kimberlite = "onyx",
	labradorite = "cobalt",
	magnetite = "nickel",
	malachite = "nickel",
	manganese = "nickel",
	moissanite = "amethyst",
	moldavite = "gold",
	niobium = "cobalt",
	osmium = "soulstone",
	quartzite = "pyrite",
	rhodium = "stormstone",
	rhodochrosite = "turquoise",
	sandstone = "clay",
	selenite = "pyrite",
	spinel = "sunstone",
	tanzanite = "aquamarine",
	tektite = "gold",
	tourmaline = "emerald",
	zircon = "emerald",
	zirconium = "cobalt",
}

--[[
	Old ore INDEX -> new ore INDEX, for p.oreTools.

	A saved ore tool stores `tier` as a position in MineConfig.ORES, not an id,
	so renumbering 121 rows down to 82 silently re-points every tool a player
	owns. This is the explicit map: 121 entries, one per old position, each
	landing on the new position of whatever that ore became (itself if it was
	kept, its migration target if it was removed).

	Generated alongside ORE_MIGRATION_V2 and printed by the balance sim. Two old
	positions can share a new one -- Stone and Cobblestone both end up at 1.
]]
MineConfig.ORE_TIER_REMAP_V2 = {
	[1] = 1, [2] = 1, [3] = 2, [4] = 2, [5] = 3, [6] = 4, [7] = 5, [8] = 6, [9] = 7, [10] = 7,
	[11] = 8, [12] = 9, [13] = 10, [14] = 11, [15] = 12, [16] = 12, [17] = 13, [18] = 13, [19] = 14, [20] = 15,
	[21] = 16, [22] = 16, [23] = 17, [24] = 18, [25] = 19, [26] = 19, [27] = 20, [28] = 21, [29] = 21, [30] = 21,
	[31] = 21, [32] = 22, [33] = 23, [34] = 24, [35] = 25, [36] = 25, [37] = 25, [38] = 26, [39] = 27, [40] = 28,
	[41] = 28, [42] = 28, [43] = 28, [44] = 28, [45] = 28, [46] = 28, [47] = 28, [48] = 29, [49] = 29, [50] = 30,
	[51] = 31, [52] = 32, [53] = 33, [54] = 34, [55] = 34, [56] = 35, [57] = 36, [58] = 37, [59] = 37, [60] = 37,
	[61] = 38, [62] = 39, [63] = 40, [64] = 41, [65] = 42, [66] = 43, [67] = 44, [68] = 45, [69] = 46, [70] = 47,
	[71] = 48, [72] = 49, [73] = 49, [74] = 50, [75] = 50, [76] = 50, [77] = 50, [78] = 50, [79] = 51, [80] = 51,
	[81] = 51, [82] = 51, [83] = 52, [84] = 53, [85] = 53, [86] = 54, [87] = 54, [88] = 54, [89] = 55, [90] = 55,
	[91] = 56, [92] = 57, [93] = 58, [94] = 59, [95] = 59, [96] = 60, [97] = 61, [98] = 62, [99] = 62, [100] = 63,
	[101] = 64, [102] = 65, [103] = 66, [104] = 67, [105] = 67, [106] = 68, [107] = 68, [108] = 69, [109] = 70, [110] = 71,
	[111] = 72, [112] = 73, [113] = 74, [114] = 75, [115] = 76, [116] = 77, [117] = 78, [118] = 79, [119] = 80, [120] = 81,
	[121] = 82,
}

--[[
	HOW MANY ORES THERE ARE. 82, and this is the number to read rather than
	`#ORES`, so a caller is never comparing against a stale literal.

	The roster has been renumbered once already (121 down to 82) and it silently
	re-pointed the tool ladder, because several places had the old count written
	into them as a constant.
]]
MineConfig.ORE_COUNT = #MineConfig.ORES

--[[
	THE BANDS, and where they end.

	Cutoffs come straight off ORE_YIELD_BANDS rather than being written out
	again: that table already divides the roster into exactly these eight groups,
	and two lists of the same eight boundaries is one list that will eventually
	be wrong. Change a cutoff there and the band names follow.
]]
MineConfig.ORE_BAND_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic" }
MineConfig.ORE_BAND_INDEX = {}
for i, b in ipairs(MineConfig.ORE_BAND_ORDER) do
	MineConfig.ORE_BAND_INDEX[b] = i
end

-- The band a tier falls in. One function, so the panel, the ore case and the
-- pouch cannot grade the same ore differently.
function MineConfig.oreBandForTier(tier)
	local t = math.max(1, math.floor(tonumber(tier) or 1))
	for i, b in ipairs(MineConfig.ORE_YIELD_BANDS) do
		if t <= b.upTo then
			return MineConfig.ORE_BAND_ORDER[i] or "Common", i
		end
	end
	local last = #MineConfig.ORE_YIELD_BANDS
	return MineConfig.ORE_BAND_ORDER[last] or "Exotic", last
end

MineConfig.ORE_BY_ID = {}
do
	-- D is derived from tier so the ladder cannot drift out of step with it.
	local top = Depth.SECTIONS[#Depth.SECTIONS]
	MineConfig.ORE_DMAX = math.log((top.dirtHp * 2 * 6 ^ 9) / 20) / math.log(6)
	local n = #MineConfig.ORES
	for _, o in ipairs(MineConfig.ORES) do
		o.d = (o.tier - 1) * MineConfig.ORE_DMAX / (n - 1)
		o.packId = o.id .. "_ore_pack"
		--[[
			Band, and the HP of the rock this ore calls home.

			Both are DERIVED, not authored on the row: `d` is already the ore's
			depth coordinate, and 20 * 6^d is the rock HP at that coordinate --
			the same 20 and the same 6 that ORE_DMAX is defined with just above,
			so homeHp and d cannot drift apart.

			homeHp is what the ore pouch prices gem value off. It is on the row
			rather than recomputed per call because the pouch asks for it once
			per row per frame.
		]]
		o.band, o.bandIndex = MineConfig.oreBandForTier(o.tier)
		o.homeHp = 20 * (6 ^ o.d)
		MineConfig.ORE_BY_ID[o.id] = o
	end
end

function MineConfig.oreById(id)
	return MineConfig.ORE_BY_ID[tostring(id or "")]
end

--[[
	ORE FINDER -- a better roll, not a bigger one.

	`rareOre` has been on runes, on cards (Seer, Prospector, Vein Sense) and on
	the Crystal skill branch since long before ore existed, described as
	"weighting toward deeper, richer ore". It has never done anything. This is
	what it does.

	It does NOT multiply how much ore you get. It shifts the hardness the roll
	thinks it is standing in, so the SAME number of ore blocks come up better.
	+2000% finder is not 2000% more loot -- it is a roll taken ~9 tiers up the
	ladder, which at the bottom of Primordium is the difference between
	Aquamarine and something with a glow on it.

	log6 because the whole axis is log6: multiplying finder power by 6 buys
	one full zone-step of roll quality, and the returns taper the way every
	other number in this game does.
]]
function MineConfig.oreFindShift(rareOre)
	local m = math.max(1, tonumber(rareOre) or 1)
	return math.log(m) / math.log(6)
end

-- How hard the rock is here, on the same axis the ores sit on.
function MineConfig.oreDifficulty(zoneId, layer)
	local hp = MineConfig.blockHp("dirt", zoneId, layer)
	return math.log(math.max(20, hp) / 20) / math.log(6)
end

--[[
	Weights for this spot, cached.

	rollOre runs for EVERY block the generator makes, and the weight table is
	121 exp() calls. It only changes when the SECTION changes, though, so this
	is computed once per zone+section -- 825 times for the whole game rather
	than once per block.
]]
local oreWeightCache = {}
function MineConfig.oreWeights(zoneId, layer, rareOre)
	local sec = Depth.sectionFor and Depth.sectionFor(layer)
	-- Finder power is bucketed to 1/20 of a D-step before it reaches the key,
	-- so two players a hair apart still share a cached table.
	local bucket = math.floor(MineConfig.oreFindShift(rareOre) * 20 + 0.5)
	local key = tostring(zoneId) .. "|" .. tostring((sec and sec.id) or math.floor(layer / 40))
		.. "|" .. tostring(bucket)
	local hit = oreWeightCache[key]
	if hit then
		return hit
	end
	local dl = MineConfig.oreDifficulty(zoneId, layer) + bucket / 20
	local X0, K, S, W = MineConfig.ORE_X0, MineConfig.ORE_K, MineConfig.ORE_S, MineConfig.ORE_W
	local list = MineConfig.ORES
	local w, tot = table.create(#list), 0
	for i, o in ipairs(list) do
		local x = o.d - dl
		local v = 1 / (1 + math.exp((x - X0) / K))
		if x < 0 then
			v = v * math.exp(x / S) * math.exp(-((x / W) ^ 2))
		end
		w[i] = v
		tot += v
	end
	local row = { w = w, tot = tot }
	oreWeightCache[key] = row
	return row
end

-- WHICH ore, given that it already is one. Never returns nil for a real zone.
function MineConfig.oreIdentity(zoneId, layer, rng, rareOre)
	local row = MineConfig.oreWeights(zoneId, layer, rareOre)
	if row.tot <= 0 then
		return nil
	end
	local pick = ((rng and rng.NextNumber) and rng:NextNumber() or math.random()) * row.tot
	local list = MineConfig.ORES
	for i, o in ipairs(list) do
		pick -= row.w[i]
		if pick <= 0 then
			return o
		end
	end
	return list[#list]
end

-- Is this block ore, and which. A flat 1 in 200 everywhere; the curve only
-- decides WHICH ore, never how much ore there is.
function MineConfig.rollOre(zoneId, layer, rng, rareOre)
	local roll = (rng and rng.NextNumber) and rng:NextNumber() or math.random()
	if roll >= MineConfig.ORE_CHANCE then
		return nil
	end
	return MineConfig.oreIdentity(zoneId, layer, rng, rareOre)
end

-- Kept for callers that want the roster; ore is no longer filtered by zone.
function MineConfig.oresFor()
	return MineConfig.ORES
end


return MineConfig
