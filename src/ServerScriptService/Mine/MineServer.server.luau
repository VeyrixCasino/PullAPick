-- MineServer compact: AFK mining TCG. Original city place is not modified.
--[[
	ONE TABLE FOR THE SERVICES, AND IT IS NOT TIDINESS.

	Luau gives a function 200 registers, and a script's main chunk IS a
	function, so every top-level local spends one. This script had ZERO left:
	tools/verify/compile.js measures headroom by appending live locals until
	the compile fails, and the answer here was 0. The next top-level local
	added by anyone would have stopped the whole script compiling -- which does
	not fail loudly. It happened on 2026-10-05: the server script never ran, so
	MineNet was never created and every client hung on WaitForChild, with one
	line in the output to explain it.

	Seven service locals become one, buying back six registers. Services are
	the cheapest place to find them: referenced often, declared once, so the
	saving is structural rather than a rewrite of any logic.
]]
local Svc = {
	Players = game:GetService("Players"),
	Run = game:GetService("RunService"),
	Teleport = game:GetService("TeleportService"),
	Collection = game:GetService("CollectionService"),
	DSS = game:GetService("DataStoreService"),
	Marketplace = game:GetService("MarketplaceService"),
	RS = game:GetService("ReplicatedStorage"),
}

local shared = Svc.RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared.MineConfig)
local Cards = require(shared.MineCards)
local Packs = require(shared.MinePackConfig)
local PetRoster = require(shared:WaitForChild("MinePetRoster"))
local Skills = require(shared.MineSkillData)
local EventPass = require(shared:WaitForChild("MineEventPass"))
local DiscordLink = require(shared:WaitForChild("MineDiscordLink"))
-- Deep Mine 1 shafts must not be auto-destroyed by the engine. This is set in
-- the place file as well; the write here is a belt-and-braces retry and is
-- wrapped because Studio now refuses it from a plain Script ("lacking
-- capability Plugin"), and an unguarded failure on line 16 took the whole
-- server down with it -- no MineNet, so every client hung on WaitForChild
-- and the game did nothing at all.
pcall(function()
	workspace.FallenPartsDestroyHeight = -100000
end)
local Patterns = require(script.Parent:WaitForChild("MinePatterns"))
local MineAntiGear = require(script.Parent:WaitForChild("MineAntiGear"))
local MineBadges = require(script.Parent:WaitForChild("MineBadges"))
local Tools = require(shared.MineTools)
local ChestModel = require(shared:WaitForChild("MineChestModel"))
local ToolModels = require(game.ReplicatedStorage:WaitForChild("ToolModelFactory"))
local Stats = require(shared.MineStats)
local Runes = require(shared.MineRunes)
local Charms = require(shared:WaitForChild("MineCharms"))
local Vfx = require(shared:WaitForChild("MineVfx"))
local Gear = require(shared.MineGear)
local Scrolls = require(shared.MineScrolls)
local LuckyBlocks = require(shared.MineLuckyBlocks)
local Quests = require(shared:WaitForChild("MineQuests"))
local WorldBuilder = require(script.Parent.WorldBuilder)
local LeaderboardService = require(script.Parent:WaitForChild("LeaderboardService"))
local GroupWheelService = require(script.Parent:WaitForChild("GroupWheelService"))
local TradeService = require(script.Parent:WaitForChild("TradeService"))
local SocialService = require(script.Parent:WaitForChild("SocialService"))
-- Mine For Cards modules packed as one local to spare the 200-register main-chunk cap.
local Dig = {
	-- Traits: the prefix on a forged tool, and the one thing runes and
	-- gear were replaced by. On Dig rather than a top-level local because this
	-- script sits at 197 of Luau's 200, and boosts() reads it per swing so a
	-- require-per-call is not an option either.
	Traits = require(shared:WaitForChild("MineTraits")),
	-- Two layers, and the second multiplies the first. See MineBoostLayers
	-- for the owner's worked example (100 -> 300, not 250).
	Layers = require(shared:WaitForChild("MineBoostLayers")),
	Depth = C.Depth or require(shared:WaitForChild("MineDepth")),
	Auth = require(script.Parent:WaitForChild("MineDigAuth")),
	Shop = require(shared:WaitForChild("MineDepthShop")),
	Plazas = require(script.Parent:WaitForChild("MineDepthPlazas")),
	Breaking = require(shared:WaitForChild("MineBreaking")),
	-- The wandering trader: rules in MineTrader (shared, harnessed), bodies in
	-- MineTraderNPC (server). On Dig for the same reason as the rest -- this
	-- script has five top-level locals left and these do not need two of them.
	Trader = require(shared:WaitForChild("MineTrader")),
	TraderNPC = require(script.Parent:WaitForChild("MineTraderNPC")),
	-- The season clock. MineRotatingOffers and MineScrolls already default their
	-- `now` to Launch.seasonNow(), so this handle exists for the server to LOAD
	-- and STAMP the flag; nothing reads the time through it.
	Launch = require(shared:WaitForChild("MineLaunch")),
}
-- TODO(dig-deeper): skill 4x depth bonuses not implemented yet — leave skill tables alone.

local store = Svc.DSS:GetDataStore(C.DATASTORE)
-- Per-card ownership ledger: key = 16-hex serial, value = userId.
local serialStore = Svc.DSS:GetDataStore(tostring(C.DATASTORE) .. "_card_serials")
local profiles, busy, voxels, swingBudget = {}, {}, {}, {}
-- In-flight battle-pass claims: [userId] = { ["free_3"|"premium_3"] = true }
local claimPassLocks = {}
-- Packed scalars: keeps MineServer under Luau's 200 main-chunk local register cap.
local Const = {
	THROW_SPEED = 78,
	THROW_LIFT = 16,
	THROW_GRAV = 62,
	THROW_MAX = 2.6,
	VOXEL_SKIP = { Skip = true },
	GROUND_Y = 5,
	OPEN_RUN_MAX = 50,
	--[[
		Most of one item a player may buy in a single typed request.

		Owner, 2026-10-03: "a custom amoujt of packs to buy (the player can
		write the number themselves [default 1])". A text box needs a ceiling
		or a fat-fingered 999999 is one request that spends a whole bank.
	]]
	BUY_QTY_MAX = 100,
	-- One number, shared with the Select UI that has to clamp to it.
	SCRAP_MAX = C.SCRAP_MAX,
	ROLL_MAX = 100,
	-- Chunk size. Generation runs three layers at a time and the next chunk
	-- is cut as soon as a block in the current one is touched.
	ENSURE_BAND = 3,
	-- Beyond this far below the frontier it is an arrival, not a dig, and the
	-- chunk is cut at the destination instead of extending the frontier.
	ENSURE_FAR = 64,
	-- Layers below the server-wide dug depth before a dig is worth a look.
	FLAG_DEPTH_SLACK = 250,
	CART_MAX_LINES = 24,
	--[[
		Most of one line the cart will buy. RAISED 25 -> 100 on 2026-10-04 to
		match BUY_QTY_MAX below and the typed quantity box in
		MineInventoryView, which allows the same number.

		These three have to agree. A box that accepts 60 above a server that
		silently clamps to 25 is a box that lies, which is the exact failure
		the pack tile's own comment warns about ("a button that says x10 above
		a stack of six is a button that lies"). tools/verify/buyqty.js pins
		them together.
	]]
	CART_MAX_QTY = 100,
}
local mineResetState = { at = {}, warned = {} }
-- VIP gamepass ownership cache (server-authoritative). Keyed by userId.
local vipPassOwned = {}

--[[
	Warehouse Pass seats remaining ON THIS SERVER.

	Declared up here rather than beside joinVip, because snap() reads it and
	snap() is defined two and a half thousand lines earlier. A local declared
	below its reader is a nil global to that closure -- no error at load, the
	snapshot just quietly ships `vipSeats = nil` forever, and the VIP page
	renders it as "0 seats left on this server".

	Seats reset when the server does. The VIP page says exactly that; a scarcity
	number that silently resets is one players work out, and then they stop
	trusting every other number on the page.
]]
local vipSeatsLeft = Packs.VIP_SEATS or 500

local function applyVipNameTag(plr, owns)
	if not plr then
		return
	end
	local p = profiles[plr.UserId]
	if p then
		p.vfx = p.vfx or {}
		if owns then
			p.vfx.tag_vip = true
		end
		if type(p.vip) == "table" and p.vip.since then
			p.vfx.tag_founder = true
		end
	end
	local tag = (p and type(p.equippedVfx) == "table" and p.equippedVfx.tag) or nil
	local prefix = ""
	local founder = p and type(p.vip) == "table" and p.vip.since
	local vip = owns == true or (p and p.vipPass == true)
	if tag == "tag_none" then
		prefix = ""
	elseif tag == "tag_founder" and founder then
		prefix = C.FOUNDERS_NAME_PREFIX or "[Founder] "
	elseif tag == "tag_vip" and vip then
		prefix = C.VIP_NAME_PREFIX or "[VIP] "
	elseif founder then
		prefix = C.FOUNDERS_NAME_PREFIX or "[Founder] "
	elseif vip then
		prefix = C.VIP_NAME_PREFIX or "[VIP] "
	end
	plr:SetAttribute("NamePrefix", prefix)
	plr:SetAttribute("VipPass", vip)
	local function paint(char)
		if not char then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end
		hum.DisplayName = prefix .. plr.DisplayName
	end
	paint(plr.Character)
end

local function refreshVipPass(plr)
	if not plr then
		return false
	end
	local ok, owns = pcall(function()
		return Svc.Marketplace:UserOwnsGamePassAsync(plr.UserId, C.VIP_GAMEPASS_ID or 1977363670)
	end)
	local valued = (ok and owns == true) or false
	vipPassOwned[plr.UserId] = valued
	local p = profiles[plr.UserId]
	if p then
		p.vipPass = valued
		local function ownPass(gid)
			gid = tonumber(gid) or 0
			if gid <= 0 then
				return false
			end
			local ok2, owns2 = pcall(function()
				return Svc.Marketplace:UserOwnsGamePassAsync(plr.UserId, gid)
			end)
			return ok2 and owns2 == true
		end
		if ownPass(C.COIN_DOUBLE_GAMEPASS_ID) then
			p.coinDouble = true
		end
		if ownPass(C.AUTO_MINE_GAMEPASS_ID) then
			p.autoMineLicense = true
		end
	end
	applyVipNameTag(plr, valued)
	return valued
end

local function hasVipPass(plr)
	if not plr then
		return false
	end
	local cached = vipPassOwned[plr.UserId]
	if cached ~= nil then
		return cached
	end
	local p = profiles[plr.UserId]
	if p and type(p.vipPass) == "boolean" then
		vipPassOwned[plr.UserId] = p.vipPass
		return p.vipPass
	end
	return refreshVipPass(plr)
end

local remotes = Svc.RS.Mine:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = Svc.RS.Mine
local net = remotes:FindFirstChild("MineNet") or Instance.new("RemoteEvent")
net.Name = "MineNet"
net.Parent = remotes

-- Admin remotes are created HERE, not in MineAdmin.start().
--
-- start() is called at the very bottom of this file (~line 14990 of 15000) with
-- 100+ yield points ahead of it, so MineAdminClient:19 -- a top-level
-- WaitForChild("AdminReady") with no timeout -- reached its wait long before the
-- remote existed and warned "Infinite yield possible". The panel then never
-- appeared for admins, silently: the fallback at MineAdminClient:861 cannot help
-- because line 19 never returns.
--
-- Creating them up here costs nothing (bare instances, no handlers) and start()
-- is FindFirstChild-or-create, so it adopts these rather than making new ones.
-- IIFE so these do not burn main-chunk registers (Luau 200-local cap).
do
	local function ensureRemote(name, className)
		local r = remotes:FindFirstChild(name) or Instance.new(className)
		r.Name = name
		r.Parent = remotes
		return r
	end
	ensureRemote("AdminReady", "RemoteEvent")
	ensureRemote("AdminNotify", "RemoteEvent")
	ensureRemote("AdminInvoke", "RemoteFunction")
end

require(shared.MineWorldEvents).bind({
	C = C,
	Gear = Gear,
	Players = Svc.Players,
	profiles = profiles,
	net = net,
})

-- Card serial: 3-hex species prefix + 16-hex instance = 19 hex chars.
-- Species prefix is stable per pet name (sorted roster index). Instance id
-- never changes on trade/equip/inventory moves. If the same full serial is
-- ever found on two profiles, both copies are nuked and the ledger entry cleared.
local SPECIES_HEX_BY_NAME = (PetRoster and PetRoster.HEX3_BY_NAME) or {}
if next(SPECIES_HEX_BY_NAME) == nil then
	-- Fallback if roster hex3 table missing.
	local names = {}
	for _, pet in ipairs((PetRoster and PetRoster.PETS) or {}) do
		if type(pet) == "table" and type(pet.name) == "string" then
			table.insert(names, pet.name)
		end
	end
	table.sort(names)
	for i, name in ipairs(names) do
		SPECIES_HEX_BY_NAME[name] = string.format("%03x", i)
	end
end

local function speciesHex3(def)
	def = def or {}
	local name = def.name
	if type(name) == "string" and SPECIES_HEX_BY_NAME[name] then
		return SPECIES_HEX_BY_NAME[name]
	end
	-- Fallback for non-roster cards: stable hash of cardKey / set+index.
	local s = tostring(def.cardKey or ((def.setId or "?") .. ":" .. tostring(def.index or 0)))
	local h = 0
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 4096
	end
	-- Avoid 000 which we reserve as "unknown" visually if needed — still valid.
	return string.format("%03x", h)
end

local function instanceHex16()
	local g = string.gsub(game:GetService("HttpService"):GenerateGUID(false), "-", ""):lower()
	return string.sub(g, 1, 16)
end

local function makeSerial(def)
	return speciesHex3(def) .. instanceHex16()
end

local function isCardSerial(s)
	return type(s) == "string" and #s == 19 and string.match(s, "^%x+$") ~= nil
end

-- Same 16-hex instance format as runes / gear (not the 19-char card serial).
local function isInstanceHex16(s)
	return type(s) == "string" and #s == 16 and string.match(s, "^%x+$") ~= nil
end

--[[
	FOSSILS ARE GONE, AND THIS IS THE LAST OF THEM.

	MineFossils and MineFossilEconomy are deleted. What is left is the one thing
	that could not be: a save can still be holding pieces and assembled tools,
	and those have to be paid for rather than silently dropped.

	THE PRICE IS FROZEN HERE, NOT LOOKED UP. It is the exact formula MineFossils
	used, copied rather than approximated:

	    zi        the pair's zone index: grove 2, tide 4, scarlet 6,
	              fracture 8, myth 10
	    per band  shallow x3, mid x12, deep x40
	    gemMin    = max(1, floor(zi * bandMult))
	    gemMax    = max(gemMin + 1, floor(gemMin * (deep and 8 or 5)))
	    value     = floor(gemMin + (gemMax - gemMin) * grade + 0.5)
	    grade     = mean over the pieces of
	                clamp01(layer / 2500) * 0.65 + quality * 0.35

	A recipe id is `pair_<name>_<band>_<slot>`, so the pair and band read
	straight off it. Six ids predate that scheme (LEGACY_IDS in the old module,
	all in pair_grove) and are listed below, because parsing them would give the
	wrong pair and quietly underpay.

	THIS WHOLE BLOCK IS DELETABLE once enough players have logged in to drain
	the old saves. Nothing else references it, and deleting it costs exactly one
	thing: anyone who has not logged in since the retirement keeps their pieces
	as dead data instead of gems.
]]
--[[
	Everything the payout needs, in ONE top-level local.

	Eight separate ones put this file at 205 against Luau's hard ceiling of 200,
	and a migration that will be deleted is the last thing that should spend
	five of the four remaining slots.
]]
local FossilPay = {
	-- The pair's zone index.
	ZI = { pair_grove = 2, pair_tide = 4, pair_scarlet = 6, pair_fracture = 8, pair_myth = 10 },
	BAND = { shallow = 3, mid = 12, deep = 40 },
	-- The six ids minted before the pair_<name>_<band>_<slot> scheme. All grove.
	LEGACY = {
		seismic_reaver = { "pair_grove", "shallow" },
		wraithorebit = { "pair_grove", "shallow" },
		spikeslicer = { "pair_grove", "mid" },
		tallurn = { "pair_grove", "mid" },
		yardspiral = { "pair_grove", "deep" },
		archcask = { "pair_grove", "deep" },
	},
	-- Pieces a full set took (MineFossilEconomy.PIECES_NEEDED).
	NEEDED = 100,
	MAX_LAYER = 2500,
}

-- (pair, band) for a recipe id, or nil if it is not one we can price.
function FossilPay.where(recipeId)
	local id = tostring(recipeId or "")
	local legacy = FossilPay.LEGACY[id]
	if legacy then
		return legacy[1], legacy[2]
	end
	local pair, band = string.match(id, "^(pair_%a+)_(%a+)_")
	if pair and FossilPay.ZI[pair] and FossilPay.BAND[band] then
		return pair, band
	end
	return nil
end

-- Gems one piece of this recipe is worth at this grade. The frozen formula.
function FossilPay.gems(recipeId, grade)
	local pair, band = FossilPay.where(recipeId)
	if not pair then
		return 0
	end
	local gemMin = math.max(1, math.floor(FossilPay.ZI[pair] * FossilPay.BAND[band]))
	local gemMax = math.max(gemMin + 1, math.floor(gemMin * (band == "deep" and 8 or 5)))
	local g = math.clamp(tonumber(grade) or 0, 0, 1)
	return math.floor(gemMin + (gemMax - gemMin) * g + 0.5)
end

-- Mean quality of a set of pieces, 0..1. Depth counts for most of it.
function FossilPay.grade(pieces)
	if type(pieces) ~= "table" or #pieces == 0 then
		return 0
	end
	local sum = 0
	for _, piece in ipairs(pieces) do
		local layer = math.max(1, math.floor(tonumber(piece.layer) or 1))
		local depth = math.clamp(layer / FossilPay.MAX_LAYER, 0, 1)
		local quality = piece.qualityRoll or piece.quality
		quality = (quality == nil) and 0.5 or math.clamp(tonumber(quality) or 0.5, 0, 1)
		sum += depth * 0.65 + quality * 0.35
	end
	return math.clamp(sum / #pieces, 0, 1)
end

--[[
	Cash out whatever the retired fossil system left on this profile, once.

	Returns the gems paid so the caller can tell the player. Idempotent: it
	clears the fields, so a second load finds nothing and pays nothing.
]]
local function retireFossils(p)
	if type(p) ~= "table" then
		return 0
	end
	local gems = 0

	-- Loose pieces, grouped by recipe so grade is computed over the set the way
	-- the bench computed it rather than per piece.
	local byRecipe = {}
	for _, piece in ipairs(p.fossilPieces or {}) do
		if type(piece) == "table" and piece.fossilId then
			local key = tostring(piece.fossilId)
			byRecipe[key] = byRecipe[key] or {}
			table.insert(byRecipe[key], piece)
		end
	end
	for recipeId, pieces in pairs(byRecipe) do
		gems += FossilPay.gems(recipeId, FossilPay.grade(pieces)) * #pieces
	end

	-- Assembled tools, at what they cost to build: a full set at full grade.
	-- That is the one judgement call here, and the one that cannot leave anyone
	-- worse off than if they had never assembled the thing.
	for key, ft in pairs(p.fossilTools or {}) do
		if type(ft) == "table" then
			gems += FossilPay.gems(ft.fossilId or key, 1) * FossilPay.NEEDED
		end
	end

	--[[
		Held fossil PACKS, too.

		These used to cash out when OPENED, because the pack rows were still
		registered and an unopenable pack reads as a bug. The rows are gone now
		(MineZonePacks dropped its three fossil slots, Mine1PacksData its three
		packs), so an unopened one would be an inventory row with no definition
		behind it. It pays here instead, at the same rate the open branch used:
		a mid-band recipe at full grade, three pieces a pull.

		Matched on the substring rather than a list, because the ids came in six
		shapes -- "fossil_pack", the three zone-prefixed ones, and the two
		legacy aliases ("fossil_deep_pack", "fossil_abyss_pack").
	]]
	if type(p.packs) == "table" then
		local keep = {}
		for _, pk in ipairs(p.packs) do
			local id = type(pk) == "table" and tostring(pk.packId or "") or ""
			if id ~= "" and string.find(id, "fossil", 1, true) then
				local pulls = tonumber(type(pk) == "table" and pk.pulls) or 3
				local count = math.max(1, math.floor(tonumber(type(pk) == "table" and pk.count) or 1))
				gems += FossilPay.gems("pair_tide_mid_pick", 1) * 3 * pulls * count
			else
				table.insert(keep, pk)
			end
		end
		p.packs = keep
	end

	p.fossilPieces = nil
	p.fossilTools = nil
	p.fossilTool = nil
	if gems > 0 then
		p.gems = (tonumber(p.gems) or 0) + gems
	end
	return gems
end

--[[
	BANK UNOPENED ORE PACKS, as many as the pouch will hold.

	An ore block hands over its ore directly now (see the `kind == "ore"` break
	branch), so an "<id>_ore_pack" sitting in the bag is a legacy row whose
	contents were already settled when the block broke -- opening it reveals
	nothing that was not decided then. A bag of hundreds of single-ore packs was
	the most-complained-about screen in the game, and asking the player to clear
	it by hand is the same screen with extra steps.

	CAPACITY DECIDES HOW MANY, and nothing is destroyed to make it tidy.
	Dig.addOre spills whatever does not fit and spilled ore is gone, so this
	checks for room FIRST and converts a pack only when its whole yield lands.
	What does not fit STAYS A PACK: it is retried on the next load, and it can
	still be opened by hand once there is room, because MineZonePacks keeps the
	"_ore_pack" ids registered.

	That is also why there is NO VERSION STAMP. A stamp would mean a player with
	a full pouch converts nothing and is marked done, stranding the rest for
	good; this is idempotent and has to be able to run again.

	THE AMOUNT IS THE BAND MIDPOINT, NOT A ROLL. Opening pays a uniform
	[lo, hi], so the midpoint is the same in expectation -- and being
	deterministic means rejoining cannot re-roll a bad result. The pack's
	STAMPED finder still applies, capped exactly as the open branch caps it:
	the pack has carried that number since break time, and dropping it here
	would quietly pay less than opening by hand.

	Returns packs converted and ore banked. It does NOT bump the "packs" stat:
	these were not opened, and counting them would jump every pack quest.
]]
function Dig.bankOrePacks(p)
	if type(p) ~= "table" or type(p.packs) ~= "table" then
		return 0, 0
	end
	local Pouch = Dig.pouch()
	local cap = tonumber(C.ORE_PACK_FIND_CAP) or 1
	local keep, converted, banked = {}, 0, 0
	for _, pk in ipairs(p.packs) do
		local id = (type(pk) == "table") and tostring(pk.packId or "") or ""
		local oreId = (id ~= "") and string.match(id, "^(.*)_ore_pack$") or nil
		local ore = oreId and C.oreById(oreId) or nil
		if not ore then
			table.insert(keep, pk)
		else
			local lo, hi = C.oreYieldFor(ore.tier)
			lo, hi = math.min(lo, hi), math.max(lo, hi)
			local find = math.min(math.max(0, tonumber(pk.oreFind) or 0), cap)
			local each = math.max(1, math.floor(((lo + hi) / 2) * (1 + find) + 0.5))
			-- Rows stack (see the merge in openPack), so one row can be many packs.
			local left = math.max(1, math.floor(tonumber(pk.count) or 1))
			while left > 0 do
				p.ores = p.ores or {}
				if Pouch.room(p.ores, Dig.pouchTier(p)) < each then
					break
				end
				local got = Dig.addOre(p, ore.id, each)
				if got <= 0 then
					break
				end
				banked += got
				converted += 1
				left -= 1
			end
			if left > 0 then
				pk.count = left
				table.insert(keep, pk)
			end
		end
	end
	p.packs = keep
	return converted, banked
end

-- chestTools shipped as a flat array of id strings, then started carrying a
-- socketed rune -- and a string cannot hold a rune. Every entry is a row now.
local function reconcileChestTools(p)
	p.chestTools = p.chestTools or {}
	local rows, seen = {}, {}
	for _, entry in ipairs(p.chestTools) do
		local id = (type(entry) == "table") and entry.id or entry
		local def = (type(id) == "string") and Tools.chestTool(id) or nil
		if def and not seen[id] then
			seen[id] = true
			if type(entry) == "table" then
				entry.id, entry.name, entry.family = def.id, def.name, def.family
				entry.rarity = def.rarity or def.rarityId or entry.rarity
				entry.rarityId = entry.rarity
				entry.level = nil
				entry.temperRolls = tonumber(entry.temperRolls) or 0
				--[[
					Temperaments are bought, never given. Every found tool used to
					arrive with a free "starter" one, and this used to roll one onto
					any tool missing it. Now a tool has a temperament only after
					tokens were spent on it (Verbs.rollTemper counts those in
					temperRolls), so the free ones already sitting on saves --
					temperRolls still 0 -- come off here.
				]]
				local Temper = require(shared.MineTemper)
				if entry.temperRolls <= 0 then
					entry.temperId, entry.temperRarity, entry.tempers = nil, nil, nil
				elseif entry.temperId and not Temper.kit(entry.temperId) then
					entry.temperId, entry.temperRarity = nil, nil
				elseif entry.temperId and not entry.temperRarity then
					local kit = Temper.kit(entry.temperId)
					entry.temperRarity = kit and kit.rarity or "Common"
				end
				table.insert(rows, entry)
			else
				table.insert(rows, {
					id = def.id, name = def.name, family = def.family,
					temperRolls = 0,
				})
			end
		end
	end
	p.chestTools = rows
	if p.chestTool and not Tools.chestTool(p.chestTool) then p.chestTool = nil end
end

local function serialSpecies(serial)
	if isCardSerial(serial) then
		return string.sub(serial, 1, 3)
	end
	return nil
end

-- Returns "won" | "taken" | "error". DataStore blips must NOT look like
-- someone else owns the card — that path used to wipe the whole binder.
local function claimSerial(serial, userId)
	if not isCardSerial(serial) or not userId then
		return "error"
	end
	-- Studio DataStore queues stall join when every card claims on load.
	-- Trust the local profile in Studio; live servers still hit the ledger.
	if Svc.Run:IsStudio() then
		return "won"
	end
	local status = "error"
	local ok = pcall(function()
		serialStore:UpdateAsync(serial, function(old)
			if old == nil or old == userId then
				status = "won"
				return userId
			end
			status = "taken"
			return old
		end)
	end)
	if not ok then
		return "error"
	end
	return status
end

local function claimSerialOk(serial, userId)
	return claimSerial(serial, userId) == "won"
end

local function transferSerial(serial, fromUserId, toUserId)
	if not isCardSerial(serial) or not toUserId then
		return false
	end
	local won = false
	pcall(function()
		serialStore:UpdateAsync(serial, function(old)
			if old == nil or old == fromUserId then
				won = true
				return toUserId
			end
			won = false
			return old
		end)
	end)
	return won
end

local function clearSerialLedger(serial)
	if not isCardSerial(serial) then
		return
	end
	pcall(function()
		serialStore:UpdateAsync(serial, function()
			return nil
		end)
	end)
end

local function stripSerialFromProfile(p, serial)
	if not p then
		return 0
	end
	local n = 0
	local keep = {}
	for _, c in ipairs(p.cards or {}) do
		if (c.serial or c.id) == serial then
			n += 1
		else
			table.insert(keep, c)
		end
	end
	p.cards = keep
	local eq = {}
	for _, id in ipairs(p.equipped or {}) do
		if id ~= serial then
			table.insert(eq, id)
		end
	end
	p.equipped = eq
	return n
end

-- If the same serial exists on more than one loaded profile (or ledger says
-- another owner while we also hold it), destroy every live copy and clear ledger.
local function nukeSerialEverywhere(serial, reason)
	if not isCardSerial(serial) then
		return
	end
	clearSerialLedger(serial)
	local hit = 0
	for _, plr in ipairs(Svc.Players:GetPlayers()) do
		local p = profiles[plr.UserId]
		if p then
			local n = stripSerialFromProfile(p, serial)
			if n > 0 then
				hit += n
			end
		end
	end
	warn("[Mine] nuked serial", serial, "copies=", hit, reason or "")
end

local function releaseSerial(serial, userId)
	-- Kept for call sites; prefer clear/nuke for contested ids.
	if not isCardSerial(serial) then
		return
	end
	pcall(function()
		serialStore:UpdateAsync(serial, function(old)
			if old == userId then
				return nil
			end
			return old
		end)
	end)
end

local function blank()
	return {
		gems = 0, coins = 0, spaceCoins = 0, haulSpace = 0, haulMix = {}, dust = 0, prestige = 0, pickaxeTier = 1, backpackTier = 1,
		wormholeBag = false, eventToolId = nil, eventTools = {},
		relics = {}, charter = {}, chestTools = {}, chestTool = nil,
		pass = Scrolls.emptyPass(),
		daily = { streak = 0, last = 0 },
		groupWheel = { last = 0 },
		discordLinked = false,
		discordId = nil,
		discordBonusClaimed = false,
		quest = 1,
		stats = { blocks = 0, sells = 0, packs = 0, merges = 0, chests = 0, rebirth = 0 },
		dailyQuests = { day = 0, list = {} },
		intro = 1,
		found = {},
		-- Per dev product, how many this player has bought with credits.
		creditBuys = {},
		-- How many of each pack id this player has ever opened. `found` next to
		-- it counts CHESTS; this counts packs, which is what the pack inspector
		-- reports back. How many were found is not stored: a pack can only be
		-- acquired or opened, so found is opened plus whatever is still in the
		-- bag, and deriving it cannot drift out of step with reality.
		packsOpened = {},
		haulCoins = 0, haulGems = 0,
		petSlots = C.STARTER_PET_SLOTS, zoneId = "meadow", maxUnlockedZone = 1,
		-- Item bag rungs bought. Capacity is derived, never stored.
		itemSlotUpgrades = 0,
		bigbangOwned = false,
		coreSamples = {},
		coreRiftOpened = {},
		deepest = {}, depthUnlock = {}, backpack = {},
		-- Seams bought, keyed "<zoneIndex>:<seam>". Depth is the one axis nothing
		-- else gates, and ore tool power rides it.
		seams = {},
		-- Four meadow Loam packs so the first Inventory open has something to crack
		-- before the player finds a chest. Real roster ids, not placeholder wrappers.
		packs = {
			{ setId = "dragons_dawn", packId = "loam_pack", packName = "Loam Pack" },
			{ setId = "dragons_dawn", packId = "loam_pack", packName = "Loam Pack" },
			{ setId = "dragons_dawn", packId = "loam_pack", packName = "Loam Pack" },
			{ setId = "dragons_dawn", packId = "loam_pack", packName = "Loam Pack" },
		},
		cards = {}, equipped = {},
		-- Ore, by id. Spent at the Forge to build tools and to upgrade them,
		-- with stardust. (Build path lands with the Forge -- see docs/TODO.md.)
		ores = {},
		-- The pouch: its rung, and which ores Sell All must not touch. Both
		-- survive a rebirth, along with everything in the pouch.
		orePouchTier = 1,
		oreLocks = {},
		--[[
			Ore tools: one row per tool the player owns, not a count.

			An ore tool is a distinct object -- a tier-74 Frack at level 300 is
			not interchangeable with another tier-74 Frack at level 12 -- so it
			cannot be stored as a quantity the way charms and tempers are. Each
			row carries its own uid from the moment it is made, so it can be
			named for upgrading, recycling or trading without relying on its
			position in the list.

			  { uid, tier, typeId, level }

			The uid is minted once and NEVER regenerated -- not on upgrade, not
			on equip, not on trade. Levelling mutates `level` and touches
			nothing else, so a tool is the same object at level 900 that it was
			at level 1. That is the whole point of having the id: without it,
			"which Frack did I just upgrade" has no answer.

			`level` runs 1..MineConfig.TOOL_MAX_LEVEL and defaults to 1: a tool
			found in a wall has had nothing put into it, which is why recycling
			one pays nothing and the rate can stay a flat half of what went in.
		]]
		oreTools = {},
		--[[
			Every ore this player has ever held, as a set.

			The Forge lists a recipe per DISCOVERED ore, and holding a count is
			not the same as having discovered one: spend your last Halite and
			the Halite recipe would vanish, which reads as the game forgetting
			something you plainly found. This set only ever grows, within a save.
		]]
		oresSeen = {},
		-- How full the bag is, in block-equivalents. Every point of damage adds
		-- damage/maxHp, so the bag creeps up as you mine instead of jumping when
		-- a block dies, and a 41,000 HP crystal fills exactly as much as a clod
		-- of dirt.
		load = 0,
		-- Rebirth skills. `skillEarned` is lifetime tokens; each preset tracks
		-- what it has spent, so switching builds never invents or eats points.
		-- Tools: the family in hand, and the best tier owned in each family.
		-- `pickaxeTier` is kept only so old saves migrate cleanly.
		toolFamily = "pickaxe", toolEquipped = true,
		-- No pickaxe. The first one is collected, free, from the Blacksmith.
		tools = { pickaxe = 0, drill = 0, explosive = 0 },
		gotFirstPick = false,
		skillEarned = 0, skillBought = 0, skillSlot = 1, skillPresets = { { levels = {}, spent = 0 } },
		-- skillBurned: points destroyed by sacrifice. temperTokens: what they paid.
		boughtSecond = false, skillBurned = 0, temperTokens = 0,
		runes = {}, gear = {},
		-- Three hat seats, all the player's. Pets wear nothing.
		equippedGear = { hat = nil, hat2 = nil, hat3 = nil, face = nil },
		toolSockets = { pickaxe = nil, drill = nil, explosive = nil },
		-- One temperament per tool family. Lives on the family, like its runes.
		toolTempers = {},
		-- Owned temperaments, keyed by kit id: { rarity = grade, n = copies }.
		tempers = {},
		petSockets = {},
		charms = {},
		equippedCharm = nil,
		vfx = {},
		equippedVfx = Vfx.blankEquip(),
		credits = 0,
		scrolls = { white = 0, black = 0, omni = 0 },
	}
end

local function reconcileCardSerials(plr, p)
	local kept, seen = {}, {}
	local removed = 0
	local repaired = 0
	local toNuke = {}
	for _, c in ipairs(p.cards or {}) do
		if type(c) == "table" then
			local serial = c.serial or c.id
			local okKeep = false
			if not isCardSerial(serial) then
				-- Missing / legacy id. Always keep the pet; ledger claim is best-effort.
				local newId
				for _ = 1, 12 do
					local candidate = makeSerial(c)
					local st = claimSerial(candidate, plr.UserId)
					if st == "won" or st == "error" then
						newId = candidate
						break
					end
				end
				-- Every attempt lost. Minting one more and moving on hands the player a
				-- serial the ledger says belongs to someone else, and the very next load
				-- reads it as a collision and nukes the card -- silently, a session later.
				-- Still keep the card, but say so, because losing one quietly is worse
				-- than losing one loudly.
				if not newId then
					newId = makeSerial(c)
					warn("[Mine] could not claim a serial for", plr.UserId,
						"- keeping the card on an unclaimed id:", newId)
				end
				serial = newId
				okKeep = true
				repaired += 1
			elseif seen[serial] then
				-- Duplicate inside same inventory.
				table.insert(toNuke, serial)
				removed += 1
			else
				local st = claimSerial(serial, plr.UserId)
				if st == "won" or st == "error" then
					-- Keep on datastore blip; only real collisions get nuked.
					okKeep = true
				else
					table.insert(toNuke, serial)
					removed += 1
				end
			end
			if okKeep then
				seen[serial] = true
				c.id = serial
				c.serial = serial
				c.speciesHex = string.sub(serial, 1, 3)
				table.insert(kept, c)
			end
		end
	end
	p.cards = kept
	local own = {}
	for _, c in ipairs(p.cards) do
		own[c.id] = true
		own[c.serial] = true
	end
	local eq = {}
	for _, id in ipairs(p.equipped or {}) do
		if own[id] then
			table.insert(eq, id)
		end
	end
	p.equipped = eq
	for _, serial in ipairs(toNuke) do
		nukeSerialEverywhere(serial, "reconcile-collision")
	end
	if repaired > 0 then
		warn("[Mine] repaired", repaired, "card ids for", plr.UserId)
	end
	if removed > 0 then
		warn("[Mine] stripped", removed, "dupe cards for", plr.UserId)
	end
end

local syncFoundLedger -- forward; assigned with collection ledger helpers

local function load(plr)
	--[[
		ONE CLEAN START FOR THE OWNER, AT LAUNCH, AND NEVER AGAIN.

		This used to delete the owner's save on their first join to EVERY
		server (a WipeUserOnce attribute saved into the place file), so in the
		published game their progress vanished whenever they changed servers.
		That is gone. What replaces it runs only in a published server, only for
		the owner, and only once ever: the old test save is copied to a backup
		key first, and the backup's existence is the marker that stops it from
		running again on any server. Nobody else is touched. Studio has its own
		stores now (MineConfig.DATASTORE_SUFFIX) and never gets here.
	]]
	--[[
		RESET_EPOCH IS HOW A SECOND CLEAN START IS AUTHORISED.

		Owner, 2026-10-08: "reset my save, i want to have nothing".

		The block below already does exactly that, correctly -- back the save up
		first, then remove it -- and already guarantees it happens at most once,
		because the backup key's existence is the marker that stops it. Which
		means it had already fired, and asking for a second reset had no way to
		say so.

		Bumping this number names a NEW backup key, so the marker for that key
		does not exist yet and the reset runs one more time. It still cannot run
		twice: the new backup is written before the save is removed, so the very
		next join sees the marker. Every previous epoch's backup is left intact,
		so nothing is ever actually lost -- epoch 1's save is still sitting under
		_prelaunch_backup.

		Raise it by one for each deliberate wipe. Never reuse a number.

		Studio is included from epoch 2 on. Studio runs against its own store
		(MineConfig.DATASTORE_SUFFIX) so the key is a different key there, and
		the same once-per-epoch marker applies -- the old `not IsStudio()` guard
		was there to stop a wipe on EVERY Studio run, which the marker now
		handles on its own.
	]]
	local RESET_EPOCH = 2
	if plr.UserId == 465369561 then
		local key = "u_" .. plr.UserId
		local backupKey = (RESET_EPOCH <= 1) and (key .. "_prelaunch_backup")
			or string.format("%s_reset_backup_%d", key, RESET_EPOCH)
		local okB, already = pcall(function()
			return store:GetAsync(backupKey)
		end)
		if okB and already == nil then
			local okG, old = pcall(function()
				return store:GetAsync(key)
			end)
			local okS = okG and pcall(function()
				store:SetAsync(backupKey, { savedAt = os.time(), data = old })
			end)
			if okS then
				pcall(function()
					store:RemoveAsync(key)
				end)
				warn(string.format("[Mine] reset epoch %d: owner's save backed up to %s and cleared", RESET_EPOCH, backupKey))
			end
		end
	end
	--[[
		READ THE SAVE AND CLAIM IT (session lock).

		Two things used to go wrong here.

		A failed read (a DataStore blip) fell through to a fresh starter profile
		that was NOT marked ephemeral, so the next autosave wrote that blank over
		the player's real save. Now the read retries, and if it still cannot be
		read the player is sent back to rejoin -- nothing is overwritten.

		And a player who left one server and joined another could be loaded
		there before the first server's final save landed, from the older copy:
		the classic dupe, trade something away and hop. Now loading CLAIMS the
		save with a lock (this server's JobId plus a time). A server that finds
		someone else's fresh lock waits for it to be released by that server's
		final save; a lock older than two minutes belongs to a dead server and is
		taken over. save() refuses to write once another server holds the lock,
		so a stale copy can never land over a newer one.
	]]
	local key = "u_" .. plr.UserId
	local lockTtl = Svc.Run:IsStudio() and 0 or 120
	local data, read = nil, false
	-- With API access off, all 8 lock-claim attempts are refused and each one logs
	-- StudioAccessToApisNotAllowed with backoff between -- the UpdateAsync lines
	-- scattered through the boot log. The existing Studio fallback below already
	-- handles the "cannot read" case, so skip straight to it rather than spending
	-- ~15s failing loudly first.
	-- LeaderboardService is the local from line 43, well above this function --
	-- checked, because a local declared BELOW its use site is a nil global to this
	-- closure and the guard would silently never fire. That trap has bitten this
	-- file four times (shortNum, invCtl, vipSeatsLeft, SET_IDS).
	local claimAttempts = 8
	if Svc.Run:IsStudio() and LeaderboardService.dataStoresUsable
		and not LeaderboardService.dataStoresUsable() then
		claimAttempts = 0
	end
	for attempt = 1, claimAttempts do
		local blocked, seen = false, nil
		local okU = pcall(function()
			store:UpdateAsync(key, function(old)
				seen, blocked = old, false
				local lk = (type(old) == "table") and old._lock or nil
				if lockTtl > 0 and type(lk) == "table" and lk.job ~= game.JobId
					and (os.time() - (tonumber(lk.t) or 0)) < lockTtl and attempt < 8 then
					blocked = true
					return nil
				end
				local new = (type(old) == "table") and old or {}
				new._lock = { job = game.JobId, t = os.time() }
				return new
			end)
		end)
		if okU and not blocked then
			data, read = seen, true
			break
		end
		task.wait(math.min(4, attempt))
	end
	if not read then
		-- Studio: UpdateAsync can fail on API blips / leftover locks. Fall back to
		-- GetAsync so we still play on the real save and keep writing.
		if Svc.Run:IsStudio() then
			local okG, got = pcall(function()
				return store:GetAsync(key)
			end)
			if okG then
				data, read = got, true
				warn("[Mine] Studio load: UpdateAsync claim failed; using GetAsync fallback")
			end
		end
	end
	if not read then
		if Svc.Run:IsStudio() then
			-- Studio without API access: play on a throwaway profile.
			error("datastore unavailable in Studio")
		end
		plr:Kick("Your save couldn't be loaded right now (a Roblox data hiccup). Nothing was lost -- please rejoin.")
		error("save unreadable for " .. plr.UserId)
	end
	local ok = true
	local p = blank()
	if ok and type(data) == "table" then
		for k, v in pairs(data) do p[k] = v end
		p._lock, p._releasing = nil, nil
	end
	p.equipped = p.equipped or {}
	p.cards = p.cards or {}
	-- Event Horizon rename: migrate owned pet card names to Matter± / Albert Minestein.
	local petAliases = (PetRoster and PetRoster.NAME_ALIASES) or {
		["Horizon+"] = "Matter+",
		["Horizon-"] = "Matter-",
		["Albert Horizontein"] = "Albert Minestein",
		["Albert Minestine"] = "Albert Minestein",
		["Matter(+)"] = "Matter+",
		["Matter(-)"] = "Matter-",
	}
	for _, c in ipairs(p.cards) do
		if type(c) == "table" and type(c.name) == "string" then
			local renamed = petAliases[c.name]
			if renamed then
				c.name = renamed
				if type(c.setName) == "string" and c.setName == "Big Bang" then
					c.setName = "Event Horizon"
				end
				if type(c.cardKey) == "string" then
					c.cardKey = (string.gsub(c.cardKey, "Horizon%+", "Matter+")
						:gsub("Horizon%-", "Matter-")
						:gsub("Matter%(%+%)", "Matter+")
						:gsub("Matter%(%-%)", "Matter-")
						:gsub("Albert Horizontein", "Albert Minestein")
						:gsub("Albert Minestine", "Albert Minestein"))
				end
			end
		end
	end
	p.packs = p.packs or {}
	p.packsOpened = p.packsOpened or {}
	p.backpack = p.backpack or {}
	-- Collection ledger: normalize keys + backdate bag chests into found.
	syncFoundLedger(p)
	p.deepest = p.deepest or {}
	-- Normalize deepest keys to strings (JSON datastore may leave either form).
	do
		local norm = {}
		for k, v in pairs(p.deepest) do
			local key = tostring(k)
			norm[key] = math.max(tonumber(norm[key]) or 0, tonumber(v) or 0)
		end
		p.deepest = norm
	end
	p.depthUnlock = p.depthUnlock or {}
	p._userId = plr.UserId
	p.coreSamples = p.coreSamples or {}
	p.coreRiftOpened = p.coreRiftOpened or {}
	p.bigbangOwned = p.bigbangOwned and true or false
	p.spaceCoins = math.max(0, math.floor(tonumber(p.spaceCoins) or 0))
	p.haulSpace = math.max(0, math.floor(tonumber(p.haulSpace) or 0))
	Dig.seedHaulMix(p)
	p.wormholeBag = p.wormholeBag and true or false
	for i, bp in ipairs(C.BACKPACKS or {}) do
		if bp.robux and (p.backpackTier or 1) >= i then
			p.foundersBag = true
			break
		end
	end
	if p.foundersBag and p.equippedBag == nil then
		p.equippedBag = "founders"
	end
	p.eventTools = p.eventTools or {}
	if p.bigbangOwned then
		p.wormholeBag = true
		p.eventTools.eh_shallow_pick = true
		p.eventToolId = p.eventToolId or "eh_shallow_pick"
	end
	do
		local oldEvent = {
			eh_shallow_drill = "eh_crimson_pick",
			eh_shallow_charge = "eh_basalt_bore",
			eh_mid_pick = "eh_basalt_bore",
			eh_mid_drill = "eh_gloomar_bore",
			eh_mid_charge = "eh_aether_charge",
			eh_deep_pick = "eh_aether_charge",
			eh_deep_drill = "eh_mythril_dirt_charge",
			eh_deep_charge = "eh_endsoil_charge",
		}
		for oldId, newId in pairs(oldEvent) do
			if p.eventTools[oldId] then
				p.eventTools[newId] = true
				p.eventTools[oldId] = nil
				if p.eventToolId == oldId then
					p.eventToolId = newId
				end
			end
		end
	end
	-- 1-based zone index; clamp so a stored 0 cannot break buyZone sequencing.
	p.maxUnlockedZone = math.max(1, tonumber(p.maxUnlockedZone) or 1)
	p.prestige = math.max(0, tonumber(p.prestige) or 0)
	p.petSlots = math.clamp(p.petSlots or 3, 3, C.MAX_PET_SLOTS)
	do
		--[[
			The pouch rung, clamped to what exists. Locks are rebuilt as a clean
			set: a DataStore round-trip turns the map's values into whatever JSON
			made of them, and a lock is a yes/no, so anything truthy is a yes.
		]]
		local Pouch = require(shared:WaitForChild("MineOrePouch"))
		p.orePouchTier = math.clamp(math.floor(tonumber(p.orePouchTier) or 1), 1, Pouch.MAX_TIER)
		local locks = {}
		for id, on in pairs(p.oreLocks or {}) do
			if on and C.oreById(tostring(id)) then
				locks[tostring(id)] = true
			end
		end
		p.oreLocks = locks
	end
	p.petSlotRobux = math.clamp(math.floor(tonumber(p.petSlotRobux) or 0), 0, 2)
	p.coinDouble = p.coinDouble and true or false
	p.autoMineLicense = p.autoMineLicense and true or false
	p.foundersBag = p.foundersBag and true or false
	p.potions = p.potions or {}
	p.coins = p.coins or 0
	--[[
		GRANDFATHERING THE DEPTH GATE.

		Nobody loses depth they already reached. grantReachedSeams derives the
		grant from p.deepest, which creditDeepest has been writing all along, so
		this needs no migration flag and no version stamp -- the evidence was
		already on the profile before the gate existed.

		It is add-only and therefore safe to run on every load: creditDeepest
		keeps pushing deepest down as they mine, and re-running must never take a
		seam away. It runs HERE, inside load and before the first canDigLayer,
		because a returning player whose first swing is at layer 900 would
		otherwise eat a refusal for a seam they earned months ago.
	]]
	p.seams = p.seams or {}
	if Dig.Depth.grantReachedSeams then
		Dig.Depth.grantReachedSeams(p)
	end
	p.runes = p.runes or {}
	p.gear = p.gear or {}
	p.equippedGear = p.equippedGear or { hat = nil, face = nil }
	if p.equippedGear.gloves ~= nil then
		p.equippedGear.face = p.equippedGear.face or p.equippedGear.gloves
		p.equippedGear.gloves = nil
	end
	--[[
		Gear became a hat and a face, and a hat became three seats that are all
		yours. Everything that is not one of those folds in here.

		This used to nil every slot that was not literally "hat" or "face",
		which meant it nil'd `hat2` -- the second seat never survived a rejoin.
		It walks Gear.HAT_SLOTS now, so the seat count can move again without
		the save quietly eating the new one.

		Nothing is deleted: the pieces themselves are re-priced to the hat sheet
		by Gear.normalize just below, sockets and all.
	]]
	do
		local eq = p.equippedGear
		local hatSlots = Gear.HAT_SLOTS or { "hat" }
		local live = { face = true }
		for _, slot in ipairs(hatSlots) do
			live[slot] = true
		end
		--[[
			Retired slots fold into free seats, head first -- that is the one
			that was already a hat, so it keeps the seat a player would expect.

			PET HATS FOLD IN THE SAME WAY. A pet wears nothing now, so a hat
			sitting on one has to land somewhere or it reads as lost. Free seats
			take as many as they hold; the rest go back to the bag, which is
			where they already were as far as the gear list is concerned -- only
			the "worn" marker changes.
		]]
		local orphans = {}
		if type(eq.head) == "string" then
			table.insert(orphans, eq.head)
		end
		for slot, id in pairs(eq) do
			if not live[slot] then
				if slot ~= "head" and type(id) == "string" then
					table.insert(orphans, id)
				end
				eq[slot] = nil
			end
		end
		for _, id in pairs(p.petHats or {}) do
			if type(id) == "string" and id ~= "" then
				table.insert(orphans, id)
			end
		end
		-- The field is gone, not emptied: a reader that still asks for it should
		-- come up nil rather than find a map that no longer governs anything.
		p.petHats = nil
		if #orphans > 0 then
			local taken = {}
			for _, slot in ipairs(hatSlots) do
				if type(eq[slot]) == "string" then
					taken[eq[slot]] = true
				end
			end
			for _, slot in ipairs(hatSlots) do
				if eq[slot] == nil then
					while #orphans > 0 do
						local id = table.remove(orphans, 1)
						if not taken[id] then
							eq[slot] = id
							taken[id] = true
							break
						end
					end
				end
			end
		end
	end
	for _, g in ipairs(p.gear or {}) do
		if type(g) == "table" and Gear.normalize then
			Gear.normalize(g)
			if g.adminForged or (type(g.id) == "string" and string.sub(g.id, 1, 4) == "adm_") then
				print(string.format(
					"###ADMIN ITEM### LOAD owner=%s(%d) id=%s creationId=%s asset=%s forgedBy=%s",
					plr.Name,
					plr.UserId,
					tostring(g.id),
					tostring(g.adminCreationId or "?"),
					tostring(g.adminRobloxAssetId or g.catalogId or "?"),
					tostring(g.adminForgedBy or "?")
				))
			end
		end
	end
	p.vfx = p.vfx or {}
	for _, row in ipairs(Vfx.CATALOG or {}) do
		if (row.priceCredits or 0) == 0 then
			p.vfx[row.id] = true
		end
	end
	p.equippedVfx = Vfx.normalize(p.equippedVfx)
	p.toolSockets = p.toolSockets or { pickaxe = nil, drill = nil, explosive = nil }
	if p.toolSockets.ranged ~= nil then
		-- Ranged tools/runes were cut; fold any leftover socket into pickaxe.
		if p.toolSockets.ranged and not p.toolSockets.pickaxe then
			p.toolSockets.pickaxe = p.toolSockets.ranged
		end
		p.toolSockets.ranged = nil
	end
	-- Migrate ranged runes so fuse/socket never target a dead family.
	for _, rune in ipairs(p.runes or {}) do
		if type(rune) == "table" and rune.kind == "ranged" then
			rune.kind = "pickaxe"
		end
	end
	p.petSockets = p.petSockets or {}
	--[[
		Temperaments are a COLLECTION now: you own them, and you choose which one
		each tool wears. Anything already rolled onto a family or a flagship is
		owned -- it was paid for in tokens, and taking it out of the collection
		because the storage shape changed would be a deletion.
	]]
	p.tempers = p.tempers or {}
	do
		local Temper = require(shared.MineTemper)
		local function own(id, rarity)
			if type(id) ~= "string" or id == "" or not Temper.kit(id) then
				return
			end
			local row = p.tempers[id]
			if row then
				row.rarity = Temper.betterGrade(row.rarity, rarity)
				row.n = math.max(1, tonumber(row.n) or 1)
			else
				p.tempers[id] = { rarity = Temper.normalizeRarity(rarity) or "F", n = 1 }
			end
		end
		local function harvest(holder)
			if type(holder) ~= "table" then
				return
			end
			own(holder.temperId, holder.temperRarity)
			for _, slot in ipairs(holder.tempers or {}) do
				if type(slot) == "table" then
					own(slot.id, slot.rarity)
				end
			end
		end
		for _, tt in pairs(p.toolTempers or {}) do
			harvest(tt)
		end
		for _, ct in ipairs(p.chestTools or {}) do
			harvest(ct)
		end
	end
	p.charms = p.charms or {}
	if type(p.equippedCharm) == "string" and p.equippedCharm ~= "" and not p.charms[p.equippedCharm] then
		p.equippedCharm = nil
	end
	-- Tiers arrived after these saves were written. normalize() labels each
	-- rune from the percentage it already has and leaves that percentage alone.
	p.runes = p.runes or {}
	for _, r in ipairs(p.runes) do
		Runes.normalize(r)
	end
	-- Gear grades became letters (F..SSS); saved pieces still carry the old
	-- words, and the stat sheet is keyed by grade, so this has to run before
	-- anything reads a piece.
	p.gear = p.gear or {}
	for _, piece in ipairs(p.gear) do
		Gear.normalize(piece)
	end
	-- fusePity is deliberately dropped, not migrated: the fuse is a flat
	-- independent chance now and there is no counter to carry forward.
	p.fusePity = nil
	p.credits = p.credits or 0
	-- Old saves predate the pass track. `battlePass` was the receipt stub the
	-- purchase used to write when there was nothing to grant; anyone carrying
	-- one paid for the pass and owns it.
	if p.intro == nil then
		local fresh = (p.coins or 0) == 0 and ((p.tools and p.tools.pickaxe) or 1) <= 1
			and #(p.cards or {}) == 0
		p.intro = fresh and 1 or 4
	end
	do
		local intro = math.floor(tonumber(p.intro) or 1)
		-- Finished the short tutorial before tips for runes/gear/temper/rebirth existed.
		-- Literals (not Intro.*) — this runs in load() before Intro is assigned later in the chunk.
		if intro == 5 then
			p.intro = 10
		end
	end
	-- v2 ladder (T1..T18). Old saves carry the 9-step numbering (done = 10);
	-- remap onto the new ladder so nobody repeats what they already did.
	-- Literals, same reason as above: Intro is assigned later in the chunk.
	if (math.floor(tonumber(p.introVer) or 1)) < 2 then
		local map = { 1, 2, 3, 4, 5, 12, 8, 16, 18, 19 }
		local old = math.clamp(math.floor(tonumber(p.intro) or 1), 1, 10)
		p.intro = map[old] or 1
		p.introVer = 2
	end
	-- v3: new tutorial steps are numbered 19 and up, so the v2 "finished" mark
	-- (19) moves to the new sentinel before it can be read as a step.
	if (math.floor(tonumber(p.introVer) or 1)) < 3 then
		if (math.floor(tonumber(p.intro) or 1)) >= 19 then
			p.intro = 99
		end
		p.introVer = 3
	end
	if (math.floor(tonumber(p.introVer) or 1)) < 4 then
		local intro = math.floor(tonumber(p.intro) or 1)
		local kept = {
			[1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true,
			[12] = true, [18] = true, [21] = true, [22] = true,
			[27] = true, [28] = true, [29] = true, [30] = true, [31] = true,
			[32] = true, [33] = true, [34] = true, [35] = true, [36] = true,
			[37] = true, [38] = true, [39] = true,
		}
		if intro >= 99 then
			-- already finished
		elseif intro == 1 or not kept[intro] then
			if (tonumber(p.prestige) or 0) > 0 or #(p.cards or {}) > 4 then
				p.intro = 21
			else
				p.intro = 27
			end
		end
		p.introVer = 4
	end
	-- Quest ladder v2 inserted rungs: move the saved index onto the same quest.
	if (math.floor(tonumber(p.questVer) or 1)) < 2 then
		if Quests.remapV1 then
			p.quest = Quests.remapV1(p.quest)
		end
		p.questVer = 2
	end
	-- The short-lived "tool mastery" bonus is gone; drop its ledger.
	p.toolMastery = nil
	-- Quest counters. Saves that predate quests have no history for blocks,
	-- sells, packs or merges, so those start at zero; the zone, card and
	-- rebirth quests read state that already existed and so are correct.
	p.quest = math.max(1, math.floor(tonumber(p.quest) or 1))
	p.questBase = p.questBase or {}
	p.stats = p.stats or {}
	p.stats.blocks = tonumber(p.stats.blocks) or 0
	p.stats.sells = tonumber(p.stats.sells) or 0
	p.stats.packs = tonumber(p.stats.packs) or 0
	p.stats.merges = tonumber(p.stats.merges) or 0
	if type(p.dailyQuests) ~= "table" then
		p.dailyQuests = { day = 0, list = {} }
	end
	if type(p.contracts) ~= "table" then
		p.contracts = { day = 0, list = {} }
	end
	p.milestones = p.milestones or {}
	p.daily = p.daily or { streak = 0, last = 0 }
	p.daily.streak = tonumber(p.daily.streak) or 0
	p.daily.last = tonumber(p.daily.last) or 0
	p.pass = p.pass or Scrolls.emptyPass()
	p.pass.free = p.pass.free or {}
	p.pass.prem = p.pass.prem or {}
	p.pass.xp = tonumber(p.pass.xp) or 0
	if p.battlePass and not p.pass.owned then
		p.pass.owned = true
	end
	Scrolls.reconcilePass(p.pass)
	p.scrolls = p.scrolls or Scrolls.emptyBag()
	p.scrolls.white = p.scrolls.white or 0
	p.scrolls.black = p.scrolls.black or 0
	p.scrolls.omni = p.scrolls.omni or 0
	-- One-shot: old 6-rung gem backpack ladder → 30-rung coin ladder by capacity.
	if not p.backpackCoinV2 then
		local OLD = { 80, 650, 5400, 44000, 370000, 3100000 }
		local had = OLD[math.clamp(tonumber(p.backpackTier) or 1, 1, #OLD)] or 80
		local best = 1
		for i, row in ipairs(C.BACKPACKS) do
			if (row.slots or 0) >= had then
				best = i
				break
			end
			best = i
		end
		if C.BACKPACKS[best] and C.BACKPACKS[best].robux then
			best = math.max(1, best - 1)
		end
		p.backpackTier = best
		p.backpackCoinV2 = true
	end
	if not p.backpackCatalogV3 then
		local oldSlots = nil
		pcall(function()
			local Bags = require(shared:WaitForChild("MineBags"))
			oldSlots = Bags.LEGACY_SLOTS
		end)
		local oldTier = math.clamp(tonumber(p.backpackTier) or 1, 1, (oldSlots and #oldSlots) or 112)
		local had = (oldSlots and oldSlots[oldTier]) or 480
		local best = 1
		for i, row in ipairs(C.BACKPACKS) do
			if (row.slots or 0) >= had then
				best = i
				break
			end
			best = i
		end
		if C.BACKPACKS[best] and C.BACKPACKS[best].robux and not p.foundersBag then
			best = math.max(1, best - 1)
		end
		p.backpackTier = best
		p.backpackCatalogV3 = true
	end
	p.backpackTier = math.clamp(tonumber(p.backpackTier) or 1, 1, #C.BACKPACKS)
	--[[
		Tools must exist before givePickaxe / snap -- a save with tools=nil left
		players with no tool and a dead HUD.

		Zero is a legitimate state now: the first pickaxe is collected from the
		Blacksmith. Only a profile that says it has not been collected may sit
		there. A save from before this existed carries no flag at all, and those
		players keep the pickaxe they have always had -- nobody logs in tomorrow
		to find their tool confiscated.
	]]
	if type(p.oreTools) ~= "table" then
		p.oreTools = {}
	end
	--[[
		Backfill the seen-set for saves that predate it. Anything banked right
		now was obviously discovered, so seed from the keys of p.ores; ore spent
		before this shipped is lost to us, but it comes back the next time one
		drops, and over-reporting here would be worse than under-reporting.
	]]
	if type(p.oresSeen) ~= "table" then
		p.oresSeen = {}
		for id, n in pairs(p.ores or {}) do
			if (tonumber(n) or 0) > 0 then
				p.oresSeen[tostring(id)] = true
			end
		end
	end
	if p.gotFirstPick == nil then
		p.gotFirstPick = true
	end
	--[[
		Ore roster swap: 33 ids were retired and every one of them is load
		bearing twice over. p.ores[id] is banked material, and every ore pack in
		the bag is "<id>_ore_pack" -- so dropping an id without a map does not
		just rename a rock, it deletes a player's stock and bricks their packs
		into rows that no longer resolve to anything.

		Runs once per profile and stamps oreRosterV so it never runs twice. The
		merge is additive: a save holding both the old id and its replacement
		keeps the sum rather than whichever the loop happened to reach last.

		LESS-THAN, NOT NOT-EQUAL. This read `~= 1`, which is only "has not run"
		while 1 is the newest version. The V2 pass below stamps 2, so every
		already-migrated profile came back here with oreRosterV == 2, failed
		`~= 1`, re-ran the whole V1 merge AND stamped itself back DOWN to 1 --
		which then made the V2 guard fire too. Both passes re-ran on every single
		load, forever, for every player past the migration.

		A version stamp is monotonic, so the test is "older than this pass", and
		a profile from a future build is left alone rather than downgraded.
	]]
	if (tonumber(p.oreRosterV) or 0) < 1 then
		local map = C.ORE_MIGRATION
		if type(map) == "table" then
			if type(p.ores) == "table" then
				for oldId, newId in pairs(map) do
					-- An id mapped to itself would add a pile to itself and then
					-- delete the lot. The generator refuses to emit one, and this
					-- refuses to act on one, because the failure is silent and
					-- total: the player just finds the ore gone.
					if oldId ~= newId then
						local held = tonumber(p.ores[oldId])
						if held and held > 0 then
							p.ores[newId] = (tonumber(p.ores[newId]) or 0) + held
						end
						p.ores[oldId] = nil
					end
				end
			end
			if type(p.packs) == "table" then
				-- ore packs resolve through MineZonePacks, not MinePackConfig:
				-- only the former has get(), so `Packs` here would silently
				-- leave every renamed pack showing its old name.
				local ZonePacks = require(shared:WaitForChild("MineZonePacks"))
				for _, pk in ipairs(p.packs) do
					local pid = pk and pk.packId
					if type(pid) == "string" then
						local baseId = pid:match("^(.*)_ore_pack$")
						local to = baseId and map[baseId]
						if to then
							pk.packId = to .. "_ore_pack"
							local def = ZonePacks.get and ZonePacks.get(pk.packId)
							pk.packName = (def and def.name) or pk.packName
						end
					end
				end
			end
		end
		p.oreRosterV = 1
	end
	--[[
		SECOND roster pass: 121 ores became 82, and 39 ids went away.

		Separate table and separate stamp from v1 on purpose. v1 still has to
		run for a save that has never seen it, so a save arrives here as v0, v1
		or v2 and walks forward: v0 -> 1 -> 2, v1 -> 2, v2 -> nothing. Editing
		v1 in place instead would have quietly skipped the rename step for
		every save that predates it.

		Three things move, and a fourth is repaired:
		  p.ores       amounts, summed where two old ids land on one new one
		  p.packs      "<old>_ore_pack" -> "<new>_ore_pack"
		  p.oreTools   tier is an INDEX into C.ORES, so it is re-pointed through
		               ORE_TIER_REMAP_V2 -- the uid is kept, because the uid is
		               what every button in the bench sends
		  level        clamped to the new cap, with the overspend refunded
	]]
	-- Monotonic, for the same reason as the V1 guard above: `~=` would re-run
	-- this pass on any profile stamped past it rather than only on older ones.
	if (tonumber(p.oreRosterV) or 0) < (C.ORE_ROSTER_V or 2) then
		local map = C.ORE_MIGRATION_V2
		local moved, packed, retiered, clamped = 0, 0, 0, 0
		if type(map) == "table" then
			if type(p.ores) == "table" then
				for oldId, newId in pairs(map) do
					if oldId ~= newId then
						local held = tonumber(p.ores[oldId])
						if held and held > 0 then
							p.ores[newId] = (tonumber(p.ores[newId]) or 0) + held
							moved += 1
						end
						p.ores[oldId] = nil
					end
				end
			end
			if type(p.packs) == "table" then
				local ZonePacks = require(shared:WaitForChild("MineZonePacks"))
				for _, pk in ipairs(p.packs) do
					local pid = pk and pk.packId
					if type(pid) == "string" then
						local baseId = pid:match("^(.*)_ore_pack$")
						local to = baseId and map[baseId]
						if to then
							pk.packId = to .. "_ore_pack"
							local def = ZonePacks.get and ZonePacks.get(pk.packId)
							pk.packName = (def and def.name) or pk.packName
							packed += 1
						end
					end
				end
			end
		end
		--[[
			Ore tools. A tool saved above the cap is set to the cap and meant to
			be handed back half of what the levels above it cost -- the same 50%
			the bench refunds on a recycle, so nobody can farm the migration by
			having over-levelled first.

			THE REFUND BELOW HAS NEVER PAID OUT. MineConfig.toolSpent runs its
			level through clampLevel, so toolSpent(t, savedLevel) is literally
			toolSpent(t, cap) once savedLevel is over the cap, and the difference
			is always zero. Dead since it was written, in every case it exists
			for.

			Left in place rather than deleted because it is gated on
			ORE_ROSTER_V and has already run for every live profile, so changing
			it now changes nothing for anyone -- but it must not be copied. The
			cap migration further down does the same job without pretending to
			pay, and says why: the cost curve is restretched by perLevel()
			whenever the cap moves, so what was actually spent is not
			recoverable from the save.

			The comment also said "the cap drops to 100". It is 30.
		]]
		local remap = C.ORE_TIER_REMAP_V2
		local cap = math.min(100, tonumber(C.TOOL_MAX_LEVEL) or 100)
		if type(p.oreTools) == "table" then
			for _, t in ipairs(p.oreTools) do
				if type(t) == "table" then
					local oldTier = tonumber(t.tier)
					if oldTier and type(remap) == "table" and remap[oldTier] then
						if remap[oldTier] ~= oldTier then
							retiered += 1
						end
						t.tier = remap[oldTier]
					end
					local lv = math.max(1, math.floor(tonumber(t.level) or 1))
					if lv > cap then
						if C.toolSpent then
							local oreWas, dustWas = C.toolSpent(t.tier, lv, t.typeMult)
							local oreNow, dustNow = C.toolSpent(t.tier, cap, t.typeMult)
							local oreBack = math.floor(math.max(0, (oreWas or 0) - (oreNow or 0)) * 0.5)
							local dustBack = math.floor(math.max(0, (dustWas or 0) - (dustNow or 0)) * 0.5)
							if oreBack > 0 then
								local ore = C.ORES[t.tier]
								if ore then
									p.ores = p.ores or {}
									p.ores[ore.id] = (tonumber(p.ores[ore.id]) or 0) + oreBack
								end
							end
							if dustBack > 0 then
								p.dust = (tonumber(p.dust) or 0) + dustBack
							end
						end
						lv = cap
						clamped += 1
					end
					t.level = lv
				end
			end
		end
		print(string.format(
			"[oreRosterV2] %s: %d ore piles merged, %d packs renamed, %d tools re-tiered, %d levels clamped",
			tostring(p.userId or p.name or "?"), moved, packed, retiered, clamped))
		p.oreRosterV = C.ORE_ROSTER_V or 2
	end

	--[[
		THE TOOL LEVEL CAP, ON ITS OWN VERSION STAMP.

		The roster migration above already clamps levels to the live cap and
		refunds half of what the excess cost -- but it is gated on
		`p.oreRosterV`, so it runs ONCE. Every profile that passed through it
		while the cap was 100 is stamped and will never re-enter it, and
		TOOL_MAX_LEVEL is 30 now. Those saves still hold tools stored at level
		80. `clampLevel` makes them BEHAVE as 30 wherever damage is computed, so
		nothing is broken, but the stored number is a lie, the bench shows a
		level the game will not honour, and the player is never handed back what
		the dead levels cost them.

		So the cap gets its own stamp rather than a bump of the roster's: the two
		move for different reasons and will move again at different times.
		Idempotent -- a second run finds nothing above the cap and does nothing.

		WHY CLAMP AND NOT RESCALE. Rescaling proportionally (level 80 of 100 ->
		24 of 30) keeps the player at the same FRACTION of the ladder and looks
		fairer, and it cannot be done safely: nothing in the save records which
		cap a level was earned under, so a stored 80 is "80 of 100" or "80 of
		1000" with no way to tell. Clamping needs no such knowledge.

		AND WHY NO REFUND, which is the part worth reading before adding one.
		The roster migration above tries to hand back half of what the dead
		levels cost, and that code has never paid out a single ore:
		MineConfig.toolSpent runs its level through clampLevel, so
		toolSpent(t, 80) IS toolSpent(t, cap) and the difference is always zero.
		Dead since it was written.

		It cannot be repaired by unclamping either, because the cost CURVE moved
		underneath it: TOOL_CLIMB_ORE and TOOL_CLIMB_DUST are restretched by
		perLevel() over the new cap, so the geometric series that priced level 80
		when it was bought no longer exists anywhere in the config. What a player
		actually spent is not reconstructible from the save.

		Clamping is its own compensation and that is the honest framing: on this
		curve the cap IS the full x350 climb, so a tool that comes back as level
		30 arrives MAXED. The player skips the whole ~12-hour climb rather than
		being paid off for it.
	]]
	do
		local capV = tonumber(C.TOOL_CAP_V) or 1
		if (tonumber(p.toolCapV) or 0) < capV and type(p.oreTools) == "table" then
			local cap = math.max(1, math.floor(tonumber(C.TOOL_MAX_LEVEL) or 30))
			local cut = 0
			for _, t in ipairs(p.oreTools) do
				if type(t) == "table" then
					local lv = math.max(1, math.floor(tonumber(t.level) or 1))
					if lv > cap then
						t.level = cap
						cut += 1
					end
				end
			end
			if cut > 0 then
				print(string.format(
					"[toolCapV%d] %s: %d tool level(s) clamped to %d (maxed on the current curve)",
					capV, tostring(p.userId or p.name or "?"), cut, cap))
			end
			p.toolCapV = capV
		end
	end
	if type(p.tools) ~= "table" then
		p.tools = { pickaxe = math.max(1, tonumber(p.pickaxeTier) or 1), drill = 0, explosive = 0 }
		p.gotFirstPick = true
	end
	if p.gotFirstPick then
		p.tools.pickaxe = math.max(1, tonumber(p.tools.pickaxe) or tonumber(p.pickaxeTier) or 1)
	else
		p.tools.pickaxe = math.max(0, tonumber(p.tools.pickaxe) or 0)
	end
	p.tools.drill = math.max(0, tonumber(p.tools.drill) or 0)
	p.tools.explosive = math.max(0, tonumber(p.tools.explosive) or 0)
	if p.toolEquipped == nil then
		p.toolEquipped = true
	end
	p.toolFamily = p.toolFamily or "pickaxe"
	if p.toolFamily == "ranged" then
		p.toolFamily = "pickaxe"
	end
	-- Twig Auger / Spark Charge inserted as new T1; bump owned drill/explosive rungs once.
	if not p._drillBombLadderV2 then
		p.tools = p.tools or {}
		p.toolTier = p.toolTier or {}
		for _, fam in ipairs({ "drill", "explosive" }) do
			local owned = tonumber(p.tools[fam]) or 0
			if owned >= 1 then
				p.tools[fam] = owned + 1
			end
			local eq = tonumber(p.toolTier[fam]) or 0
			if eq >= 1 then
				p.toolTier[fam] = eq + 1
			end
		end
		p._drillBombLadderV2 = true
	end
	for i, c in ipairs(p.cards) do
		if type(c) == "table" and not c.createdAt then
			c.createdAt = i
		end
	end
	--[[
		Cash out anything the retired fossil system left behind, once, and tell
		the player so the gems are not a mystery. Fires only when there was
		something to pay for, so a profile that never touched fossils is silent.
	]]
	do
		local paid = retireFossils(p)
		if paid > 0 then
			task.defer(function()
				if plr.Parent then
					net:FireClient(plr, "toast", string.format(
						"Fossils are retired -- your pieces and tools paid out %s gems",
						Verbs._benchNum(paid)))
				end
			end)
		end
	end
	--[[
		Convert legacy ore packs to banked ore, and say so -- the bag visibly
		changes, and a silent change to someone's inventory reads as a bug.
		Runs after the roster migrations above, which rename "<old>_ore_pack"
		to "<new>_ore_pack": before them the ids would not resolve.
	]]
	do
		local n, got = Dig.bankOrePacks(p)
		if n > 0 then
			task.defer(function()
				if plr.Parent then
					net:FireClient(plr, "toast", string.format(
						"Banked %d legacy ore pack%s -- %s ore went into your pouch",
						n, n == 1 and "" or "s", Verbs._benchNum(got)))
				end
			end)
		end
	end
	reconcileChestTools(p)
	profiles[plr.UserId] = p
	LeaderboardService.recordRoster(plr.UserId)
	LeaderboardService.queueUpdate(plr.UserId, p.prestige, p.gems, LeaderboardService.profileStardustValue(p))
	-- Cache VIP gamepass + Founders ownership on join (pcall + table); never trust the client.
	task.spawn(function()
		pcall(refreshVipPass, plr)
		pcall(function()
			local Founders = require(shared.MineFounders)
			if Founders.isMember(p) then return end
			local ok, owns = pcall(function()
				return Svc.Marketplace:UserOwnsGamePassAsync(plr.UserId, Founders.gamePassId(C))
			end)
			if ok and owns then
				local seatsRef = { left = vipSeatsLeft }
				if Founders.grant(p, plr, "gamepass", {
					seatsRef = seatsRef,
					grantScrolls = grantScrolls,
					toast = function(plr2, msg) net:FireClient(plr2, "toast", msg) end,
				}) then
					vipSeatsLeft = seatsRef.left or vipSeatsLeft
					markDirty(plr)
				end
			end
		end)
		if profiles[plr.UserId] == p and plr.Parent then
			pcall(snap, plr)
		end
	end)
	-- Serial ledger claims used to run inline and stall join on DataStore queue
	-- (no pickaxe, no snapshot → blank wallet). Repair in the background.
	task.spawn(function()
		local ok, err = pcall(reconcileCardSerials, plr, p)
		if not ok then
			warn("[Mine] reconcile failed", err)
		end
		if profiles[plr.UserId] == p then
			pcall(snap, plr)
		end
	end)
	return p
end

--[[
	Save one player. Retries twice, and says so when it fails.

	This used to be a single SetAsync inside a bare pcall: a DataStore hiccup
	lost the save with no retry and no warning, so the first anyone knew was a
	player logging back in to an older copy of themselves. Returns true only
	once the write has actually landed.
]]
local function save(plr)
	local p = profiles[plr.UserId]
	if not p then
		return false
	end
	if p._ephemeral then
		warn(string.format("[Mine] save skipped for %d: ephemeral profile (load never claimed a real save)", plr.UserId))
		return false
	end
	-- A final save (leaving, shutdown) hands the lock back so the next server
	-- can load this player straight away instead of waiting for it to expire.
	local final = p._releasing and true or false
	local lockTtl = Svc.Run:IsStudio() and 0 or 120
	for attempt = 1, 3 do
		local lost = false
		local ok, err = pcall(function()
			store:UpdateAsync("u_" .. plr.UserId, function(old)
				local lk = (type(old) == "table") and old._lock or nil
				if lockTtl > 0 and type(lk) == "table" and lk.job ~= game.JobId and (os.time() - (tonumber(lk.t) or 0)) < lockTtl then
					-- Another server has this player now and its copy is newer.
					-- Writing ours would roll them back (or dupe what they traded).
					lost = true
					return nil
				end
				p._releasing = nil
				p._ephemeral = nil
				p._lock = (not final) and { job = game.JobId, t = os.time() } or nil
				return p
			end)
		end)
		if ok and lost then
			warn(string.format("[Mine] save skipped for %d: another server holds their session", plr.UserId))
			return false
		end
		if ok then
			-- queueUpdate records the roster itself; calling both here doubled
			-- the roster write on every autosave.
			LeaderboardService.queueUpdate(plr.UserId, p.prestige, p.gems, LeaderboardService.profileStardustValue(p))
			return true
		end
		warn(string.format("[Mine] save failed for %d (attempt %d of 3): %s", plr.UserId, attempt, tostring(err)))
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	return false
end

local function cardById(p, id)
	if id == nil then
		return nil
	end
	for _, c in ipairs(p.cards) do
		if c.id == id or c.serial == id then
			return c
		end
	end
end

-- The active preset, and the skill points still free to spend in it.
local function skillState(p)
	p.skillPresets = p.skillPresets or { { levels = {}, spent = 0 } }
	p.skillSlot = p.skillSlot or 1
	local slot = p.skillPresets[p.skillSlot]
	if not slot then
		slot = { levels = {}, spent = 0 }
		p.skillPresets[p.skillSlot] = slot
	end
	slot.levels = slot.levels or {}
	slot.spent = slot.spent or 0
	--[[
		What buying the second preset charged THIS preset. That purchase is not
		a node, so a reset must not refund it -- otherwise buy the slot, reset,
		and you have the slot and your 25 points back.

		Saves from before it was recorded can only have paid from preset 1: the
		second slot does not exist to be standing on until it has been bought.
	]]
	local charge = slot.slotCharge
	if charge == nil then
		charge = (p.skillSlot == 1 and p.boughtSecond) and Skills.PRESETS.secondSlotCost or 0
	end
	return {
		levels = slot.levels,
		-- Sacrificed points are gone from every preset, so they come off the
		-- lifetime total before any preset's spending does.
		-- `skillBought` are points paid for with tokens rather than granted by a
		-- rebirth (Verbs.skillBuyBack). They spend exactly like earned ones.
		tokens = (p.skillEarned or 0) + (p.skillBought or 0) - (p.skillBurned or 0) - slot.spent,
		-- Exactly what a reset hands back. Read from `spent`, not recomputed
		-- from levels: node prices inflate with breadth, so the levels alone
		-- cannot say what was actually paid.
		refund = math.max(0, slot.spent - charge),
		charge = charge,
	}, slot
end

-- What the player is actually swinging. Everything reads through here so
-- there is exactly one definition of "your tool".
local function foreverPowerCap(p)
	--[[
		Forever tools (chest / fossil / event / pass) may not outrun the dig curve.
		cap = 50^(zone^0.5) * 1.20^rebirths
		Zone 1 = 50; softer zone curve via sqrt exponent; each rebirth +20% compound.
	]]
	local zi = math.max(1, math.floor(tonumber(p and p.maxUnlockedZone) or 1))
	local rebirths = math.max(0, math.floor(tonumber(p and p.stats and p.stats.rebirth) or 0))
	local BASE = 50
	local cap = (BASE ^ (zi ^ 0.5)) * (1.20 ^ math.min(rebirths, 64))
	if cap ~= cap or cap > 1e18 then
		return 1e18
	end
	return cap
end

local function clampForeverTool(p, tool)
	if type(tool) ~= "table" then
		return tool
	end
	local cap = foreverPowerCap(p)
	local pow = tonumber(tool.power) or 0
	if pow <= cap then
		return tool
	end
	local t = table.clone(tool)
	t.power = math.max(1, math.floor(cap))
	t.powerCapped = true
	t.powerCap = cap
	return t
end

local function foreverToolZoneOk(p, def)
	if type(def) ~= "table" or not def.zoneId then
		return true
	end
	local unlocked = math.max(1, math.floor(tonumber(p and p.maxUnlockedZone) or 1))
	for i, z in ipairs(C.ZONES or {}) do
		if z.id == def.zoneId then
			return i <= unlocked
		end
	end
	return true
end

local function equippedTool(p)
	-- Migrate saves that predate the 70-tool table.
	if not p.tools then
		p.tools = { pickaxe = math.max(1, p.pickaxeTier or 1), drill = 0, explosive = 0 }
	end
	-- Event Horizon swings an event tool. Meadow picks do nothing there.
	if p.zoneId == "bigbang" then
		local eid = p.eventToolId or "eh_shallow_pick"
		local okH, Horizon = pcall(function()
			return require(shared:WaitForChild("MineHorizonTools"))
		end)
		local et = okH and Horizon and Horizon.byId(eid)
		if et and p.eventTools and p.eventTools[eid] then
			return et, et.family or "pickaxe", et.tier or 1
		end
	end
	--[[
		AN EQUIPPED ORE TOOL OUTRANKS THE LADDER.

		Ore tools are found, not bought. Like a chest flagship they are a
		separate object rather than a rung, so holding one replaces whatever
		pickaxe tier the player has climbed to.

		The row is synthesised, not stored. Its `name` is the ORE's name, which
		is exactly what ToolModels_50 keys the baked head on, so the model
		resolves through the existing fromNamed path off the same string the
		bench prints -- no second lookup table to drift.

		A missing uid clears the equip instead of erroring: scrapping the tool
		in your hand must not leave you swinging a ghost.

		The lookup is inline because Verbs is declared some six thousand lines
		below this function, so Verbs._findOreTool is not in scope here.
	]]
	if p.oreToolEquipped then
		local held
		for _, t in ipairs(p.oreTools or {}) do
			if type(t) == "table" and t.uid == p.oreToolEquipped then
				held = t
				break
			end
		end
		if not held then
			p.oreToolEquipped = nil
		else
			local famId = held.familyId or "pickaxe"
			local oreDef = C.ORES and C.ORES[tonumber(held.tier) or 1]
			-- Same rarity rank the bench prices against, so what you paid for
			-- and what you swing agree.
			local typeMult = 1
			local famList = Tools.TOOLS and Tools.TOOLS[famId]
			if famList then
				for _, td in ipairs(famList) do
					if td.id == held.typeId then
						local rr = Tools.normalizeToolRarity and Tools.normalizeToolRarity(td.rarity)
						typeMult = (Tools.RARITY_RANK and Tools.RARITY_RANK[rr or td.rarity]) or 1
						break
					end
				end
			end
			local lvl = math.max(1, tonumber(held.level) or 1)
			local power = 1
			if C.toolPower then
				power = math.max(1, math.floor(C.toolPower(held.tier, lvl, typeMult)))
			end
			--[[
				FINISHES RIDE AN ORE TOOL THE SAME WAY THEY RIDE A FLAGSHIP.

				Same two multipliers a chest tool gets, and the same route to
				the screen: givePickaxe reads row.shiny / row.shadow without
				caring what kind of tool the row describes, so setting them
				here is the whole of it -- ToolModelFactory.applyFinish puts the
				mirror and sparks, or the near-black body and red fire, on the
				model it already built.

				Shadow wins over shiny rather than stacking, matching withShiny
				above. A finish never changes what a level COSTS, only what the
				tool hits for, so the bench prices a shadow tool exactly like a
				plain one and recycle still returns a flat cut of what went in.
			]]
			local shiny = held.shiny and true or nil
			local shadow = held.shadow and true or nil
			local nightmare = held.nightmare and true or nil
			-- Highest finish wins outright; they never stack, same as withShiny.
			if nightmare then
				power = math.max(1, math.floor(power * (C.NIGHTMARE_MULT or 4.5)))
			elseif shadow then
				power = math.max(1, math.floor(power * (C.SHADOW_MULT or 3)))
			elseif shiny then
				power = math.max(1, math.floor(power * (C.SHINY_MULT or 1.5)))
			end
			local finish = (nightmare and "Nightmare") or (shadow and "Shadow")
				or (shiny and "Shiny") or "Normal"
			--[[
				THE ROW MUST CARRY ITS ORE, OR THE BREAKING GATE READS IT AS 1.

				MineBreaking.toolBreakingPower tries three things in order: a
				stamped `breakingPower`, then `oreId`/`ore` (derive from the ore),
				then a shop rung off `rung`/`id`. This row had NONE of them --
				no stamped power, no ore id, no `tier`, and an `id` of
				"oretool_<uid>" that tonumber cannot parse -- so every forged
				tool in the game fell through to SHOP_POWER[1], which is 1.

				Breaking power 1 is the weakest pick in the game. With ZONE_STEP
				at 100 that walls a player a few hundred layers into zone 1 no
				matter what they forged, so the entire ore ladder was unusable
				the moment the gate started being enforced. Nothing said so: a
				blocked swing is silent by design, it just does no damage.

				oreTier and oreId are set here rather than stamped at craft time
				because the row is synthesised per swing from the stored one --
				deriving keeps a tool honest if the roster moves, and needs no
				migration for the tools players already hold.
			]]
			return {
				id = "oretool_" .. tostring(held.uid),
				uid = held.uid,
				name = (oreDef and oreDef.name) or "Ore Tool",
				modelName = (oreDef and oreDef.name) or nil,
				family = famId,
				oreTier = tonumber(held.tier) or 1,
				oreId = (oreDef and oreDef.id) or nil,
				power = power,
				level = lvl,
				oreTool = true,
				shiny = shiny,
				shadow = shadow,
				nightmare = nightmare,
				finish = finish,
			}, famId, 0
		end
	end

	-- A chest flagship overrides the ladder entirely: it is not a rung, it is a
	-- separate object you found. Held only while the player has it selected.
	local function withShiny(def, owned)
		if not def then
			return nil
		end
		local shiny = owned and owned.shiny
		local shadow = owned and owned.shadow
		local nightmare = owned and owned.nightmare
		local ownedPower = owned and tonumber(owned.power)
		local ownedSlots = owned and tonumber(owned.slots)
		if not shiny and not shadow and not nightmare and not ownedPower and not ownedSlots then
			return def, def.family or "pickaxe", 0
		end
		local t = table.clone(def)
		if ownedPower then
			t.power = ownedPower
		end
		if ownedSlots then
			t.slots = ownedSlots
		end
		-- Shadow is the rarer finish and hits harder than shiny; neither stacks.
		if nightmare then
			t.nightmare = true
			t.power = math.max(1, math.floor((t.power or 1) * (C.NIGHTMARE_MULT or 4.5)))
		elseif shadow then
			t.shadow = true
			t.power = math.max(1, math.floor((t.power or 1) * (C.SHADOW_MULT or 2)))
		elseif shiny then
			t.shiny = true
			t.power = math.max(1, math.floor((t.power or 1) * (C.SHINY_MULT or 1.5)))
		end
		return t, t.family or def.family or "pickaxe", 0
	end
	--[[
		An equipped ore tool overrides the ladder, exactly as a chest flagship
		does. It is not a rung you bought, it is an object you forged.

		The row carries the ORE tier, and that tier is the tool's breaking power
		(docs/TODO.md section 0.1). It is returned on the def as `oreTier` so
		givePickaxe can stamp it on the Tool instance -- the swing gate reads it
		from there. It deliberately does NOT ride the third return value, which
		is `lookTier`, a cosmetic ladder rung clamped to the shop family's
		length; conflating the two is how breaking power would silently become
		a shop number.

		typeMult is resolved inline rather than through Verbs._oreToolTypeMult,
		because `local Verbs` is declared thousands of lines below this point.
	]]
	if p.oreToolEquipped then
		local oreRow
		for _, row in ipairs(p.oreTools or {}) do
			if type(row) == "table" and row.uid == p.oreToolEquipped then
				oreRow = row
				break
			end
		end
		if oreRow then
			--[[
				THE STATS COME FROM THE ORE, NOT FROM A FRAME.

				This walked Tools.TOOLS for the row's typeId and took `rate`,
				`radius`, `cells` and `shape` off whatever frame it found. That
				roster is gone, so the stats are read from MineOreTools instead,
				where they are baked per family per ore tier -- the same values,
				verified 2,460 for 2,460 against the roster before it was removed.

				Without this the fallbacks below would have taken over and every
				forged DRILL and EXPLOSIVE would quietly become a one-cell melee
				pickaxe: no area clear, no blast, and nothing to error on.

				The name is the family's noun now. It used to be the FRAME's
				name, so a forged tool read "Stone Chipped Crown" -- an ore and
				an invented frame title, which is the exact confusion
				MineOreTools was written to end.
			]]
			local famId = oreRow.familyId or "pickaxe"
			local OreToolsM = require(shared:WaitForChild("MineOreTools"))
			local stats = OreToolsM.frameStats(famId, oreRow.tier)
			local typeMult = OreToolsM.typeMult(famId, oreRow.tier)
			local oreDef = C.ORES and C.ORES[tonumber(oreRow.tier) or 1]
			local level = math.max(1, tonumber(oreRow.level) or 1)
			local def = {
				id = "oretool_" .. tostring(oreRow.uid),
				name = string.format("%s %s",
					(oreDef and oreDef.name) or ("Tier " .. tostring(oreRow.tier)),
					OreToolsM.familyNoun(famId)),
				family = famId,
				power = math.max(1, math.floor(C.toolPower(oreRow.tier, level, typeMult))),
				rate = stats.rate or 2.6,
				radius = stats.radius or 0,
				cells = stats.cells or 1,
				shape = stats.shape or "melee",
				-- Carried through for the families that use them. A drill needs
				-- its width and axis to clear more than one block; an explosive
				-- needs its bomb count, pattern and cooldown to be a bomb.
				width = stats.width,
				axis = stats.axis,
				turn = stats.turn,
				bombs = stats.bombs,
				pattern = stats.pattern,
				cooldown = stats.cooldown,
				oreTier = math.max(1, math.floor(tonumber(oreRow.tier) or 1)),
				oreToolEquipped = oreRow.uid,
				level = level,
			}
			return def, famId, 0
		end
		-- Scrapped or never existed: stop pointing at it.
		p.oreToolEquipped = nil
	end
	if p.chestTool then
		-- Pass tools (lunar_pick / bp_eclipse / lunar_eclipse) live in chestTools
		-- but are defined on PASS_TOOLS, not CHEST_TOOLS — resolve both.
		local ct = Tools.passTool(p.chestTool) or Tools.chestTool(p.chestTool)
		if ct and ct.family == "backpack" then
			p.chestBag = p.chestTool
			p.chestTool = nil
			ct = nil
		end
		if ct then
			local owned
			for _, row in ipairs(p.chestTools or {}) do
				if type(row) == "table" and row.id == p.chestTool then
					owned = row
					break
				end
			end
			local t, fam, rung = withShiny(ct, owned)
			-- Battle Pass tools are Meadow-strength by definition (power 5-16).
			-- They keep their place as the player moves on: scaled by the same
			-- x6 a zone the rock's HP climbs by, from the deepest zone owned.
			local z = math.max(1, math.floor(tonumber(p.maxUnlockedZone) or 1))
			if t and z > 1 and Tools.passTool(p.chestTool) then
				t = table.clone(t)
				t.power = math.max(1, math.floor((t.power or 1) * 6 ^ (z - 1)))
			end
			return clampForeverTool(p, t), fam, rung
		end
		p.chestTool = nil
	end
	if p.shopToolId and type(p.shopToolId) == "string" then
		p.ownedShopTools = p.ownedShopTools or {}
		if p.ownedShopTools[p.shopToolId] then
			local okL, Ladders = pcall(function()
				return require(shared:WaitForChild("MineShopLadders"))
			end)
			local row = okL and Ladders and Ladders.byId(p.shopToolId)
			if row then
				return row, row.family or "pickaxe", row.slot or 1
			end
		end
		p.shopToolId = nil
	end
	-- Ranged was removed; anyone still pointed at it falls back to a pickaxe.
	local fam = p.toolFamily or "pickaxe"
	if fam == "ranged" then
		fam = "pickaxe"
		p.toolFamily = fam
	end
	local list = Tools.TOOLS[fam]
	-- p.tools[fam] is the highest rung you OWN. p.toolTier[fam] is the one you
	-- are actually holding. They used to be the same number, which is why an
	-- older pick could never be equipped again once you bought past it.
	local owned = p.tools[fam] or 0
	local tier = owned
	if p.toolTier and p.toolTier[fam] then
		tier = math.clamp(p.toolTier[fam], 1, math.max(owned, 1))
	end
	if not list or #list == 0 or owned <= 0 then
		-- This fallback is what made the old Blacksmith errand impossible: the
		-- game handed you the pickaxe it was asking you to go and fetch.
		if p.gotFirstPick == false and (tonumber(p.tools.pickaxe) or 0) <= 0 then
			return C.BARE_HANDS, "pickaxe", 0
		end
		fam = "pickaxe"
		list = Tools.TOOLS.pickaxe
		tier = math.max(1, p.tools.pickaxe or 1)
		p.toolFamily = fam
	end
	tier = math.clamp(tier, 1, #list)
	return list[tier], fam, tier
end

--[[
	PETS, DRESSED.

	One pet at a time into its own table, so what that pet gives can be
	MULTIPLIED by the things that are meant to multiply it -- its rune, its own
	hat, and your hat -- before it joins the team total, which your face then
	multiplies whole.

	Summing every pet into one shared table first (what this used to do) makes
	that impossible: once three pets are added together there is no longer a
	"this pet's share" for a hat to lift.

	The order itself lives in MineGear.stackPets, so the gear screen and the
	server read it from the same place. Returns the stat the face tailored
	itself to, for the UI.
]]
-- Weak keys: this is a per-tick read-out for the UI, and it must never become
-- a field on the profile, because save() writes the profile table whole.
Dig.tailor = setmetatable({}, { __mode = "k" })

function Dig.petRows(p, n)
	local pieces, runes = {}, {}
	for _, g in ipairs(p.gear or {}) do
		if type(g) == "table" and g.id then
			pieces[g.id] = g
		end
	end
	for _, r in ipairs(p.runes or {}) do
		if type(r) == "table" and r.id then
			runes[r.id] = r
		end
	end
	local zero = Cards.emptyBoosts()
	local rows = {}
	for _, id in ipairs(p.equipped or {}) do
		local c = cardById(p, id)
		if c then
			local one = Cards.emptyBoosts()
			Cards.applyKit(one, c, C.cardPower(c), n)
			-- What the pet ADDS. A multiplier stat sits at 1 when it gives
			-- nothing, and scaling 1 would be inventing power out of nothing.
			local delta = {}
			for k, v in pairs(one) do
				if type(v) == "number" then
					local floorV = zero[k]
					if floorV == nil then
						floorV = (k == "swingRate") and 1 or 0
					end
					if v ~= floorV then
						delta[k] = v - floorV
					end
				end
			end
			table.insert(rows, {
				delta = delta,
				name = tostring(c.name or "Pet"),
				cardId = id,
				-- No `hat`: a pet wears none. Your three seats apply to all of
				-- them at once, and stackPets reads them from `eq`.
				rune = runes[(p.petSockets or {})[id] or ""],
			})
		end
	end
	return rows, pieces, runes
end

--[[
	LAYER 2: equipment and pets, summed flat.

	Owner, 2026-10-04: "Gear powers pets. Should just be a boost." and
	"equipment+pets are #2".

	Used to mutate the boost table directly, and gear used to be counted once
	PER PET and then multiplied by your face -- so a fourth pet made your hat
	33% better without the hat changing. Now both just add, once, into a layer
	that MineBoostLayers multiplies over layer 1.

	Returns the layer table and the stat the face tailored itself to.
]]
function Dig.layer2(p, n)
	local rows, pieces = Dig.petRows(p, n)
	local eq = p.equippedGear or {}
	local t2 = {}
	for stat, amount in pairs(Gear.stackPets(rows)) do
		Dig.Layers.add(t2, stat, amount)
	end
	local gear, tailor = Gear.flatBoost(Gear.wornHats(eq, pieces), pieces[eq.face or ""])
	for stat, amount in pairs(gear) do
		Dig.Layers.add(t2, stat, amount)
	end
	return t2, tailor
end

local function boosts(p)
	local b = Cards.emptyBoosts()
	local n = #(p.equipped or {})
	--[[
		THE TWO LAYERS. Owner, 2026-10-04:

		  "skills+skins+tools+traits are the very bottom ... equipment+
		   pets are #2 [if skin has +50% damage, and pet says +100% damage, and
		   the tools base is 100, then it turns to 300, rather than 250]"

		Everything inside a layer adds; the layers multiply. Collected here and
		combined once, below, after every source has had its say -- combining
		early would make the result depend on the order sources were read in.
	]]
	local T1, T2 = {}, {}
	T2, Dig.tailor[p] = Dig.layer2(p, n)
	b.luck *= C.prestigeLuck(p.prestige)
	if (tonumber(p.sellHasteUntil) or 0) > os.clock() then
		b.mineSpeed *= 1.08
	end
	if type(p.vip) == "table" and p.vip.since then
		b.luck *= 1.05
	end
	do
		local ev = C.EVENTS and C.EVENTS[1]
		local zoneId = ev and (ev.zoneId or "bigbang") or "bigbang"
		if ev and p.zoneId == zoneId and C.limitedActive and C.limitedActive() then
			local ep = EventPass.ensure(p, ev.id)
			local bonus = EventPass.activeBonus(ev.id, ep.xp)
			if bonus.luck then b.luck *= bonus.luck end
			if bonus.sell then b.sell = (b.sell or 1) * bonus.sell end
			if bonus.gems then b.gems = (b.gems or 1) * bonus.gems end
			if bonus.ore then b.blastChance = (b.blastChance or 0) + (bonus.ore - 1) end
		end
	end
	--[[
		THE EQUIPPED TOOL'S ENCHANTMENT.

		One trait, on the tool you are holding, and nothing else: no
		slots, no per-family sockets, no three hats and a face. A tool that is
		not in your hands gives nothing, which is what makes the prefix on the
		one you ARE holding mean something.

		Folded through MineCards.ADDITIVE_STATS rather than a second opinion
		about which stats add and which multiply -- the two drifting apart
		would quietly pay a chance stat as a multiplier.
	]]
	do
		local uid = p.oreToolEquipped
		if uid then
			for _, t in ipairs(p.oreTools or {}) do
				if t.uid == uid then
					if type(t.trait) == "table" then
						-- Layer 1: the tool's own trait, beside skills
						-- and skins rather than on top of them.
						local def = Dig.Traits.byId(t.trait.id)
						if def then
							Dig.Layers.add(T1, def.stat,
								Dig.Traits.amount(t.trait.id, t.trait.level))
						end
					end
					break
				end
			end
		end
	end

	-- prestigeYield used to dump +15% Blast per rebirth. Blast is Omni now; prestige
	-- does not ride it. Luck still scales with rebirth.

	-- Rebirth skills. MineStats amounts are fractions (0.62 = +62%); the boost
	-- table is multiplicative for everything except echo/zap/blastRadius/autoMine/
	-- blastChance (Blast %), which are additive.
	local sk = Skills.totalStats(skillState(p), Stats)
	for stat, key in pairs({ mineSpeed = "mineSpeed", dirtBreak = "dirtBreak",
		walkSpeed = "walkSpeed", luck = "luck", rareOre = "rareOre" }) do
		if sk[stat] then
			-- Layer 1. Rebirth skills are the floor the rest is built on.
			Dig.Layers.add(T1, key, sk[stat])
		end
	end

	--[[
		COMBINE. base x (1 + layer1) x (1 + layer2), once, for every stat
		either layer touched.

		Chance stats are handed through untouched -- MineCards.ADDITIVE_STATS
		is the list -- because "1 + x" on a blast chance is meaningless and two
		layers of it is twice as meaningless.
	]]
	Dig.Layers.apply(b, T1, T2, Cards.ADDITIVE_STATS)
	Cards.foldSwingRate(b)

	-- Swing seconds are a DURATION, so a faster swing rate divides it.
	if sk.swingRate then
		b.swingSec /= (1 + sk.swingRate)
	end
	--[[
		BLAST RADIUS FROM SKILLS. This line did not exist.

		Nine nodes in MineSkillData grant blastRadius and it is FIRE'S PRIMARY
		STAT -- the headline buff of the first wedge on the tree, deg 0. The
		server read sk.mineSpeed, sk.dirtBreak, sk.walkSpeed, sk.luck,
		sk.rareOre, sk.swingRate, sk.echo, sk.zap, sk.blastChance, sk.luckyFind,
		sk.fossilFind, sk.pulverize, sk.scrap, sk.backpack, sk.chestLuck,
		sk.coinBonus and sk.gemFind -- and never sk.blastRadius. So every point
		a player put into the Fire road's primary stat was silently discarded.

		Additive, like the other procs: MineCards.ADDITIVE_STATS lists it.
	]]
	if sk.blastRadius then
		b.blastRadius += sk.blastRadius
	end
	--[[
		THE REST OF THE TREE'S STATS, for exactly the same reason.

		blastRadius was not alone -- it was just the one whose element was most
		obviously broken. Once the 2026-10-04 remap put earthquake, ricochet,
		procPower, oreLuck, packLuck, coolant, reach and shortFuse on elements,
		every one of them was granted by nodes and read by nobody.

		tools/verify/skilltree.js now fails if the tree grants a stat the server
		does not apply, so this list cannot fall behind the roster again.

		Additive ones are chances or flat adds; oreLuck and packLuck are
		MULTIPLIERS and sit at 1 when they give nothing.
	]]
	for _, key in ipairs({ "earthquake", "ricochet", "procPower",
		"coolant", "shortFuse", "reach" }) do
		if sk[key] then
			b[key] = (tonumber(b[key]) or 0) + sk[key]
		end
	end
	for _, key in ipairs({ "oreLuck", "packLuck" }) do
		if sk[key] then
			b[key] = (tonumber(b[key]) or 1) * (1 + sk[key])
		end
	end
	if sk.echo then
		b.echo += sk.echo
	end
	if sk.zap then
		b.zap += sk.zap
	end
	if sk.blastChance then
		b.blastChance += sk.blastChance
	end
	if sk.luckyFind then
		b.luckyFind += sk.luckyFind
	end
	if sk.fossilFind then
		b.fossilFind += sk.fossilFind
	end
	if sk.pulverize then
		b.pulverize += sk.pulverize
	end
	if sk.scrap then
		b.scrap += sk.scrap
	end
	-- Skills stack after pets. No haul-multiplier clamp.
	if sk.backpack then
		b.backpack *= (1 + sk.backpack)
	end
	-- These five now start life in Cards.emptyBoosts, so the tree COMPOUNDS with
	-- whatever the pets gave. Assigning here is what made a pet's Coin Bonus,
	-- Gem Find and Chest Luck do nothing at all.
	b.coinBonus *= (1 + (sk.coinBonus or 0))
	b.gemFind *= (1 + (sk.gemFind or 0))
	b.chestLuck *= (1 + (sk.chestLuck or 0))
	-- Blast radius is a rune, not a tree or pet.
	b.autoMine += (sk.autoMine or 0)

	-- Relics and Charter levels outlive a rebirth. Multipliers compound; additive
	-- procs (echo/zap/Blast/blastRadius/autoMine) add chance or radius instead.
	local ADDITIVE_BOOST = {
		echo = true, zap = true, blastRadius = true, autoMine = true, blastChance = true, luckyFind = true, fossilFind = true, pulverize = true, scrap = true, coolant = true, shortFuse = true, reach = true,
		earthquake = true, ricochet = true,
	}
	for _, held in ipairs(p.relics or {}) do
		local r = C.relicById(held.id)
		if r and b[r.stat] ~= nil then
			if ADDITIVE_BOOST[r.stat] then
				b[r.stat] += r.amount
			else
				b[r.stat] *= (1 + r.amount)
			end
		end
	end
	for id, level in pairs(p.charter or {}) do
		local row = C.charterById(id)
		if row and level > 0 and b[row.stat] ~= nil then
			local amt = row.per * math.min(level, row.max)
			if ADDITIVE_BOOST[row.stat] then
				b[row.stat] += amt
			else
				b[row.stat] *= (1 + amt)
			end
		end
	end

	-- Runes + gear (after relics/charter; clamped at the end).
	local byRune = {}
	for _, r in ipairs(p.runes or {}) do byRune[r.id] = r end
	local equippedPieces = {}
	for slot, pieceId in pairs(p.equippedGear or {}) do
		if pieceId then
			for _, g in ipairs(p.gear or {}) do
				if g.id == pieceId then
					equippedPieces[slot] = g
					break
				end
			end
		end
	end
	Gear.applyEquipped(b, equippedPieces, byRune)
	local _, fam = equippedTool(p)
	local sock = p.toolSockets and p.toolSockets[fam]
	local mainId, omniId
	if type(sock) == "string" then
		mainId = sock
	elseif type(sock) == "table" then
		mainId, omniId = sock.main, sock.omni
	end
	-- Track what is actually socketed, so a completed set can pay its bonus.
	-- Only worn runes count; a full set sitting in the bag is a full set you
	-- have not equipped.
	local socketed = {}
	local function wear(rune)
		if rune then
			-- Six sockets in the whole loadout: a rune that earns one is worth
			-- more than it was when a single head piece held five.
			Runes.applyRune(b, rune, Runes.SOCKET_GAIN)
			table.insert(socketed, rune)
		end
	end
	if mainId and byRune[mainId] then wear(byRune[mainId]) end
	if omniId and byRune[omniId] then wear(byRune[omniId]) end
	for _, ct in ipairs(p.chestTools or {}) do
		if ct.runeId and byRune[ct.runeId] and p.chestTool == ct.id then
			wear(byRune[ct.runeId])
		end
	end
	-- A coin-shop tool's own socket, while that tool is the one in hand.
	if p.shopToolId and not p.chestTool and p.shopToolRunes then
		local rid = p.shopToolRunes[p.shopToolId]
		if rid and byRune[rid] then
			wear(byRune[rid])
		end
	end
	for _, cardId in ipairs(p.equipped or {}) do
		local rid = p.petSockets and p.petSockets[cardId]
		if rid and byRune[rid] then wear(byRune[rid]) end
	end
	Runes.applySetBonuses(b, socketed)

	-- One equipped charm (does not take a rune/pet slot).
	if p.equippedCharm then
		Charms.applyEquipped(b, p.equippedCharm, p)
	end

	-- World Pulse multipliers (eligible players only).
	require(shared.MineWorldEvents).foldBoosts(b, p)

	-- Timed dig potions (chest / lucky drops).
	pcall(function()
		require(shared:WaitForChild("MinePotions")).applyBoosts(b, p)
	end)

	if p.chestTool then
		for _, ct in ipairs(p.chestTools or {}) do
			if type(ct) == "table" and ct.id == p.chestTool then
				require(shared.MineTemper).applyTemper(b, ct)
				break
			end
		end
	else
		--[[
			The tool family's temperament, when what is in hand is not a
			flagship. A flagship carries its own, above; only one temperament
			ever applies, the one on the tool actually being swung.
		]]
		--[[
			A FORGED TOOL WEARS ITS FAMILY'S SKIN. IT DID NOT.

			This read `(tier or 0) > 0`, meaning to exclude found objects -- the
			comment said so: "a fossil tool comes back as tier 0, and it is a
			found object with no family temperament". But equippedTool returns
			tier 0 on THREE paths, not one: the two found-tool paths AND the
			forged-ore-tool path, which returns `famId, 0` because a forged
			tool's rung is its ORE's tier and deliberately does not ride the
			third return value (equippedTool says so where it returns).

			So the test excluded exactly the tools the Forge exists to make.
			Fitting a skin to a pickaxe did nothing the moment the pickaxe you
			were swinging was one you forged -- which, past the first hour, is
			every pickaxe. The Forge's own panel reports the fitted skin for the
			family, so it read as applied while contributing nothing.

			Nothing caught it because both branches are silent: no skin fitted
			and a skin fitted-but-ignored produce the same boost table.

			Tested positively now. A forged row is the only one carrying
			`oreTier` (MineTools never sets it on a chest def) and the primary
			path also stamps `oreTool = true`, so either marker identifies one
			without having to enumerate what it is not. Found tools still fall
			through, and a flagship is still handled by the branch above --
			only one temperament ever applies, the one on the tool in hand.
		]]
		local row, fam, tier = equippedTool(p)
		local forged = type(row) == "table"
			and (row.oreTool == true or tonumber(row.oreTier) ~= nil)
		local tt = (forged or (tier or 0) > 0) and p.toolTempers and p.toolTempers[fam]
		if type(tt) == "table" and tt.temperId then
			require(shared.MineTemper).applyTemper(b, tt)
		end
	end

	--[[
		The zone-1 softcap is gone.

		It capped Mine Speed at +15% and Dirt Break at +8% until zone 2 was
		unlocked, which is the whole first session -- so the Sod Charm's
		+110%, every pet, every hat and every rune a new player earned in
		the meadow all landed as nothing, and the first twenty minutes
		felt like swinging at wet cardboard. That is the exact complaint
		it produced.

		Nothing here was gating progression anyway: how deep you may dig is
		Dig.Auth.canDigLayer and the layer window, not how hard you hit.
		Block HP is the depth curve (MineDepth) and the shop ladder is
		priced against it (MineShopLadders), so a stronger swing buys
		exactly the pace those two tables intend.
	]]

	--[[
		Echo is barred as a buff and pays as Swing Rate. Folded HERE, after every
		source has summed, because that is the one place that catches all of
		them -- gear, runes, temperaments, charms, pets and skills -- rather
		than fourteen temperament kits and counting.
	]]
	local echoLeft = tonumber(b.echo) or 0
	if echoLeft ~= 0 then
		local eRatio = (Stats and Stats.ECHO_TO_SWING) or (1.5 / 1.4)
		b.swingRate = (tonumber(b.swingRate) or 1) + echoLeft * eRatio
		b.echo = 0
	end

	local autoLeft = tonumber(b.autoMine) or 0
	if autoLeft ~= 0 then
		local ratio = (Stats and Stats.AUTO_MINE_TO_GEM) or (2.5 / 1.8)
		b.gemFind = (tonumber(b.gemFind) or 1) + autoLeft * ratio
		b.autoMine = 0
	end
	if p.autoMineLicense then
		b.autoMine = math.max(tonumber(b.autoMine) or 0, C.AUTO_MINE_LICENSE_RATE or 1)
	end

	return Runes.clampBoosts(b)
end

local function runeById(p, id)
	for _, r in ipairs(p.runes or {}) do if r.id == id then return r end end
end

local function gearById(p, id)
	for _, g in ipairs(p.gear or {}) do if g.id == id then return g end end
end

local function removeRune(p, id)
	for i, r in ipairs(p.runes or {}) do if r.id == id then return table.remove(p.runes, i) end end
end

local function familySocket(p, family)
	p.toolSockets = p.toolSockets or {}
	local v = p.toolSockets[family]
	if type(v) == "string" then
		v = { main = v, omni = nil, omniUnlocked = false }
		p.toolSockets[family] = v
	elseif type(v) ~= "table" then
		v = { main = nil, omni = nil, omniUnlocked = false }
		p.toolSockets[family] = v
	else
		v.main = v.main or nil
		v.omni = v.omni or nil
		v.omniUnlocked = v.omniUnlocked and true or false
	end
	return v
end

local function runeBusy(p, id)
	for fam, _ in pairs(p.toolSockets or {}) do
		local sock = familySocket(p, fam)
		if sock.main == id or sock.omni == id then return "tool" end
	end
	for _, ct in ipairs(p.chestTools or {}) do if ct.runeId == id then return "chest" end end
	for _, rid in pairs(p.petSockets or {}) do if rid == id then return "pet" end end
	for _, rid in pairs(p.shopToolRunes or {}) do if rid == id then return "shop" end end
	for _, g in ipairs(p.gear or {}) do
		-- pairs, not ipairs: sockets is sparse whenever slot 1 is still empty,
		-- and ipairs stops dead at the first hole.
		for _, sid in pairs(g.sockets or {}) do if sid == id then return "gear" end end
	end
	return nil
end

local function cap(p)
	local bag = C.BACKPACKS[p.backpackTier] or C.BACKPACKS[1]
	local base = bag.slots
	-- Founders Rig does not fill, and that is the whole of its perk.
	--
	-- The Wormhole Bag used to be in here too, from when it was a second
	-- infinite bag. It cashes itself once full now, and a bag that cannot fill
	-- can never fire that -- the ability would have been dead text on the card.
	-- Owning one also infinited whatever bag you had equipped, which is why
	-- this read p.wormholeBag rather than the equipped row.
	if bag.infinite or (p.foundersBag and p.equippedBag == "founders") then
		base = math.max(base, 1e15)
	end
	local mult = (boosts(p).backpack or 1) * (1 + (tonumber(p.backpackBonus) or 0))
	local best = math.max(base, math.ceil(base * mult))
	for _, row in ipairs(p.chestTools or {}) do
		local slots = (type(row) == "table") and tonumber(row.slots)
		if not slots then
			local id = (type(row) == "table") and row.id or row
			local def = (type(id) == "string") and Tools.chestTool(id)
			slots = def and tonumber(def.slots)
		end
		if slots then
			if type(row) == "table" and row.shiny then
				slots = math.floor(slots * (C.SHINY_MULT or 1.5))
			end
			if slots > best then
				best = slots
			end
		end
	end
	return best
end

local function atCamp(plr)
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	if C.atSurface then return C.atSurface(root.Position) end
	local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
	return flat.Magnitude <= (C.CAMP_RADIUS or 52)
end

-- Standing on the cloud deck, facing the gate you arrived through.
local function cloudCf()
	local y = (WorldBuilder and WorldBuilder.CLOUD_Y or 420) + 3
	return CFrame.lookAt(Vector3.new(0, y, 8), Vector3.new(0, y, -12))
end

local function lobbyCf()
	-- One of the four fountain-ring spawns, facing the fountain center.
	local world = workspace:FindFirstChild("MineWorld")
	local lobby = world and world:FindFirstChild("Lobby")
	local spawns = lobby and lobby:FindFirstChild("Spawns")
	local fountain = lobby and lobby:FindFirstChild("Fountain")
	local centerPart = fountain and fountain:FindFirstChild("FountainCenter")
	local center = (centerPart and centerPart.Position) or (C.FOUNTAIN or Vector3.new(0, 8, 0))
	if spawns then
		local pads = {}
		for _, child in ipairs(spawns:GetChildren()) do
			if child:IsA("SpawnLocation") then
				table.insert(pads, child)
			end
		end
		if #pads > 0 then
			local pick = pads[Random.new():NextInteger(1, #pads)]
			local pos = pick.Position + Vector3.new(0, 3, 0)
			return CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))
		end
	end
	-- Fallback: ring offset facing fountain, looking down the Meadow road.
	local ring = C.SPAWN_RING or 22
	local ang = math.rad(45)
	local pos = Vector3.new(math.sin(ang) * ring, 8, math.cos(ang) * ring)
	return CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))
end

local function surfaceCf(zone)
	zone = zone or C.ZONES[1]
	local pits = workspace:FindFirstChild("MineWorld") and workspace.MineWorld:FindFirstChild("Pits")
	local stand = pits and pits:FindFirstChild("Stand_" .. zone.id)
	if stand then return stand.CFrame end
	local origin = C.zoneOrigin(zone)
	local flat = Vector3.new(origin.X, 0, origin.Z)
	local dir = flat.Magnitude > 1 and flat.Unit or Vector3.new(0, 0, 1)
	local pitW = C.GRID * C.BLOCK + 8
	return CFrame.new(origin - dir * (pitW * 0.5 + 4) + Vector3.new(0, 6, 0), origin)
end

--[[
	The daily claim.

	Stored as a UTC day INDEX rather than a date string, because the streak has
	to answer "was the last claim yesterday", which is arithmetic. (The battle
	pass stores a date string -- it only ever asks "is this the same day", which
	is equality. Different question, different shape, both right.)
]]
--[[
	Quests.

	`questValue` is the only place a goal is measured, and the only place that
	decides a quest is finished. The client is handed a current/goal pair and
	draws it; it never evaluates anything.

	Four counters are kept on the profile because the game had no history for
	them. The rest are read straight off state that already existed, so they
	are correct for saves that predate quests -- an existing player finds the
	zone, card and rebirth quests already satisfied and claims them on the spot,
	which is the right answer: they did that work.
]]
local function questValue(p, stat)
	local s = p.stats or {}
	if stat == "blocks" then
		return tonumber(s.blocks) or 0
	elseif stat == "sells" then
		return tonumber(s.sells) or 0
	elseif stat == "packs" then
		return tonumber(s.packs) or 0
	elseif stat == "chests" then
		return tonumber(s.chests) or 0
	elseif stat == "merges" then
		return tonumber(s.merges) or 0
	elseif stat == "cards" then
		return #(p.cards or {})
	elseif stat == "zone" then
		return tonumber(p.maxUnlockedZone) or 1
	elseif stat == "rebirth" then
		return tonumber(p.prestige) or 0
	elseif stat == "picktier" then
		-- Upgrades past the free starter (wood / tier 1). Absolute count so a
		-- player who already bought a shop pickaxe can CLAIM immediately.
		local n = 0
		local ladder = (p.tools and tonumber(p.tools.pickaxe)) or 1
		if ladder > 1 then
			n += ladder - 1
		end
		local okL, Ladders = pcall(require, shared:WaitForChild("MineShopLadders"))
		for id, on in pairs(p.ownedShopTools or {}) do
			local row = on and okL and Ladders.byId(id)
			if row and row.family == "pickaxe" then
				n += 1
			end
		end
		return n
	elseif string.sub(stat, 1, 7) == "chestsL" then
		-- Chests opened in depth layer N OR DEEPER (50m bands: 1 = 1-50m,
		-- 2 = 51-100m...). "Or deeper" so a player who shafts straight past a
		-- band still finishes the rung with the chests they meet below it --
		-- an exact band stalled the whole ladder behind it.
		local n = tonumber(string.sub(stat, 8)) or 1
		local total = 0
		for k, v in pairs(s.chestSec or {}) do
			if (tonumber(k) or 0) >= n then
				total += tonumber(v) or 0
			end
		end
		return total
	elseif stat == "depth" then
		local best = 0
		for _, d in pairs(p.deepest or {}) do
			best = math.max(best, tonumber(d) or 0)
		end
		return best
	elseif stat == "gear" then
		return #(p.gear or {})
	elseif stat == "runes" then
		return #(p.runes or {})
	end
	return 0
end

--[[
	A goal counts FROM WHEN THE QUEST BECAME ACTIVE.

	questValue returns the lifetime figure. The baseline is that figure at the
	moment the quest became current, and progress is the difference. Without
	this, "Rebirth once" is satisfied by a prestige you did last week and a
	veteran claims half the ladder on login -- "mine 1,000 blocks" and "reach
	1,000 blocks mined" are not the same quest.

	Captured lazily: the first time a quest is looked at without a baseline, now
	becomes its zero. That is also the migration, so nobody is retro-credited.
]]
local function questBase(p, stat)
	p.questBase = p.questBase or {}
	if p.questBase[stat] == nil then
		p.questBase[stat] = questValue(p, stat)
	end
	return p.questBase[stat]
end

-- Called when the ladder advances: the new quest's stat starts from here.
local function questRebase(p)
	local q = Quests.at(math.floor(tonumber(p.quest) or 1))
	if not q then
		return
	end
	p.questBase = p.questBase or {}
	p.questBase[q.stat] = questValue(p, q.stat)
end

local function questState(p)
	local index = math.floor(tonumber(p.quest) or 1)
	local q = Quests.at(index)
	if not q then
		-- Ladder finished. Say so rather than leaving an empty tracker.
		return { done = true, index = Quests.COUNT, total = Quests.COUNT }
	end
	-- picktier is an absolute milestone (own any paid/shop pick), not a delta
	-- from when the rung became active — otherwise a pre-owned Sodpick never
	-- lights CLAIM on "Buy a better pickaxe".
	local current
	if q.stat == "picktier" then
		current = questValue(p, q.stat)
	else
		current = math.max(0, questValue(p, q.stat) - questBase(p, q.stat))
	end
	return {
		id = q.id,
		text = q.text,
		tip = q.tip,
		current = math.min(current, q.goal),
		goal = q.goal,
		ready = current >= q.goal,
		reward = Quests.describe(q.reward),
		index = index,
		total = Quests.COUNT,
		done = false,
	}
end

local function utcDayIndex()
	return math.floor(os.time() / 86400)
end

--[[
	The day's three repeatable quests.

	Rolled once per UTC day and then STORED, not re-derived. The roll is
	deterministic on day and player, so storing is not what keeps them stable
	across a rejoin -- it is what keeps a release that edits the pool from
	swapping a player's quests out from under them halfway through their day.
]]
local function ensureDailyQuests(p, userId)
	local today = utcDayIndex()
	local dq = p.dailyQuests
	local stale = type(dq) ~= "table" or type(dq.list) ~= "table" or dq.day ~= today
	if not stale then
		for _, row in ipairs(dq.list) do
			if not Quests.dailyById(row.id) then
				stale = true
				break
			end
		end
	end
	if stale then
		p.dailyQuests = { day = today, list = Quests.rollDaily(today, userId) }
	end
	return p.dailyQuests
end

local function dailyQuestState(p, userId)
	local dq = ensureDailyQuests(p, userId)
	local zone = p.maxUnlockedZone or 1
	local out = {}
	for i, row in ipairs(dq.list) do
		local def = Quests.dailyById(row.id)
		if def then
			local progress = math.min(tonumber(row.progress) or 0, def.goal)
			out[i] = {
				id = row.id,
				text = def.text,
				current = progress,
				goal = def.goal,
				ready = progress >= def.goal and not row.claimed,
				claimed = row.claimed and true or false,
				reward = Quests.dailyGems(def, zone) .. " Gems",
			}
		end
	end
	return out
end

-- Every counter the quests read moves through here, so the lifetime total and
-- the day's three can never disagree about what happened.
-- Collection / Planets share profile.found. Normalize keys + backdate bag chests.
syncFoundLedger = function(p)
	if type(p) ~= "table" then return end
	p.found = p.found or {}
	p.backpack = p.backpack or {}
	local norm = {}
	for k, v in pairs(p.found) do
		local key = tostring(k)
		local n = (v == true) and 1 or (tonumber(v) or 0)
		if n > 0 then
			norm[key] = math.max(norm[key] or 0, n)
		end
	end
	for _, item in ipairs(p.backpack) do
		if type(item) == "table" and (item.kind == "chest" or item.kind == "crate") then
			local id = item.chestId or item.id
			if id ~= nil and tostring(id) ~= "" then
				local key = tostring(id)
				norm[key] = math.max(norm[key] or 0, 1)
			end
		end
	end
	p.found = norm
end

local function bumpStat(plr, p, stat)
	p.stats = p.stats or {}
	p.stats[stat] = (p.stats[stat] or 0) + 1
	-- Milestones: the first pack opened is when the starter bundle is offered
	-- (the client decides whether it can show), and the analytics dashboard
	-- hears about rebirths and pack milestones -- never every block.
	if stat == "packs" and p.stats.packs == 1 then
		net:FireClient(plr, "offerStarter")
	end
	if stat == "rebirth" or (stat == "packs" and (p.stats.packs == 1 or p.stats.packs == 10 or p.stats.packs == 100)) then
		pcall(function()
			game:GetService("AnalyticsService"):LogCustomEvent(plr,
				stat == "rebirth" and "Rebirth" or ("PacksOpened" .. p.stats.packs), 1)
		end)
	end
	-- Event Horizon pass: digs/fossils only in the event mine;
	-- sells/packs count while the event is live (sell pad / pack open).
	do
		local ev = C.EVENTS and C.EVENTS[1]
		local zoneId = ev and (ev.zoneId or "bigbang") or "bigbang"
		local live = ev and C.limitedActive and C.limitedActive()
		if live then
			local inEvent = p.zoneId == zoneId
			if stat == "blocks" and inEvent then
				p.stats.eventBlocks = (p.stats.eventBlocks or 0) + 1
				EventPass.tick(ev.id, p)
			elseif stat == "sells" and (inEvent or p.bigbangOwned) then
				p.stats.eventSells = (p.stats.eventSells or 0) + 1
				EventPass.tick(ev.id, p)
			elseif stat == "packs" and (inEvent or p.bigbangOwned) then
				p.stats.eventPacks = (p.stats.eventPacks or 0) + 1
				EventPass.tick(ev.id, p)
			elseif inEvent then
				EventPass.tick(ev.id, p)
			end
		end
	end
	local dq = ensureDailyQuests(p, plr.UserId)
	for _, row in ipairs(dq.list) do
		if row.stat == stat and not row.claimed then
			row.progress = (tonumber(row.progress) or 0) + 1
		end
	end
	-- Contractor jobs share the same counters.
	local cq = p.contracts
	if type(cq) == "table" and type(cq.list) == "table" then
		for _, row in ipairs(cq.list) do
			if row.stat == stat and not row.claimed then
				-- Ownership/depth jobs prefer base deltas; bump path for
				-- blocks/sells/packs/merges keeps them moving without a tick.
				row.progress = (tonumber(row.progress) or 0) + 1
			end
		end
	end
	MineBadges.onStat(plr, p, stat)
end

-- Extra quest surfaces (milestones + contractor) hang off Quests (already a
-- local) so we stay under Luau's 200-local ceiling on this script.

function Quests.svEnsureContracts(p, userId)
	local today = utcDayIndex()
	local cq = p.contracts
	if type(cq) ~= "table" or type(cq.list) ~= "table" or cq.day ~= today then
		local list = Quests.rollContracts(today, userId)
		for _, row in ipairs(list) do
			row.base = questValue(p, row.stat)
			row.progress = 0
		end
		p.contracts = { day = today, list = list }
	end
	return p.contracts
end

function Quests.svContractProgress(p, row)
	if row.base ~= nil then
		return math.max(tonumber(row.progress) or 0, math.max(0, questValue(p, row.stat) - (tonumber(row.base) or 0)))
	end
	return tonumber(row.progress) or 0
end

function Quests.svContractState(p, userId)
	local cq = Quests.svEnsureContracts(p, userId)
	local zone = p.maxUnlockedZone or 1
	local out = {}
	for i, row in ipairs(cq.list) do
		local def = Quests.contractById(row.id)
		if def then
			local progress = math.min(Quests.svContractProgress(p, row), def.goal)
			out[i] = {
				id = row.id,
				text = def.text,
				current = progress,
				goal = def.goal,
				ready = progress >= def.goal and not row.claimed,
				claimed = row.claimed and true or false,
				reward = Quests.contractGems(def, zone) .. " Gems",
			}
		end
	end
	return out
end

function Quests.svMilestoneState(p)
	p.milestones = p.milestones or {}
	local out = {}
	for _, m in ipairs(Quests.MILESTONES or {}) do
		local claimed = p.milestones[m.id] or p.milestones[tostring(m.id)]
		local current = math.min(questValue(p, m.stat), m.goal)
		out[#out + 1] = {
			id = m.id,
			text = m.text,
			current = current,
			goal = m.goal,
			ready = current >= m.goal and not claimed,
			claimed = claimed and true or false,
			reward = Quests.describe(m.reward),
		}
	end
	return out
end

local function dailyState(p)
	local d = p.daily or { streak = 0, last = 0 }
	local today = utcDayIndex()
	local last = tonumber(d.last) or 0
	-- What the NEXT claim would be worth: an unbroken run continues, a broken
	-- one starts again at day one. Shown before claiming, so the card can say
	-- what is behind it.
	local nextStreak = (last == today - 1) and ((tonumber(d.streak) or 0) + 1) or 1
	local reward = Scrolls.dailyReward(nextStreak)
	local ready = last ~= today
	-- The calendar highlights the next claim, or today's once it is taken.
	local shown = ready and nextStreak or math.max(1, tonumber(d.streak) or 1)
	return {
		ready = ready,
		streak = tonumber(d.streak) or 0,
		nextStreak = nextStreak,
		day = Scrolls.dailyDay(nextStreak),
		days = Scrolls.DAILY_DAYS,
		text = Scrolls.describeDaily(reward, p.maxUnlockedZone or 1, nextStreak),
		calendar = Scrolls.dailyCalendar and Scrolls.dailyCalendar(shown, ready, p.maxUnlockedZone or 1) or nil,
		weekMult = Scrolls.dailyWeekMult and Scrolls.dailyWeekMult(shown) or 1,
	}
end

local function snap(plr)
	local p = profiles[plr.UserId]
	if not p then return end
	syncFoundLedger(p)
	--[[
		EVERY PACK IS ITS OWN THING.

		The bag is a flat list and the inventory groups it into stacks for
		display, so "open one of these" used to travel as a list INDEX. An index
		is only true until the list shifts -- another pack lands, a run opens
		three -- and then it names the wrong pack. Stamping a permanent id on
		the way out covers every grant path without touching two dozen minters.
	]]
	for _, pk in ipairs(p.packs or {}) do
		if type(pk) == "table" and not pk.uid then
			pk.uid = instanceHex16()
		end
	end
	--[[
		Same stamp, for every other list of owned instances.

		chestTools was the real gap: its `id` is the CATALOG id, so two copies
		of the same flagship tool were indistinguishable in the save -- you
		could not name one of them to upgrade, trade or scrap it. gear and
		relics had the same shape. `id` is left alone because plenty of code
		keys off it; `uid` is added beside it.

		Runes are skipped on purpose: their `id` is already a 16-hex instance
		value, so a `uid` next to it would just be the same bytes twice.

		Quantity maps -- charms, tempers, eventTools, ores, tools --
		get nothing. You own three of a charm, not three distinguishable charms,
		and giving each a row would grow the save rather than shrink it.
	]]
	for _, list in ipairs({ p.chestTools, p.gear, p.relics, p.oreTools }) do
		if type(list) == "table" then
			for _, row in ipairs(list) do
				if type(row) == "table" and not row.uid then
					row.uid = instanceHex16()
				end
			end
		end
	end
	-- Other players see your pets: the few fields a pet model needs, as an
	-- attribute every client can read (ClientFns.othersPets builds them).
	do
		local shown = {}
		local seatN = C.effectivePetSlots and C.effectivePetSlots(p) or (p.petSlots or 3)
		for _, id in ipairs(p.equipped or {}) do
			local c = #shown < seatN and cardById(p, id)
			if c then
				shown[#shown + 1] = {
					n = c.name, a = c.animal, t = c.typeId, v = c.variant, r = c.rarityId, sp = c.species,
					s = c.shiny and 1 or nil, d = c.shadow and 1 or nil,
				}
			end
		end
		local json = game:GetService("HttpService"):JSONEncode(shown)
		if plr:GetAttribute("PetsJSON") ~= json then
			plr:SetAttribute("PetsJSON", json)
		end
	end
	net:FireClient(plr, "snapshot", {
		settings = p.settings, starterBought = p.starterBought and true or false,
		shopToolRunes = p.shopToolRunes or {},
		playtime = p.playtime, serverTime = os.time(),
		freeGear = (not p.freeGearUsed) and #(p.gear or {}) == 0,
		gems = p.gems, coins = p.coins or 0, dust = p.dust, dustShop = Packs.dustShopPayload and Packs.dustShopPayload(p) or nil, prestige = p.prestige, pickaxeTier = p.pickaxeTier,
		backpackTier = p.backpackTier, petSlots = p.petSlots, petSlotsEffective = C.effectivePetSlots and C.effectivePetSlots(p) or p.petSlots, zoneId = p.zoneId,
		maxUnlockedZone = p.maxUnlockedZone, bigbangOwned = p.bigbangOwned and true or false,
		eventPass = (function()
			local ev = C.EVENTS and C.EVENTS[1]
			if not ev then return nil end
			EventPass.ensure(p, ev.id)
			if C.limitedActive and C.limitedActive() then
				EventPass.tick(ev.id, p)
			end
			return EventPass.payload(ev.id, p)
		end)(),
		limitedActive = C.limitedActive and C.limitedActive() or false,
		worldEvent = require(shared.MineWorldEvents).payload("tick", p),
		coreSamples = p.coreSamples or {},
		deepest = p.deepest, deepestSection = p.deepestSection or {}, backpack = p.backpack,
		packs = p.packs, cards = p.cards, equipped = p.equipped, cap = cap(p),
		ores = p.ores or {},
		--[[
			The pouch, as the panel needs it. Capacity and the next rung's price
			are SERVER-COMPUTED and sent, not re-derived on the client: the price
			comes off the ore value curve, and a client that computes its own
			would show a number the server then refuses.
		]]
		orePouchTier = Dig.pouchTier(p),
		oreLocks = p.oreLocks or {},
		orePouch = (function()
			local Pouch = require(shared:WaitForChild("MineOrePouch"))
			local t = Dig.pouchTier(p)
			local def = Pouch.tier(t)
			return {
				tier = t,
				maxTier = Pouch.MAX_TIER,
				name = def and def.name or "Pouch",
				cap = Pouch.capacity(t),
				held = Pouch.held(p.ores),
				upgradeCost = Pouch.upgradeCost(t),
				nextName = (t < Pouch.MAX_TIER) and Pouch.TIERS[t + 1].name or nil,
				nextCap = (t < Pouch.MAX_TIER) and Pouch.capacity(t + 1) or nil,
			}
		end)(),
		-- The Forge keys its recipe list off this, not off what is banked.
		oresSeen = p.oresSeen or {},
		-- Which forged tool is in hand, so the Forge can mark it EQUIPPED.
		oreToolEquipped = p.oreToolEquipped,
		oreTools = p.oreTools or {},
		oreToolEquipped = p.oreToolEquipped,
		itemSlotsUsed = C.itemSlotsUsed and C.itemSlotsUsed(p) or nil,
		itemSlotCap = C.itemSlotCap and C.itemSlotCap(p) or nil,
		itemSlotPrice = C.itemSlotPrice and C.itemSlotPrice(p) or nil,
		charms = p.charms, equippedCharm = p.equippedCharm,
		-- The RAMP's stacks, so the panel can say how charged a ramp charm is.
		-- Sent rather than derived: the client has no block-break feed of its own.
		charmRamp = p.charmRamp,
		potions = (function()
			local ok, snapP = pcall(function()
				return require(shared:WaitForChild("MinePotions")).snapshot(p)
			end)
			return ok and snapP or { bag = {}, active = {} }
		end)(),
		vfx = p.vfx, equippedVfx = p.equippedVfx,
		packsOpened = p.packsOpened,
		vip = hasVipPass(plr),
		vipMembership = p.vip,
		foundersBag = p.foundersBag and true or false,
		equippedBag = p.equippedBag,
		coinDouble = p.coinDouble and true or false,
		autoMineLicense = p.autoMineLicense and true or false,
		vipSeats = vipSeatsLeft,
		vipPrice = Packs.VIP_PRICE,
		vipRobux = Packs.VIP_ROBUX or C.FOUNDERS_ROBUX or 999,
		vipSeatsTotal = Packs.VIP_SEATS,
		-- Lifetime counters. The quests already read these server-side; the pack
		-- inspector wants the packs total, and it was printing 0 because the
		-- table never crossed the wire.
		stats = p.stats,
		load = p.load or 0,
		haulCoins = p.haulCoins or 0, haulGems = p.haulGems or 0, haulSpace = p.haulSpace or 0, haulMix = p.haulMix,
		spaceCoins = p.spaceCoins or 0,
		wormholeBag = p.wormholeBag == true,
		bagInfinite = (C.BACKPACKS[p.backpackTier] and C.BACKPACKS[p.backpackTier].infinite) and true or false,
		-- Seconds until the bag next tries to cash itself, and whether it is
		-- full enough for that attempt to do anything.
		autoSellSec = (C.BACKPACKS[p.backpackTier] and tonumber(C.BACKPACKS[p.backpackTier].autoSellSec)) or nil,
		autoSellLeft = p.autoSellAt and math.max(0, math.floor(p.autoSellAt - os.clock())) or nil,
		eventToolId = p.eventToolId,
		eventTools = p.eventTools,
		mineResetRemaining = math.max(0, (mineResetState.at.meadow or os.clock()) - os.clock()),
		mineResetSec = C.MINE_RESET_SEC or 1200,
		boosts = boosts(p), pickName = (equippedTool(p) or {}).name or "Pickaxe",
		boostSources = Dig.boostSources and Dig.boostSources(p) or nil,
		upgrades = Dig.upgradesFor and Dig.upgradesFor(p, plr.UserId) or nil,
		tool = (function()
			local t, fam, tier = equippedTool(p)
			return { id = t.id, name = t.name, family = fam, tier = tier, power = t.power,
				rate = t.rate, radius = t.radius, cooldown = t.cooldown, range = t.range, axis = t.axis,
				-- Carried so the client cannot disagree with the server about reach.
				reach = Tools.reachOf(t) * (1 + math.max(0, tonumber((boosts(p) or {}).reach) or 0)) }
		end)(),
		tools = p.tools, toolEquipped = p.toolEquipped ~= false,
		ownedShopTools = p.ownedShopTools or {},
		shopToolId = p.shopToolId,
		zoneId = p.zoneId,
		zoneIndex = (C.zoneIndex and p.zoneId and C.zoneIndex(p.zoneId)) or (p.maxUnlockedZone or 1),
		atSurface = atCamp(plr),
		skills = skillState(p), skillSlot = p.skillSlot or 1,
		boughtSecond = p.boughtSecond,
		-- Where the character is, not a remembered flag. See MineConfig.
		inClouds = C.playerInClouds(plr), rebirth = p.prestige or 0,
		temperTokens = p.temperTokens or 0, skillBurned = p.skillBurned or 0,
		skillBought = p.skillBought or 0, skillMax = Skills.maxTreePoints and Skills.maxTreePoints() or nil,
		sacrificeRate = Skills.UNUSED_SKILL_POINT_SELL,
		buybackCost = Skills.BUYBACK_TOKENS, rollCost = Skills.TEMPER_ROLL_COST,
		rebirthTokenGrant = Skills.rebirthTokens((p.prestige or 0) + 1),
		rebirthCost = Skills.rebirthCost((p.prestige or 0) + 1),
		rebirthMinCoins = Skills.minRebirthCoins((p.prestige or 0) + 1),
		rebirthAdvice = Skills.rebirthAdvice(p.coins, p.prestige, p.maxUnlockedZone),
		rebirthTokens = Skills.tokensFor((p.prestige or 0) + 1),
		rebirthGems = C.rebirthGems((p.prestige or 0) + 1),
		relics = p.relics or {}, charter = p.charter or {}, found = p.found or {},
		chestTools = p.chestTools or {}, chestTool = p.chestTool,
		toolTier = p.toolTier or {},
		-- Owned once. Pass XP/claims live under Inventory > Pass.
		battlePass = p.battlePass,
		runes = p.runes, gear = p.gear, equippedGear = p.equippedGear,
		toolSockets = p.toolSockets, petSockets = p.petSockets,
		hatSlots = Gear.HAT_SLOTS,
		tailorStat = Dig.tailor[p],
		toolTempers = p.toolTempers or {},
		tempers = p.tempers or {},
		temperCasePrice = require(shared.MineTemper).CASE_PRICE_TOKENS,
		runeRollPrice = Runes.rollPriceFor(p.maxUnlockedZone), gearRollPrice = tonumber(Gear.ROLL_TOKEN_COST) or 5,
		credits = p.credits or 0, scrolls = p.scrolls or Scrolls.emptyBag(),
		quest = questState(p),
		dailyQuests = dailyQuestState(p, plr.UserId),
		milestones = Quests.svMilestoneState(p),
		contracts = Quests.svContractState(p, plr.UserId),
		daily = dailyState(p),
		groupWheel = GroupWheelService.payload(p),
		discordLinked = p.discordLinked == true,
		discordId = p.discordId,
		discordBonusClaimed = p.discordBonusClaimed == true,
		pass = (function()
			local bp = p.pass or Scrolls.emptyPass()
			local xp = bp.xp or 0
			local tier = Scrolls.passTier(xp)
			local today = os.date("!%Y-%m-%d")
			local dayXp = (bp.day == today) and (bp.dayXp or 0) or 0
			local function claimedNums(led)
				local t = {}
				if type(led) == "table" then
					for k, v in pairs(led) do
						if v then
							local n = math.floor(tonumber(k) or 0)
							if n >= 1 then
								t[#t + 1] = n
							end
						end
					end
					table.sort(t)
				end
				return t
			end
			return {
				xp = xp,
				tier = tier,
				owned = bp.owned and true or false,
				season = bp.season,
				free = bp.free or {},
				prem = bp.prem or {},
				-- Integer lists survive remotes; `{[5]=true}` maps often arrive empty
				-- and the pass rail pops CLAIM again on a rung the server already paid.
				freeClaimed = claimedNums(bp.free),
				premClaimed = claimedNums(bp.prem),
				-- Progress into the next tier, and how much of today's cap is
				-- left, because a bar that stops moving with no explanation
				-- reads as a bug.
				intoTier = xp - Scrolls.passXpFor(tier),
				perTier = Scrolls.PASS_XP_PER_TIER,
				dailyLeft = dayXp,
				dailyCap = 0,
				dailyFromQuests = true,
				tiers = Scrolls.PASS_TIERS,
			}
		end)(),
		creditPacks = Scrolls.CREDIT_PACKS, scrollShop = Scrolls.ITEMS,
	})
end

-- A snapshot is the whole profile: cards, packs, relics, skills. Sending one
-- per destroyed block meant a 99-cell blast shipped 99 of them in a frame, which
-- is exactly the hitch you feel when a big charge goes off. Mark the player
-- dirty instead and flush at most ten times a second.
local dirty = {}
local function markDirty(plr)
	dirty[plr.UserId] = plr
end

task.spawn(function()
	while true do
		task.wait(0.1)
		for id, plr in pairs(dirty) do
			dirty[id] = nil
			if plr and plr.Parent then
				pcall(snap, plr)
			end
		end
	end
end)

--[[
	The first session.

	There was nothing here at all: a new player spawned facing a hole with zero
	of every currency, seven rail buttons, seven shop fronts behind them and no
	indication that the game is played by holding the mouse on a rock. On Roblox
	that first minute decides whether there is a second one.

	Three lines, each cleared by doing the thing it asks, then it never shows
	again. Deliberately not a quest system -- no rewards, no tracking, nothing to
	claim. It gets out of the way as soon as the loop is obvious.
]]
-- Step 1 no longer names a walk: a brand new profile now spawns at the pit
-- rim (see boot / firstSpawnAtPit), so there IS a rock in reach when this
-- line appears. If first spawn ever moves back to the lobby, this line has
-- to name the walk again -- twice in this file's history a player read
-- "hold on a rock", found none within 125 studs, and concluded mining was
-- broken.
-- starter pit, and the nearest block is 125 studs away against a 26 stud reach
-- -- so "hold the mouse on a rock" is a lie for the first few seconds, and a
-- player who obeys it literally concludes mining is broken. That exact mistake
-- is recorded twice in this file's history; do not shorten this line back.
--[[
	Step 4 exists because the first three teach the loop and then stop, leaving
	the player with a better pickaxe and no idea that cards -- the thing the
	game is named after -- come out of chests. Nothing anywhere said to look
	for one.

	It clears on the first chest OPENED rather than seen, because finding one is
	the beat worth ending the tutorial on.
]]
local Intro = {
	--[[
		The v2 ladder. Every step either force-opens the panel it teaches
		(panel/tab ride the payload; the client routes them) or requires one
		concrete action — the numbered introAdvance(...) hooks scattered through
		this file. `ack = true` steps advance from a banner tap instead.

		Grants make a forced step affordable exactly once: gems are topped up
		to the step's cost, a pack appears only if the bag is empty. The spent
		mark lives in p.introGrants so nothing can be farmed.
	]]
	steps = {
		[1] = { text = "HOLD on a rock to break it." },
		[2] = { text = "Bag's filling up! Run it to the SELL PAD.", waypoint = "sell", bonusGems = 10 },
		[3] = { text = "Coins burning a hole? BUY A BIGGER PICK.", panel = "shop", waypoint = "shop", grantCoins = "nextPick" },
		[4] = { text = "Chests are stuffed with packs. CRACK ONE.", waypoint = "chest" },
		[5] = { text = "RIP IT OPEN — Inventory, Packs.", panel = "inventory", tab = "packs", grantPack = true },
		[6] = { text = "Send your best pet out. It mines WITH you.", panel = "inventory", tab = "cards", highlight = "cardsTab", bonusGems = 15 },
		[7] = { text = "Free gems, top-left. CLAIM IT.", highlight = "questClaim" },
		[8] = { text = "Now the good stuff: ROLL A RUNE.", panel = "summon", grantGems = "runeRoll", waypoint = "enchanter" },
		[9] = { text = "Jam it into your pick. Yours forever, even through rebirth.", panel = "enchanter", tab = "sockets", requireAction = "socketToolRune", waypoint = "enchanter", bonusGems = 25 },
		-- Two things wrong here before: it said hats go on your PETS (they are
		-- player-only now, three seats, TODO 6.2) and it taught gems (they cost
		-- rebirth tokens).
		[10] = { text = "Summon a HAT — your first roll is FREE. Hats are real Roblox items, you wear them yourself, and after the free one they cost REBIRTH TOKENS.", panel = "summon", highlight = "gearRow", waypoint = "enchanter" },
		[11] = { text = "Your runes live at the Enchanter, on its RUNES tab. Fuse spares there later (50%, no pity).", panel = "enchanter", tab = "runes", ack = true, waypoint = "enchanter" },
		[12] = { text = "NEW ZONE: Greyvein. The bar is how close you are.", panel = "zones" },
		[13] = { text = "JOBS: dailies and the board pay gems every UTC day. Come back here when you need more.", panel = "jobs", ack = true, waypoint = "contractor" },
		[14] = { text = "EVENTS: Event Horizon is free while its timer runs — grab it from the portal.", panel = "events", ack = true },
		-- Was the FOSSIL BENCH. Fossils are retired, and the step is repurposed
		-- rather than removed: introAdvance walks these by number, so deleting 15
		-- would strand every player sitting on it. The ore pouch is the right
		-- replacement -- it is new, it is where ore turns into gems, and nothing
		-- else taught it.
		[15] = { text = "Your ORE POUCH holds everything you dig. Sell ore there for GEMS -- and it is the one thing a rebirth never takes.", panel = "shop", tab = "pouch", ack = true, waypoint = "shop" },
		[16] = { text = "Last one — SPIN A TEMPERAMENT CASE.", panel = "enchanter", tab = "summon", highlight = "caseRow", waypoint = "enchanter", ack = true },
		[17] = { text = "Rebirth grants SKILL POINTS for the Clouds skill tree.", ack = true },
		[18] = { text = "REBIRTH. Reset small, come back way bigger.", panel = "prestige", waypoint = "prestige" },
		[19] = { text = "DAILY REWARD: claim today's gift. Seven days in a row pays the day-7 jackpot.", highlight = "daily" },
		[20] = { text = "FREE GIFTS fill up while you play. Tap the gift box under the wallet and open one.", highlight = "gifts" },
		[21] = { text = "Dig down to 30m. The deepest miners get their name on the board at the far end of every mine." },
		[22] = { text = "Chests glow. When the dirt around you picks up a warm light, a chest is close: dig toward it and open 3 chests.", count = 3 },
		[23] = { text = "Every tool has its own RUNE SLOT. Rebirth takes coin tools back, but the rune stays in the slot and is waiting when you buy that tool again.", panel = "enchanter", tab = "sockets", ack = true, waypoint = "enchanter" },
		--[[
			The hat/face/rune lessons. Each one opens the screen it teaches AND
			points a hand at the exact thing to tap (`highlight` resolves to a
			named widget on the client, ClientFns.handTargets) -- "gear" was the
			system players never found, and a sentence in a banner was why.
		]]
		[24] = { text = "A HAT is yours -- you have three seats, and every hat you wear makes every pet stronger. Tap a HAT seat, then tap a hat.", panel = "inventory", tab = "tools", highlight = "hatSeat", requireAction = "equipGearPiece" },
		[25] = { text = "Your FACE is the one piece nobody else wears -- it multiplies your WHOLE team. Fit one here.", panel = "inventory", tab = "tools", highlight = "faceSeat", ack = true },
		[26] = { text = "Runes fit from your bag now: one per pet, one per hat, one in your face, one on your tool. Eight in the entire game.", panel = "inventory", tab = "runes", highlight = "runesTab", ack = true },
		-- No `ack`: this one only clears when the pickaxe is actually in hand.
		[27] = { text = "Go to the BLACKSMITH and grab your free pickaxe.", waypoint = "shop" },
		[28] = { text = "Break the next block. That swing drops your charm." },
		[29] = { text = "Open the 3 gear crates in your bag. They're rigged: the best hats for the pets you have out.", panel = "inventory", tab = "packs", count = 3, grantGear = 3 },
		[30] = { text = "Tap GO ENCHANTER.", panel = "inventory", tab = "tools", highlight = "goEnchanter", ack = true },
		[31] = { text = "Inventory → Equipment. Equip the best hats on your pets.", panel = "inventory", tab = "tools", highlight = "petSeat" },
		[32] = { text = "Salvage is in the Enchanter now. Open that tab.", panel = "enchanter", tab = "salvage", waypoint = "enchanter", ack = true },
		[33] = { text = "Scrap 5 pets. The quest pays stardust on top of what they salvage for.", panel = "enchanter", tab = "salvage", count = 5 },
		[34] = { text = "The Stardust Shop is on the Enchanter. Open it.", panel = "enchanter", tab = "dust", waypoint = "enchanter", ack = true },
		[35] = { text = "Buy 1 pack from the Stardust Shop.", panel = "enchanter", tab = "dust", grantDust = 500 },
		[36] = { text = "Buy 5 temperament rolls. Rebirth just paid the tokens.", panel = "enchanter", tab = "temper", waypoint = "enchanter", count = 5 },
		[37] = { text = "Reach rebirth 5 when you feel like it." },
		[38] = { text = "Open a gear crate whenever you want another hat.", ack = true, bonusGems = 25 },
		[39] = { text = "Temperament tokens still come from rebirth. Spend them when you want.", ack = true, grantTokens = 15 },
	},
	--[[
		The order they are taught in. Step NUMBERS are what the introAdvance(...)
		hooks name (here and in MineShopBuy), so a new step takes a new number
		and slots into this list; the old numbers never move.
	]]
	--[[
		Eight beats to the loop, then the two systems that keep someone here.

		27 opens the ladder again. It used to be an errand for a tool every
		profile was already seeded with, which read as a broken game on the very
		first instruction anyone saw. blank() now starts you with no pickaxe at
		all, so the step asks for something real and the Blacksmith hands it
		over free.

		Runes and temperaments sit AFTER the rebirth step. They are the best
		part of the game and they mean nothing to someone who has not yet felt a
		run end -- taught at minute three they were noise, taught after a
		rebirth they are the reason to start the next one.
	]]
	order = { 27, 1, 2, 3, 4, 5, 6, 7, 12, 18, 8, 9, 16 },
}
-- Finished. Clear of every step number (the v2 ladder used 19 for done).
Intro.done = 99
Intro.posOf = {}
for i, n in ipairs(Intro.order) do
	Intro.posOf[n] = i
end
-- Where a step sits in the teaching order; done sits past the end.
function Intro.pos(step)
	return Intro.posOf[math.floor(tonumber(step) or 1)] or (#Intro.order + 1)
end
-- The step taught after `step`, or done.
function Intro.nextAfter(step)
	local i = Intro.posOf[math.floor(tonumber(step) or 1)]
	return (i and Intro.order[i + 1]) or Intro.done
end

-- True once the player owns any coin/shop pickaxe past the free starter.
local function ownsBetterPickaxe(p)
	if not p then
		return false
	end
	if ((p.tools and tonumber(p.tools.pickaxe)) or 1) > 1 then
		return true
	end
	local okL, Ladders = pcall(require, shared:WaitForChild("MineShopLadders"))
	for id, on in pairs(p.ownedShopTools or {}) do
		local row = on and okL and Ladders.byId(id)
		if row and row.family == "pickaxe" then
			return true
		end
	end
	return false
end

-- A step whose deed is already done is skipped, so a veteran remapped into
-- the middle of the ladder is not asked to equip a card they equipped weeks ago.
local function introSatisfied(p, step)
	if step == 3 then
		return ownsBetterPickaxe(p)
	elseif step == 6 then
		return #(p.equipped or {}) > 0
	elseif step == 7 then
		return (tonumber(p.quest) or 1) > 1
	elseif step == 9 then
		return next(p.toolSockets or {}) ~= nil or next(p.petSockets or {}) ~= nil
	elseif step == 10 then
		return next(p.equippedGear or {}) ~= nil
	elseif step == 12 then
		-- Greyvein (zone 2) bought — do not ack-skip past the portal.
		return math.max(1, tonumber(p.maxUnlockedZone) or 1) >= 2
	elseif step == 19 then
		return (tonumber(p.daily and p.daily.last) or 0) == utcDayIndex()
	elseif step == 20 then
		local pt = p.playtime
		return type(pt) == "table" and pt.day == utcDayIndex() and next(pt.got or {}) ~= nil
	elseif step == 21 then
		for _, d in pairs(p.deepest or {}) do
			if (tonumber(d) or 0) >= 30 then
				return true
			end
		end
	elseif step == 28 then
		return p.introCharmGot == true
	elseif step == 29 then
		return (tonumber(p.introGearOpened) or 0) >= 3
	elseif step == 31 then
		-- Wearing a hat in any of the three seats. (It used to ask whether a pet
		-- had one on, which nothing can satisfy now.)
		local eq = p.equippedGear or {}
		for _, s in ipairs(Gear.HAT_SLOTS or { "hat" }) do
			if type(eq[s]) == "string" and eq[s] ~= "" then
				return true
			end
		end
		return false
	elseif step == 33 then
		return (tonumber(p.introScrapped) or 0) >= 5
	elseif step == 36 then
		return (tonumber(p.introTemperRolls) or 0) >= 5
	elseif step == 37 then
		return (tonumber(p.prestige) or 0) >= 5
	end
	return false
end

-- One-shot starter grants so a forced step is never a locked door: gems for
-- the first summon, a pack if the bag is empty. Marked spent per step whether
-- or not anything was missing, so dumping gems cannot farm the top-up.
local function introGrant(plr, p)
	if not p then
		return
	end
	local step = math.floor(tonumber(p.intro) or 1)
	local d = Intro.steps[step]
	if not d then
		return
	end
	p.introGrants = p.introGrants or {}
	local key = tostring(step)
	if p.introGrants[key] then
		return
	end
	if d.grantGear or d.grantDust or d.bonusGems or (type(d.grantTokens) == "number") then
		p.introGrants[key] = true
		if d.grantGear then
			local def = Packs.PACK_BY_ID and Packs.PACK_BY_ID.gear_pack
			p.packs = p.packs or {}
			for _ = 1, math.floor(d.grantGear) do
				table.insert(p.packs, {
					packId = "gear_pack",
					packName = (def and def.name) or "Gear Crate",
					kind = "gear",
				})
			end
			net:FireClient(plr, "toast", "3 gear crates are in your bag")
		end
		if type(d.grantDust) == "number" and d.grantDust > 0 then
			p.dust = (p.dust or 0) + d.grantDust
			net:FireClient(plr, "toast", "+" .. d.grantDust .. " stardust")
		end
		if type(d.bonusGems) == "number" and d.bonusGems > 0 then
			p.gems = (p.gems or 0) + d.bonusGems
		end
		if type(d.grantTokens) == "number" and d.grantTokens > 0 then
			p.temperTokens = (p.temperTokens or 0) + d.grantTokens
			net:FireClient(plr, "toast", "+" .. d.grantTokens .. " temperament tokens")
		end
		markDirty(plr)
	end
	-- grantZone: enough for that zone's portal, whatever it costs today.
	local grantGems = d.grantGems
	-- "runeRoll": one summon at today's price for this player's zones.
	if grantGems == "runeRoll" then
		grantGems = Runes.rollPriceFor(p.maxUnlockedZone)
	end
	if d.grantZone and C.ZONES[d.grantZone] then
		grantGems = math.floor(tonumber(C.ZONES[d.grantZone].buyCost) or grantGems or 0)
	end
	if not (grantGems or d.grantPack or d.grantCoins) then
		return
	end
	p.introGrants[key] = true
	-- grantCoins "nextPick": enough for the cheapest meadow pickaxe they do not
	-- own yet, so the Blacksmith step always ends in the purchase it teaches
	-- (a player who sold after two clods has 30 coins, not a full bag).
	if d.grantCoins == "nextPick" then
		local okL, Ladders = pcall(require, shared:WaitForChild("MineShopLadders"))
		local price
		for _, row in ipairs((okL and Ladders.forDesk and Ladders.forDesk("meadow", "surface")) or {}) do
			if row.family == "pickaxe" and not (p.ownedShopTools or {})[row.id] then
				price = tonumber(row.price)
				break
			end
		end
		if price and (p.coins or 0) < price then
			p.coins = price
			net:FireClient(plr, "toast", "Starter coins: enough for your first real pickaxe")
		end
	end
	if grantGems and grantGems > 0 and (p.gems or 0) < grantGems then
		p.gems = grantGems
		net:FireClient(plr, "toast", "Starter gems: " .. grantGems)
	end
	if d.grantPack and #(p.packs or {}) == 0 then
		table.insert(p.packs, { setId = "dragons_dawn", packId = "loam_pack", packName = "Loam Pack" })
		net:FireClient(plr, "toast", "Starter pack added to your bag")
	end
	markDirty(plr)
end

local function introSend(plr, p)
	local step = math.floor(tonumber(p and p.intro) or 1)
	local d = Intro.steps[step]
	if p then
		introGrant(plr, p)
	end
	-- Already own a shop/coin pickaxe: do not force the blacksmith — CLAIM instead.
	local ack = (d and d.ack) == true
	local panel = d and d.panel
	local waypoint = d and d.waypoint
	local claimLabel = nil
	if step == 3 and ownsBetterPickaxe(p) then
		ack = true
		panel = nil
		waypoint = nil
		claimLabel = "Claim"
	end
	-- The length of the ladder, not the position of a step that is not on it.
	-- Intro.pos(35) fell through to #order + 1, so the bar topped out at 93%
	-- and the last lesson never read as finished.
	local tutLast = #Intro.order
	local at = Intro.pos(step)
	local inTut = p and step < Intro.done and at <= tutLast
	local progress, barLabel
	if inTut then
		progress = at / math.max(1, tutLast)
		barLabel = string.format("%d%% through the tutorial", math.floor(progress * 100 + 0.5))
		local have, need
		if step == 29 then
			have, need = p.introGearOpened or 0, 3
		elseif step == 33 then
			have, need = p.introScrapped or 0, 5
		end
		if need then
			barLabel = string.format("%s  ·  %d/%d", barLabel, have, need)
		end
	elseif p and step == 12 then
		local cost = math.floor(tonumber(C.ZONES[2] and C.ZONES[2].buyCost) or 0)
		local haveG = math.floor(tonumber(p.gems) or 0)
		progress = (cost > 0) and math.clamp(haveG / cost, 0, 1) or 0
		barLabel = string.format("%d / %d gems", haveG, cost)
	elseif p and step == 36 then
		local haveT = p.introTemperRolls or 0
		progress = math.clamp(haveT / 5, 0, 1)
		barLabel = string.format("%d / 5 temperament rolls", haveT)
	end
	net:FireClient(plr, "intro", {
		step = step,
		text = d and d.text,
		done = step >= Intro.done,
		ack = ack,
		claimLabel = claimLabel,
		panel = panel,
		tab = d and d.tab,
		highlight = d and d.highlight,
		requireAction = d and d.requireAction,
		waypoint = waypoint,
		count = d and d.count,
		pos = Intro.pos(step),
		total = #Intro.order,
		progress = progress,
		barLabel = barLabel,
		tutorial = inTut,
	})
end

-- Bump only from the step we expect, so a player who somehow sells before
-- mining does not skip the line that explains mining. Steps whose deed is
-- already done are skipped in the same breath.
local function introAdvance(plr, p, from)
	if not p then
		return
	end
	if (tonumber(p.intro) or 1) ~= from then
		return
	end
	-- Pinned to a literal 35 before, which is not on the ladder any more: the
	-- payout could never fire. Ask the order what the last step is instead.
	local lastStep = Intro.order[#Intro.order]
	if from == lastStep and not p.tutorialRewarded then
		p.tutorialRewarded = true
		p.gems = (p.gems or 0) + 1000
		p.packs = p.packs or {}
		local ZonePacks = require(shared:WaitForChild("MineZonePacks"))
		local packId = ZonePacks.id("meadow", "pack_legendary")
		local zpack = ZonePacks.get and ZonePacks.get(packId)
		for _ = 1, 3 do
			table.insert(p.packs, {
				packId = packId,
				packName = (zpack and zpack.name) or "Meadow Legendary Pack",
				zoneId = "meadow",
				setId = "dragons_dawn",
			})
		end
		net:FireClient(plr, "tutorialCelebrate")
		net:FireClient(plr, "toast", "Tutorial clear — 1,000 gems and 3 legendary packs")
	end
	local nextStep = Intro.nextAfter(from)
	while nextStep < Intro.done and introSatisfied(p, nextStep) do
		nextStep = Intro.nextAfter(nextStep)
	end
	p.intro = nextStep
	p.introStepChests = nil
	markDirty(plr)
	-- Onboarding funnel: joining is step 1 (Verbs.handleJoin), finishing the
	-- Nth step taught is step N + 1.
	pcall(function()
		local d = Intro.steps[from]
		local n = Intro.pos(from)
		game:GetService("AnalyticsService"):LogOnboardingStepEvent(plr, n + 1,
			string.format("Tutorial %d: %s", n, string.sub(tostring(d and d.text or ""), 1, 40)))
	end)
	introSend(plr, p)
end

--[[
	Merge one-shot. The FIRST time a profile holds three cards that can merge
	(same identity, rarity and variant), say so once and route the player at
	the merge flow. Never during Phase A/B of the tutorial, never twice —
	p.mergePromptShown is the forever-flag, set even on dismiss.
]]
local function maybeMergePrompt(plr, p)
	if not p or p.mergePromptShown then
		return
	end
	if Intro.pos(p.intro) <= Intro.pos(22) then
		return
	end
	local counts = {}
	for _, c in ipairs(p.cards or {}) do
		local key = tostring(c.cardKey) .. "|" .. tostring(c.rarityId) .. "|" .. tostring(c.variant or "Normal")
		local n = (counts[key] or 0) + 1
		counts[key] = n
		if n >= 3 then
			p.mergePromptShown = true
			markDirty(plr)
			net:FireClient(plr, "mergeReady", {
				text = "Three of a kind! Merge them into a stronger card.",
			})
			return
		end
	end
end



local function walk(plr)
	local p = profiles[plr.UserId]
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum and p then -- 16 is Roblox's default and far too slow for a lobby this size.
		local spd = (C.BASE_WALK_SPEED / (C.WALK_PACE or 1)) * boosts(p).walkSpeed
		hum.WalkSpeed = spd
	end
end

--[[
	Wear equipped hats/faces on the avatar. Catalog accessories via InsertService;
	faces prefer HumanoidDescription.Face when the asset is a Face.
]]
local function applyPlayerCosmetics(plr)
	local p = profiles[plr.UserId]
	local char = plr.Character
	if not (p and char) then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local head = char:FindFirstChild("Head")
	for _, ch in ipairs(char:GetChildren()) do
		if ch:GetAttribute("MineCosmetic") then
			ch:Destroy()
		end
	end
	local function wearCatalog(catalogId, tag)
		catalogId = tonumber(catalogId)
		if not catalogId then
			return
		end
		task.spawn(function()
			local ok, assets = pcall(function()
				return game:GetService("InsertService"):LoadAsset(catalogId)
			end)
			if not (ok and assets and char.Parent) then
				if assets then assets:Destroy() end
				return
			end
			local acc = assets:FindFirstChildWhichIsA("Accessory", true)
			if acc and hum and hum.Parent then
				local clone = acc:Clone()
				clone:SetAttribute("MineCosmetic", true)
				clone.Name = tag or "MineHat"
				pcall(function()
					hum:AddAccessory(clone)
				end)
				if not clone.Parent then
					clone.Parent = char
				end
			end
			assets:Destroy()
		end)
	end
	local function pieceCatalog(gearId)
		local piece = gearById(p, gearId)
		return piece and tonumber(piece.catalogId) or nil
	end
	local eq = p.equippedGear or {}
	local faceId = pieceCatalog(eq.face)
	local hat1 = pieceCatalog(eq.hat)
	local hat2 = pieceCatalog(eq.hat2)
	-- Face via HumanoidDescription FIRST. ApplyDescription wipes accessories,
	-- so hats must be worn after the face sticks.
	local function wearHats()
		wearCatalog(hat1, "MineHat")
		wearCatalog(hat2, "MineHat2")
	end
	if faceId and hum then
		local applied = false
		pcall(function()
			local desc = hum:GetAppliedDescription()
			desc.Face = faceId
			hum:ApplyDescription(desc)
			applied = true
		end)
		if not applied then
			wearCatalog(faceId, "MineFace")
			wearHats()
		else
			task.delay(0.2, wearHats)
		end
	else
		wearHats()
	end
end

local function pitOrigin(zone)
	return C.zoneOrigin(zone)
end

-- Truthy placeholder so ensureZone will not retry a lobby cell, but blast
-- code that checks `part.Parent` will ignore it.
-- Const.VOXEL_SKIP on Const

local function keyOf(z, x, y, zz)
	return string.format("%s:%d:%d:%d", z, x, y, zz)
end

--[[
	x and z joined the signature because ore is a VEIN now, and a vein is a
	function of where the block is. See MineConfig.veinOreAt: there is no moment
	at which a vein could be grown outward into its neighbours, because the
	generator spawns one key at a time in dig order and a broken block comes back
	through here minutes later. Every block works out its own membership instead,
	and neighbours agree because they are asking the same question of the same
	lattice.
]]
local function rollKind(zone, x, layer, z, b, rng)
	-- There is no ore. What you hope to see in the wall is a chest, and which
	-- chest it is gets decided here so the block can look like that chest.
	local strata = C.strataFor(zone.id)
	-- Event Horizon (bigbang) only: 3× chest density for the limited event mine.
	-- Never multiply other zones — zone.chestMult must not leak globally.
	local chance = C.CHEST_CHANCE or 0.0025
	if zone.id == "bigbang" then
		chance = chance * (tonumber(zone.chestMult) or 3)
	elseif zone.id == "meadow" and (tonumber(layer) or 1) <= 100 then
		-- Onboarding density: the tutorial's three chests should be met by
		-- digging, not by a dry spell (MineConfig.MEADOW_SHALLOW_CHEST_MULT).
		chance = chance * (C.MEADOW_SHALLOW_CHEST_MULT or 1)
	end
	-- World Pulse chest density (clamped so walls don't become all chests).
	local pulseMult = (b and b.worldChestMult) or 1
	if pulseMult ~= 1 then
		chance = math.min(0.08, chance * pulseMult)
	end
	if rng:NextNumber() < chance then
		return "chest"
	end
	-- Lucky blocks are no longer placed in the mine like chests: every block of
	-- dirt you break rolls for one instead (see the break handler).
	--[[
		ORE.

		The note at the top of this function used to say there is no ore, and
		that was the problem: a chest was the only thing worth hoping for, so
		one loot table carried the whole game. Each ore states its own 1-in-N
		and MineConfig.rollOre sums the pool available at this depth.
	]]
	--[[
		Veins, not noise. veinOreAt spends exactly the budget rollOre used to --
		ORE_CHANCE per block, per ore, at every depth -- but spends it in clumps,
		so the expected ore count is unchanged and only its arrangement differs.
		It takes no rng for the same reason it takes x and z.
	]]
	if C.veinOreAt then
		if C.veinOreAt(zone.id, x, layer, z, b and b.rareOre) then
			return "ore"
		end
	elseif C.rollOre and C.rollOre(zone.id, layer, rng, b and b.rareOre) then
		return "ore"
	end
	return strata.rock
end

local function spawnVoxel(zone, x, y, z, kind, b)
	local key = keyOf(zone.id, x, y, z)
	voxels[zone.id] = voxels[zone.id] or {}
	if voxels[zone.id][key] then return voxels[zone.id][key] end
	local size, grid = C.BLOCK, C.GRID
	local off = (grid - 1) * 0.5
	local pos = pitOrigin(zone) + Vector3.new((x - off) * size, -y * size - size * 0.5, (z - off) * size)
	if C.blockOverlapsLobby and C.blockOverlapsLobby(pos, size * 0.5) then
		voxels[zone.id][key] = Const.VOXEL_SKIP
		return nil
	end
	-- A chest block is a specific chest. Which one is decided at spawn so the
	-- block can be coloured like it and named when you look at it.
	-- Identity is re-rolled here from a fresh Random, the same two-step chests
	-- use. oreIdentity picks WHICH ore without re-rolling whether it is one --
	-- rollKind already decided that.
	local oreDef
	if kind == "ore" then
		--[[
			THE IDENTITY COMES FROM THE VEIN, NOT FROM A SECOND ROLL.

			This used to re-roll with oreIdentity(Random.new()), which is why ore
			could never form a seam even by accident: rollKind said "ore here" and
			then this picked a DIFFERENT ore for every block, so four touching ore
			blocks were four unrelated minerals.

			veinOreAt is a pure function of position, so asking it again here
			returns the same ore rollKind already matched -- the vein's ore, for
			every block in it. The finder still shifts WHICH ore, because it is
			part of the lattice key; see MineConfig.oreFindShift.
		]]
		if C.veinOreAt then
			oreDef = C.veinOreAt(zone.id, x, y, z, b and b.rareOre)
		end
		if not oreDef and C.oreIdentity then
			oreDef = C.oreIdentity(zone.id, y, Random.new(), b and b.rareOre)
		end
	end
	local luckyId
	if kind == "lucky_block" then
		luckyId = LuckyBlocks.rollPitId(Random.new())
	end
	local chestDef
	if kind == "chest" then
		local ZoneChests = require(shared:WaitForChild("MineZoneChests"))
		chestDef = ZoneChests.rollSpawn(zone.id, y, (C.zoneIndex and C.zoneIndex(zone.id)) or 1)
	end
	local part = Instance.new("Part")
	part.Name = "MineBlock"
	part.Anchored = true
	part.Size = Vector3.new(size, size, size)
	part.CFrame = CFrame.new(pos)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	--[[
		THE MINE IS THOUSANDS OF PARTS, SO EVERY PER-PART COST IS MULTIPLIED BY
		THOUSANDS.

		Owner, 2026-10-06, with the microprofiler open: GPU averages ~50 ms while
		MOVING and spikes to 80, against a 33 ms target, on a 5070 Ti. Measured
		live, the mine holds about 4,900 parts.

		CastShadow was never set, so every one of them cast a shadow. Shadow maps
		are re-rendered as the camera moves, which is exactly the "when I move"
		shape of the spike, and underground there is no sun to cast them from --
		the cost bought nothing. The rest of this codebase already knows this:
		chests, pets and portal FX all set CastShadow = false.

		CanTouch was also left on, so all 4,900 took part in touch resolution as
		the character walked through the shaft. The only Touched handler in the
		game is on the sell pad (Machine == "sell"), so blocks never needed it.

		CanQuery STAYS TRUE. Mining is a raycast against these parts; turning it
		off would make the mine unclickable.
	]]
	part.CastShadow = false
	part.CanTouch = false
	-- Fallback for an unrecognised kind. Was C.BLOCKS.fossil, which no longer
	-- exists; dirt is the plain rock every zone already starts from.
	local spec = C.BLOCKS[kind] or C.BLOCKS.dirt
	local lucky = (C.isLuckyLayer and C.isLuckyLayer(zone.id, y)) or false
	local section = (zone.id == "meadow" and C.sectionFor) and C.sectionFor(y) or nil
	-- A zone with strata of its own (MineConfig.ZONE_SECTIONS) paints its rock by depth.
	local strata = (not section and C.zoneSectionFor and kind ~= "chest" and kind ~= "core" and kind ~= "lucky_block") and C.zoneSectionFor(zone.id, y) or nil
	if kind == "lucky_block" and luckyId then
		local ldef = LuckyBlocks.def(luckyId)
		part.Color = (ldef and ldef.color) or Color3.fromRGB(255, 196, 64)
		part.Material = Enum.Material.Neon
		part:SetAttribute("LuckyBlockId", luckyId)
	elseif kind == "ore" and oreDef then
		--[==[
			The ore lives in the face art now, so the block itself is rock.

			It used to be a solid cube of the ore's own colour, which is why the
			ore roster read as a wall of coloured cubes -- a Cobalt vein and a Niobium one
			were the same blue box. Each ore now wears one of thirty hand-drawn
			faces (MineConfig.ORE_FACE), and the part underneath takes the
			zone's own rock, darkened, so the ore reads as sitting IN the wall
			rather than replacing a chunk of it. The CLIENT hangs the face on it;
			an EditableImage does not replicate, so it has to be built where it
			is drawn.
		]==]
		local rock = (zone and zone.dirt) or Color3.fromRGB(96, 92, 88)
		part.Color = Color3.new(rock.R * 0.7, rock.G * 0.7, rock.B * 0.7)
		--[[
			A PLAIN ORE IS JUST ITS OWN BLOCK. Owner: "make the stone ore, just
			a grey block".

			The darkened host and the SmoothPlastic below exist to give pixel
			art a flat surface to itself. An ore in C.ORE_PLAIN gets no art at
			all -- MineOreFace reads the same list -- so that reasoning
			inverts: it should wear its own colour and its own material, which
			for Stone is plain grey Rock.

			Only the two art-host lines are skipped. Everything after this
			branch -- OreId, HP, the attributes the client and the dig path
			read -- still runs, because a plain ore is a normal ore in every
			way except how it is painted.
		]]
		local plain = (C.ORE_PLAIN and C.ORE_PLAIN[oreDef.id]) and true or false
		if plain then
			part.Color = oreDef.color or part.Color
		end
		--[[
			SmoothPlastic on purpose: flat, textureless, no surface detail.

			Roblox's stone materials carry their own grain, and that grain reads
			at roughly the same scale as the ore pixels sitting on top of it --
			two competing textures on one face, and the art loses. A flat host
			gives the pixel art the whole surface to itself, which is why every
			game that draws ore this way keeps the block underneath plain.
		]]
		part.Material = plain and (oreDef.material or Enum.Material.Rock)
			or Enum.Material.SmoothPlastic
		part:SetAttribute("OreId", oreDef.id)
		part:SetAttribute("OreName", oreDef.name)
		part:SetAttribute("OreTier", oreDef.tier)
		--[==[
			Name the ore on the block itself.

			The server has always stamped OreId / OreName / OreTier onto the
			part and nothing has ever read them -- the client has no ore
			awareness at all. So every ore shares one palette and, in the wall,
			a Cobalt vein and a Niobium one are the same blue cube. Colour
			cannot carry identity at this roster size; the name has to.

			MaxDistance keeps it on the block you are standing at instead of
			papering the whole shaft with floating text, and the tier line is
			tinted the ore's own colour so the two read as one object.
		]==]
		local tag = Instance.new("BillboardGui")
		tag.Name = "OreTag"
		tag.Size = UDim2.fromOffset(150, 34)
		tag.StudsOffsetWorldSpace = Vector3.new(0, size * 0.75, 0)
		tag.MaxDistance = 42
		tag.Parent = part
		local nameLbl = Instance.new("TextLabel")
		nameLbl.BackgroundTransparency = 1
		nameLbl.Size = UDim2.new(1, 0, 0, 20)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 15
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.TextStrokeTransparency = 0.35
		nameLbl.Text = tostring(oreDef.name)
		nameLbl.Parent = tag
		local tierLbl = Instance.new("TextLabel")
		tierLbl.BackgroundTransparency = 1
		tierLbl.Position = UDim2.fromOffset(0, 19)
		tierLbl.Size = UDim2.new(1, 0, 0, 14)
		tierLbl.Font = Enum.Font.Gotham
		tierLbl.TextSize = 11
		tierLbl.TextColor3 = oreDef.color
		tierLbl.TextStrokeTransparency = 0.5
		tierLbl.Text = "tier " .. tostring(oreDef.tier)
		tierLbl.Parent = tag
		if oreDef.glow then
			--[[
				Glowing ore lights the shaft it sits in.

				Colour and brightness are the generator's own LOOKS values, so a
				vein in the wall and the tool eventually made from it read as the
				same material. Range follows brightness -- Uranium at 1.2 should
				be visible from further off than Charcoal at 0.3.
			]]
			local bright = tonumber(oreDef.glowBright) or 1
			local light = Instance.new("PointLight")
			light.Color = oreDef.glow
			light.Brightness = bright
			light.Range = 8 + bright * 5
			light.Shadows = false
			light.Parent = part
			if oreDef.rainbow then
				--[[
					Oganesson: void-black rock, glow cycling the spectrum.

					One coroutine per block rather than a registry and a central
					tick, because at 1 in 690,000 a server may never see two at
					once. It ends itself when the block is mined -- light.Parent
					goes nil and the loop falls out.
				]]
				part:SetAttribute("OreRainbow", true)
				task.spawn(function()
					local hue = 0
					while light.Parent do
						hue = (hue + 0.012) % 1
						light.Color = Color3.fromHSV(hue, 0.8, 1)
						task.wait(0.05)
					end
				end)
			end
		end
	elseif section and (kind == "dirt" or (spec and spec.name == "Dirt")) then
		part.Color = section.color
	elseif strata then
		part.Color = strata.color
	elseif kind == "dirt" then
		part.Color = zone.dirt or spec.color
	else
		part.Color = spec.color
	end
	if kind ~= "lucky_block" and kind ~= "ore" then
		part.Material = (strata and strata.material) or spec.material
	end
	-- A lucky seam reads as one solid band from across the shaft. Chests and
	-- lucky blocks keep their own look so they stay findable in it.
	if lucky and kind ~= "chest"
		and kind ~= "lucky_block" and kind ~= "core" and kind ~= "ore" then
		part.Color = C.LUCKY_LAYER_COLOR or Color3.fromRGB(255, 214, 92)
		part.Material = Enum.Material.Neon
	end
	part:SetAttribute("ZoneId", zone.id)
	part:SetAttribute("CX", x)
	part:SetAttribute("CY", y)
	part:SetAttribute("CZ", z)
	part:SetAttribute("Kind", kind)
	if section or strata then
		part:SetAttribute("SectionId", (section or strata).id)
		part:SetAttribute("SectionName", (section or strata).name)
	end
	if chestDef then
		-- A chest looks like the chest it is. Colour is the only tell you get
		-- from across a shaft, so the four kinds have to be distinct.
		part:SetAttribute("ChestType", chestDef.id)
		part:SetAttribute("ChestName", chestDef.name)
		if chestDef.roman then
			part:SetAttribute("SectionRoman", chestDef.roman)
			part:SetAttribute("SectionArabic", chestDef.arabic or tostring(chestDef.sectionN or ""))
			part:SetAttribute("SectionN", chestDef.sectionN)
		end
		local look = C.CHEST_LOOK[chestDef.kind] or C.CHEST_LOOK.native
		part.Color = look.color
		part.Material = look.material
		-- An actual chest, built into the block. Guarded on principle:
		-- decoration must never be able to stop a block existing.
		if ChestModel and ChestModel.build then
			pcall(ChestModel.build, part, chestDef.kind, part.Size.X)
		end
	end
	-- Meadow + Event Horizon: HP from the section ladder (dirtHp). Other mines
	-- keep BLOCKS.hp. Never fall back to the old 2.5^tier depth curve.
	local maxHp
	if kind == "chest" and chestDef and C.chestHp then
		maxHp = C.chestHp(y, chestDef)
	elseif kind == "lucky_block" and C.chestHp then
		maxHp = C.chestHp(y)
	elseif kind == "ore" then
		--[[
			Per ORE, not a flat multiple. This was
			blockHp("dirt") * ORE_HP_MULT with ORE_HP_MULT = 3, so a Stone
			block and an Oganesson block at the same layer took the same
			number of swings -- the only thing that ever varied was the dirt
			curve underneath, which describes the LAYER and not what is in it.

			C.oreBlockHp is hardness x the same dirt curve, so the layer term
			is unchanged and only the ore's own base moves. Falls back to the
			old flat multiple when the ore is unknown, which keeps a block
			breakable rather than giving it 1 HP.
		]]
		maxHp = oreDef and C.oreBlockHp and C.oreBlockHp(oreDef, zone, y)
			or math.floor(C.blockHp("dirt", zone, y) * (C.ORE_HP_MULT or 3))
	else
		maxHp = C.blockHp(kind, zone, y)
	end
	if lucky then
		maxHp = math.max(1, math.floor(maxHp * (C.LUCKY_LAYER_HP_MULT or 10) + 0.5))
		part:SetAttribute("LuckyLayer", true)
	end
	part:SetAttribute("HP", maxHp)
	part:SetAttribute("MaxHP", maxHp)
	if zone and zone.id == "bigbang" then
		part:SetAttribute("Matter", "space")
		part:SetAttribute("SpaceHP", maxHp)
		part:SetAttribute("SpaceMax", maxHp)
	end
	local blockName = spec.name or kind
	if chestDef then
		blockName = chestDef.name
	elseif luckyId then
		local ldef = LuckyBlocks.def(luckyId)
		blockName = (ldef and ldef.name) or "Lucky Block"
	elseif section and kind ~= "chest" then
		blockName = section.name
	elseif strata then
		blockName = strata.name
	end
	part:SetAttribute("BlockName", blockName)
	Svc.Collection:AddTag(part, "MineVoxel")
	local folder = workspace.MineWorld.Pits:FindFirstChild("Vox_" .. zone.id)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Vox_" .. zone.id
		folder.Parent = workspace.MineWorld.Pits
	end
	part.Parent = folder
	voxels[zone.id][key] = part
	return part
end

-- Layers are built in a window rather than all at once. At 50 layers a whole
-- zone is 8,450 parts; generating that synchronously on zone entry stalls the
-- server. We build down to `throughLayer` and remember how far we got.
local builtTo = {}
local coreRiftsBound = {}

-- Const.GROUND_Y on Const

local function openCoreRift(plr, zoneId)
	local p = profiles[plr.UserId]
	if not p then return end
	p.coreSamples = p.coreSamples or {}
	if not p.coreSamples[zoneId] then
		net:FireClient(plr, "toast", "you must collect a sample of the core")
		return
	end
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	local folder = pits and pits:FindFirstChild("CoreRift_" .. zoneId)
	local hole = folder and folder:FindFirstChild("Blackhole")
	if hole then
		tp(plr, hole.CFrame)
	end
	p.coreRiftOpened = p.coreRiftOpened or {}
	if not p.coreRiftOpened[zoneId] then
		p.coreRiftOpened[zoneId] = true
		net:FireClient(plr, "toast", "Core rift opened")
		markDirty(plr)
	else
		net:FireClient(plr, "toast", "You step into the core rift")
	end
end

local function maybeGrantCoreSample(plr, p, zone, kind)
	if kind ~= "core" or not zone then return end
	p.coreSamples = p.coreSamples or {}
	if p.coreSamples[zone.id] then return end
	p.coreSamples[zone.id] = true
	net:FireClient(plr, "toast", "Collected a sample of the core")
	markDirty(plr)
end

local function ensureCoreBottom(zone)
	local maxLayers = (C.zoneLayers and C.zoneLayers(zone)) or C.LAYERS
	local mid = math.floor(C.GRID / 2)
	voxels[zone.id] = voxels[zone.id] or {}
	for dx = -1, 1 do
		for dz = -1, 1 do
			local fx, fz = mid + dx, mid + dz
			local key = keyOf(zone.id, fx, maxLayers, fz)
			local existing = voxels[zone.id][key]
			if typeof(existing) == "Instance" then
				if existing:GetAttribute("Kind") == "core" then
					continue
				end
				existing:Destroy()
				voxels[zone.id][key] = nil
			elseif existing then
				voxels[zone.id][key] = nil
			end
			spawnVoxel(zone, fx, maxLayers, fz, "core")
		end
	end
end

local function ensureCoreRift(zone)
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	if not pits then return end
	local name = "CoreRift_" .. zone.id
	if coreRiftsBound[zone.id] and pits:FindFirstChild(name) then
		return
	end
	local old = pits:FindFirstChild(name)
	if old then old:Destroy() end
	local maxLayers = (C.zoneLayers and C.zoneLayers(zone)) or C.LAYERS
	local size = C.BLOCK
	local origin = pitOrigin(zone)
	local coreY = origin.Y - maxLayers * size - size * 0.5
	local platY = coreY - size * 1.35

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = pits

	-- Wide platform under the core so the rift reads as a destination.
	local plat = Instance.new("Part")
	plat.Name = "CorePlatform"
	plat.Anchored = true
	plat.Size = Vector3.new(size * 9, size * 0.45, size * 9)
	plat.CFrame = CFrame.new(origin.X, platY, origin.Z)
	plat.Color = Color3.fromRGB(22, 18, 28)
	plat.Material = Enum.Material.Basalt
	plat.TopSurface = Enum.SurfaceType.Smooth
	plat.BottomSurface = Enum.SurfaceType.Smooth
	plat.Parent = folder

	-- Dark well in the middle of the platform.
	local well = Instance.new("Part")
	well.Name = "RiftWell"
	well.Anchored = true
	well.CanCollide = false
	well.Size = Vector3.new(size * 3.2, size * 0.5, size * 3.2)
	well.CFrame = CFrame.new(origin.X, platY + size * 0.15, origin.Z)
	well.Color = Color3.fromRGB(4, 2, 8)
	well.Material = Enum.Material.Neon
	well.Parent = folder

	local hole = Instance.new("Part")
	hole.Name = "Blackhole"
	hole.Shape = Enum.PartType.Ball
	hole.Anchored = true
	hole.CanCollide = false
	hole.Size = Vector3.new(size * 2.6, size * 2.6, size * 2.6)
	hole.CFrame = CFrame.new(origin.X, platY + size * 1.4, origin.Z)
	hole.Color = Color3.fromRGB(0, 0, 0)
	hole.Material = Enum.Material.Neon
	hole:SetAttribute("Machine", "coreRift")
	hole:SetAttribute("ZoneId", zone.id)
	hole.Parent = folder

	local light = Instance.new("PointLight")
	light.Brightness = 1.6
	light.Range = 22
	light.Color = Color3.fromRGB(90, 40, 140)
	light.Parent = hole

	local bb = Instance.new("BillboardGui")
	bb.Name = "RiftLabel"
	bb.Size = UDim2.fromOffset(180, 42)
	bb.StudsOffset = Vector3.new(0, size * 2.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = hole
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(210, 190, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = "CORE RIFT"
	label.Parent = bb

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.ObjectText = "Core Rift"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = hole
	prompt.Triggered:Connect(function(plr)
		openCoreRift(plr, zone.id)
	end)
	coreRiftsBound[zone.id] = true
end

local function syncPitWalls(zone)
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	if not pits then
		return
	end
	local depth = math.max(builtTo[zone.id] or 0, C.LAYER_WINDOW or 8)
	local pitW = C.GRID * C.BLOCK
	local wallT = 4
	-- Match WorldBuilder: walls line the INSIDE of the mouth, tops below the
	-- Ground_* underside, so rim plates and shaft rock never share a plane.
	local wallH = depth * C.BLOCK + 8
	local wallTop = Const.GROUND_Y - 2.05
	local wallY = wallTop - wallH * 0.5
	local inset = (pitW - wallT) * 0.5
	local origin = pitOrigin(zone)
	local rock = (zone.dirt or Color3.fromRGB(96, 90, 84)):Lerp(Color3.fromRGB(24, 22, 26), 0.55)
	local specs = {
		{ "N", Vector3.new(pitW, wallH, wallT), Vector3.new(0, 0, inset) },
		{ "S", Vector3.new(pitW, wallH, wallT), Vector3.new(0, 0, -inset) },
		{ "E", Vector3.new(wallT, wallH, pitW - wallT * 2), Vector3.new(inset, 0, 0) },
		{ "W", Vector3.new(wallT, wallH, pitW - wallT * 2), Vector3.new(-inset, 0, 0) },
	}
	for _, w in ipairs(specs) do
		local name = "PitWall" .. w[1] .. "_" .. zone.id
		local wall = pits:FindFirstChild(name) or pits:FindFirstChild("PitWall_" .. zone.id)
		if not wall then
			wall = Instance.new("Part")
			wall.Name = name
			wall.Anchored = true
			wall.Material = Enum.Material.Rock
			wall.TopSurface = Enum.SurfaceType.Smooth
			wall.BottomSurface = Enum.SurfaceType.Smooth
			wall.Parent = pits
		end
		wall.Name = name
		wall.Size = w[2]
		wall.Color = rock
		wall.CFrame = CFrame.new(origin.X + w[3].X, wallY, origin.Z + w[3].Z)
	end
	local floor = pits:FindFirstChild("PitFloor_" .. zone.id)
	if floor then
		floor:Destroy()
	end
end

local function ensureZone(zone, throughLayer)
	voxels[zone.id] = voxels[zone.id] or {}
	local maxLayers = (C.zoneLayers and C.zoneLayers(zone)) or C.LAYERS
	-- Mine For Cards: meadow/mine1 uncapped past 2500. Shallow islands stay capped.
	local uncapped = zone.id == "meadow" or (tonumber(maxLayers) or 0) >= (C.MINE1_LAYERS or 2500)
	local want = math.max(1, math.floor(throughLayer or (C.LAYER_WINDOW or 8)))
	local target = uncapped and want or math.clamp(want, 1, maxLayers)
	--[[
		ONE CHUNK AT A TIME, AND NEVER BELOW THE OPEN ONE.

		Every caller asks for `deepest + LAYER_WINDOW`, which is the right ask for
		a player walking down and the wrong one for everything else: nothing
		stopped the mine existing below what anyone had earned. Clamping here
		rather than at the five call sites because this is the only place that
		turns a request into rock, so a new caller cannot forget it.

		The ceiling moves only when someone reaches a chunk floor, which is the
		owner's rule: chunk two does not exist until the bottom of chunk one has
		been mined. canCreditDepth refuses the depth; this refuses the rock.
	]]
	target = math.min(target, Dig.Auth.chunkCeiling(Dig.Auth.deepestReachedAcross(profiles, zone.id)))
	local from = (builtTo[zone.id] or 0) + 1
	if from > target then
		syncPitWalls(zone)
		return
	end
	--[[
		GENERATION IS CHUNKED, AND NEVER LEAVES A HOLE.

		This used to build every layer from builtTo+1 to target, 441 blocks
		each. Riding to a depth plaza calls ensureZone(zone, seam + window), so
		arriving at seam 2500 on a server that had built 8 layers asked for
		2,508 layers -- about 1.1 MILLION parts. task.wait() every 400 keeps it
		from hanging outright; it just grinds for minutes while the player
		stands in nothing. That is what "the zone doesn't load in" really was.

		Two different asks arrive here and they need different answers:

		  DIGGING DOWN -- target is just below the frontier. Extend the frontier
		  by one chunk and advance builtTo. Contiguous, so no layer is skipped.
		  Breaking a block asks again, which cuts the next chunk.

		  ARRIVING DEEP -- target is hundreds of layers below the frontier
		  (elevator, plaza ride). Build one chunk AT the target and leave the
		  layers above alone for whoever digs through them. builtTo is NOT
		  advanced, because those layers genuinely are not built.

		An earlier version of this clamped `from` in both cases, which on a
		plain startup call (target 8, frontier 0) built layers 5-8 and left 1-4
		missing -- a hole in the top of the mine.
	]]
	local band = math.max(1, Const.ENSURE_BAND)
	local far = (target - from) >= Const.ENSURE_FAR
	if far then
		from = math.max(1, target - band + 1)
	else
		target = math.min(target, from + band - 1)
		builtTo[zone.id] = target
	end
	--[[
		A new layout every refresh, on the same layers.

		This seed was zone.angle * 997 + 13 + from -- nothing in it ever
		changes, so every refresh, on every server, in every session, put the
		chests in exactly the same blocks, and a player who noticed could walk
		straight to them. What this roll decides is only WHERE the chests sit
		(and which meadow layers carry fossils): the rock, the section names and
		the depth-scaled HP all come from the layer number and stay as they are.

		The salt is picked once per zone and re-picked by resetMineZone, so a
		layout holds still while you dig through it and changes when the mine
		refreshes. Kept on mineResetState rather than in a new top-level local;
		this script is near Luau's 200-register ceiling.
	]]
	mineResetState.seed = mineResetState.seed or {}
	local salt = mineResetState.seed[zone.id]
	if not salt then
		salt = Random.new():NextInteger(1, 1073741823)
		mineResetState.seed[zone.id] = salt
	end
	--[[
		The ore field needs this salt too, or it is the same mine forever.

		`rng` below only decides where the CHESTS go. Ore moved to
		MineConfig.veinOreAt, which is positional by design -- that is what lets a
		vein agree with itself across blocks spawned minutes apart -- and until
		now the only thing seeding it was a hash of the zone's name. Owner,
		2026-10-06: "every time i join 4 halite on top of the line".
	]]
	if C.setVeinSalt then
		C.setVeinSalt(zone.id, salt)
	end
	local rng = Random.new(salt + from)
	local made = 0
	local Depth = Dig.Depth
	for y = from, target do
		if Depth.isAirGap and Depth.isAirGap(y) then
			for x = 0, C.GRID - 1 do
				for z = 0, C.GRID - 1 do
					local key = keyOf(zone.id, x, y, z)
					if not voxels[zone.id][key] then
						voxels[zone.id][key] = Const.VOXEL_SKIP
					end
				end
			end
		else
			for x = 0, C.GRID - 1 do
				for z = 0, C.GRID - 1 do
					if not voxels[zone.id][keyOf(zone.id, x, y, z)] then
						spawnVoxel(zone, x, y, z, rollKind(zone, x, y, z, { luck = 1, rareOre = 1 }, rng), { rareOre = 1 })
						made += 1
						if made % 400 == 0 then task.wait() end
					end
				end
			end
			--[[
				FOSSILS ARE GONE. Nothing spawns a fossil block any more.

				A fossil block used to land on one layer in ten and pay a pack of
				pieces that assembled into a forever tool. The whole line is
				retired: the build is CHARMS and SKINS now, and a third
				forever-tool source competing with them was the reason neither
				felt like the point.

				Deliberately not replaced with anything. The layer keeps the ore
				and chests it already rolled; nothing is put back in the hole.
			]]
		end
		-- Core-at-maxLayers wall retired for Mine For Cards uncapped mines.
	end
	-- Meadow starter chest: first dig window always has at least one chest near
	-- the pit centre so new players see the glow without a multi-minute dry spell.
	-- Mirrors the fossil inject above (replace a rock, never overwrite specials).
	-- Tagged IntroChest + PackQty=3 so the tutorial waypoint can find it and the
	-- first break always drops three packs.
	if zone.id == "meadow" and from == 1 then
		local function stampIntroChest(part)
			if typeof(part) == "Instance" then
				part:SetAttribute("IntroChest", true)
				part:SetAttribute("PackQty", 3)
			end
			return part
		end
		local hasChest = false
		local scanTo = math.min(3, target)
		for y = 1, scanTo do
			for x = 0, C.GRID - 1 do
				for z = 0, C.GRID - 1 do
					local existing = voxels[zone.id][keyOf(zone.id, x, y, z)]
					if typeof(existing) == "Instance" and existing:GetAttribute("Kind") == "chest" then
						stampIntroChest(existing)
						hasChest = true
						break
					end
				end
				if hasChest then break end
			end
			if hasChest then break end
		end
		if not hasChest then
			local cx = math.floor((C.GRID - 1) * 0.5)
			local cz = math.floor((C.GRID - 1) * 0.5)
			-- Prefer layer 2 (layer 1 can overlap lobby skip); nudge toward +Z pit walk-in.
			local cands = {
				{ 2, cx, cz }, { 2, cx, cz + 2 }, { 1, cx, cz }, { 3, cx, cz }, { 2, cx + 1, cz },
			}
			for _, cand in ipairs(cands) do
				local y, x, z = cand[1], cand[2], cand[3]
				if y <= target and x >= 0 and x < C.GRID and z >= 0 and z < C.GRID then
					local key = keyOf(zone.id, x, y, z)
					local existing = voxels[zone.id][key]
					if typeof(existing) == "Instance" then
						local k = existing:GetAttribute("Kind")
						if k ~= "chest" and k ~= "core" then
							existing:Destroy()
							voxels[zone.id][key] = nil
							stampIntroChest(spawnVoxel(zone, x, y, z, "chest"))
							break
						end
					elseif not existing then
						stampIntroChest(spawnVoxel(zone, x, y, z, "chest"))
						break
					end
				end
			end
		end
	end
	--[[
		The far path must NOT advance the frontier, and used to.

		The block comment above says so already -- "builtTo is NOT advanced,
		because those layers genuinely are not built" -- but this line read
		`max(builtTo, target)` unconditionally, so arriving at seam 2500 with a
		frontier of 3 built layers 2506-2508 and then claimed 2508. Every later
		call starts at builtTo+1, so layers 4-2505 could never be built by
		anything: ride back up and you are standing in a void that no amount of
		digging fills. Only the near path, which is contiguous with the frontier,
		may move it.
	]]
	if not far then
		-- keep max in case of concurrent raises
		builtTo[zone.id] = math.max(builtTo[zone.id] or 0, target)
	end
	syncPitWalls(zone)
end

local function tp(plr, cf)
	pcall(function()
		Dig.Auth.allowTpUser(plr.UserId, 2.5)
	end)
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if root then root.CFrame = cf + Vector3.new(0, 3, 0) end
end

-- Digging is gated the same way portals are: limited Event Horizon after the
-- first free claim (bigbangOwned), everything else only up to maxUnlockedZone.
-- Stops exploiters who teleport into a top-zone pit and swing.
-- One table (not two locals) to stay under Luau's 200-register main-chunk cap.
local Gate = {}

function Gate.zoneUnlocked(p, zone)
	if not p or not zone then
		return false
	end
	if zone.limited then
		return p.bigbangOwned == true
	end
	local idx = 1
	for i, z in ipairs(C.ZONES) do
		if z.id == zone.id then
			idx = i
			break
		end
	end
	return idx <= math.max(1, tonumber(p.maxUnlockedZone) or 1)
end

function Gate.canMine(plr, part)
	if not part then
		return false
	end
	if part:GetAttribute("AfkBlock") then
		return true
	end
	local p = profiles[plr.UserId]
	if not p then
		return false
	end
	local zone = C.zoneById(part:GetAttribute("ZoneId"))
	if not zone then
		return false
	end
	return Gate.zoneUnlocked(p, zone)
end

local function enterZone(plr, zoneId)
	local p = profiles[plr.UserId]
	local zone = C.zoneById(zoneId)
	if not zone then return "Unknown zone" end
	local idx = 1
	for i, z in ipairs(C.ZONES) do
		if z.id == zone.id then idx = i end
	end
	if zone.limited then
		if not (C.limitedActive and C.limitedActive()) and not p.bigbangOwned then
			return zone.name .. " event has ended"
		end
		if not p.bigbangOwned then
			-- Free claim while the limited window is live.
			p.bigbangOwned = true
			p.wormholeBag = true
			p.eventTools = p.eventTools or {}
			p.eventTools.eh_shallow_pick = true
			p.eventToolId = p.eventToolId or "eh_shallow_pick"
			net:FireClient(plr, "toast", "Wormhole Bag unlocked — best haul in the game")
			markDirty(plr)
		end
	elseif idx > math.max(1, tonumber(p.maxUnlockedZone) or 1) then
		local cost = zone.buyCost or 0
		local needR = zone.minRebirth or 0
		if needR > 0 and (p.prestige or 0) < needR then
			return string.format("Need Rebirth %d to buy %s", needR, zone.name)
		end
		return string.format("Buy %s for %s gems", zone.name, tostring(cost))
	end
	p.zoneId = zone.id
	require(game.ServerScriptService.Mine.MineEventHorizon).setLowGravity(plr, zone.id == "bigbang")
	ensureZone(zone, math.max((p.deepest[zone.id] or 0), Dig.Auth.depthPassOf(p, zone.id)) + (C.LAYER_WINDOW or 8))
	tp(plr, surfaceCf(zone))
	MineBadges.onEnterZone(plr, zone.id)
	snap(plr)
end
-- Which chest a chest-block turns out to be is decided HERE, at break time,
-- using this player's boosts -- that is what lets the luck stat matter. If the
-- variety were baked in when the block spawned, luck would have nothing to act
-- on and two players breaking the same block would get identical results.
local function zoneTierOf(zone)
	for i, z in ipairs(C.ZONES) do
		if z.id == zone.id then return i end
	end
	return 1
end

-- What a broken chest actually yields. Usually packs -- a run of them, which
-- can be none -- sometimes coins, a hat often enough to chase sets, a charm
-- rarely, and a relic almost never. No gems: those are minted from scrap ore
-- now. Luck shifts weight onto the rows worth having AND lengthens the run.
local function rollChestLoot(p, kind, chest, tier, layer, zone, b, luck)
	local rng = Random.new()
	local rows = C.CHEST_LOOT
	local total, weights = 0, {}
	for i, row in ipairs(rows) do
		-- A crate is the lesser find, so its rare rows are thinner.
		local w = row.weight
		if row.lucky then
			w = w * luck * (kind == "crate" and 0.45 or 1)
		end
		weights[i] = w
		total += w
	end
	local pick = rng:NextNumber() * total
	local chosen = rows[1]
	for i, row in ipairs(rows) do
		pick -= weights[i]
		if pick <= 0 then chosen = row break end
	end

	-- Scale the currency rows off the blocks the chest was buried in, so a
	-- zone-6 chest never pays zone-1 money and nothing needs re-tuning when a
	-- zone is added. A chest is meant to feel like a seam, not like a block.
	--[[
		CRASHED until 2026-10-05. This read
		`C.coinsFor("dirt", zone, layer)`, but coinsFor's signature is
		(kind, mult) and it evaluates `base * mult` -- and `zone` here is the
		zone TABLE, as zoneTierOf(zone) reading zone.id a few lines up shows.
		This Luau build throws on `number * table`, so every chest that rolled
		the `coins` reward errored out before paying anything.

		Dirt is one coin per point of HP (see the dig path, "One coin per point
		of HP"), so the value of the dirt a chest was buried in IS its HP.
		Asking Depth for it directly is both correct and the same rule the rest
		of the coin economy runs on.
	]]
	local dirtValue = math.max(1, Dig.Depth.dirtHp(zoneTierOf(zone), layer))

	if chosen.kind == "pack" then
		-- A run, not a row. Sometimes nothing, sometimes a pile; the count is
		-- uncapped on purpose (C.chestPackCount).
		-- PACK luck: stamped on the row, and it is what siphons that pack's
		-- card odds when it is opened. Not the chest channel.
		local stampedLuck = math.max(1, Dig.packLuck(b))
		local n = C.chestPackCount and C.chestPackCount(luck, rng) or 1
		for _ = 1, n do
			local row = {
				kind = kind,
				chestId = chest.id,
				zoneTier = tier,
				zoneId = zone.id,
				layer = layer,
				setId = C.setForLayer(zone, layer),
			}
			if stampedLuck > 1 then
				row.luck = stampedLuck
			end
			table.insert(p.packs, row)
		end
		if n == 0 then
			return "empty", 0
		end
		return "pack", chest.id, n
	elseif chosen.kind == "hat" then
		-- Head-slot gear, rolled on the spot. The common cosmetic find.
		if Gear and Gear.rollPiece then
			p.gear = p.gear or {}
			local id = instanceHex16()
			local piece = Gear.rollPiece(id, rng, "head")
			if piece then
				table.insert(p.gear, piece)
				return "hat", piece.name or "Hat"
			end
		end
		-- Gear unavailable: fall through to a pack rather than a dead chest.
		table.insert(p.packs, { kind = kind, chestId = chest.id, zoneTier = tier,
			zoneId = zone.id, layer = layer, setId = C.setForLayer(zone, layer) })
		return "pack", chest.id
	elseif chosen.kind == "charm" then
		-- The rare one. Never a duplicate; a full set falls back to a pack so
		-- the rarest roll is never a dead one, same as relics.
		local okC, Charms = pcall(function()
			return require(shared:WaitForChild("MineCharms"))
		end)
		if okC and Charms and Charms.packPool then
			p.charms = p.charms or {}
			local pool = {}
			for _, c in ipairs(Charms.packPool() or {}) do
				if not p.charms[c.id] then table.insert(pool, c) end
			end
			if #pool > 0 then
				local c = pool[rng:NextInteger(1, #pool)]
				p.charms[c.id] = true
				return "charm", c.name or c.id
			end
		end
		table.insert(p.packs, { kind = kind, chestId = chest.id, zoneTier = tier,
			zoneId = zone.id, layer = layer, setId = C.setForLayer(zone, layer) })
		return "pack", chest.id
	elseif chosen.kind == "coins" then
		-- Worth roughly 280-760 dirt blocks: a real jump, not a rounding error.
		local amount = math.floor(dirtValue * (280 + rng:NextNumber() * 480)
			* (b.coinBonus or 1) * luck)
		p.coins = (p.coins or 0) + amount
		return "coins", amount
	elseif chosen.kind == "dust" then
		local amount = math.max(5, math.floor(tier * tier * 120 * (0.6 + rng:NextNumber())))
		p.dust = (p.dust or 0) + amount
		return "dust", amount
	elseif chosen.kind == "relic" then
		p.relics = p.relics or {}
		-- Never hand out a duplicate; fall back to a pack once they are all
		-- found, so the rarest roll is never a dead one.
		local held = {}
		for _, r in ipairs(p.relics) do held[r.id] = true end
		local pool = {}
		for _, r in ipairs(C.RELICS) do
			if not held[r.id] then table.insert(pool, r) end
		end
		if #pool == 0 then
			local row = { kind = kind, chestId = chest.id, zoneTier = tier,
				zoneId = zone.id, layer = layer, setId = C.setForLayer(zone, layer) }
			-- PACK luck: stamped on the row, and it is what siphons that pack's
			-- card odds when it is opened. Not the chest channel.
			local stampedLuck = math.max(1, Dig.packLuck(b))
			if stampedLuck > 1 then
				row.luck = stampedLuck
			end
			table.insert(p.packs, row)
			return "pack", chest.id
		end
		local r = pool[rng:NextInteger(1, #pool)]
		table.insert(p.relics, { uid = instanceHex16(), id = r.id, found = os.time() })
		return "relic", r.name
	end
	return "pack", chest.id
end

local function giveDrop(p, kind, zone, layer, b)
	if kind == "chest" or kind == "crate" then
		b = b or { luck = 1 }
		local tier = zoneTierOf(zone)
		-- A crate is the lesser find: same roll, but luck bites less.
		local luck = b.luck or 1
		if kind == "crate" then luck = 1 + (luck - 1) * 0.5 end
		--[[
			THE CHEST CHANNEL, and it needs no new stat.

			`luck` decides IF a chest spawns (rollKind); chestLuck decides WHICH
			one it is, which is exactly what rollChest weighs. That pair was
			already the "chest + rare-drop luck" the split asks for, so it is
			left alone -- the two new stats carve the ORE CASE and the PACK
			stamp out of generic luck instead. See Dig.oreLuck / Dig.packLuck.
		]]
		local chest = Packs.rollChest(tier, layer, Random.new(), { luck = luck * (b.chestLuck or 1) })
		-- You do not haul a chest home. It is opened where it is found and you
		-- carry out what was inside, which is what the odds roll is for.
		rollChestLoot(p, kind, chest, tier, layer, zone, b, luck)
	else
		-- Everything you break is carried, dirt included. Where it was dug
		-- decides what it sells for, so that rides along with it.
		table.insert(p.backpack, { kind = kind, zoneTier = zoneTierOf(zone), layer = layer })
	end
end

local function lootPopup(plr, part, text, color)
	net:FireClient(plr, "loot", {
		text = text,
		color = color or Color3.fromRGB(255, 255, 255),
		pos = part and part.Position or Vector3.new(0, 8, 0),
	})
end

local function givePickaxe(plr)
	local char = plr.Character
	if not char then return end
	local p = profiles[plr.UserId]
	if p and p.toolEquipped == false then
		return
	end
	local old = char:FindFirstChild("Pickaxe") or (plr:FindFirstChild("Backpack") and plr.Backpack:FindFirstChild("Pickaxe"))
	if old then old:Destroy() end

	local row, famId, tierNo = equippedTool(p or { tools = { pickaxe = 1 } })
	if row and row.none then
		-- Nothing collected yet. The old tool was destroyed above; leaving the
		-- hands empty is the whole point of the errand.
		return
	end
	famId = famId or "pickaxe"
	local famList = Tools.TOOLS[famId] or Tools.TOOLS.pickaxe
	local count = #famList
	-- Chest/fossil tools return tier 0; Luau treats 0 as truthy so `tierNo or 1` stays 0.
	-- Map flagship power onto a ladder look so Secrets do not all render as T1.
	local lookTier = math.max(1, tonumber(tierNo) or 1)
	if (tonumber(tierNo) or 0) <= 0 and row and tonumber(row.power) then
		lookTier = math.clamp(
			math.floor(1 + math.log10(math.max(10, row.power)) * ((count - 1) / 4)),
			1,
			count
		)
	end

	local model, handle, grip
	local passId = p and p.chestTool
	local named = row and (row.modelName or row.name)
	local passAlias = ({
		lunar_pick = "LunarPickaxe",
		lunar_eclipse = "LunarEclipse",
		bp_eclipse = "Eclipse",
	})[passId]
	if passAlias and ToolModels.fromNamed then
		model, handle, grip = ToolModels.fromNamed(passAlias, "Normal", famId)
	end
	-- Shop meshes from ToolModels_50 by name (hand matches shop). Skip goofy Sodpick.
	if not handle and named and ToolModels.fromNamed and not passId then
		local SKIP_NAMED = { Sodpick = true }
		if not SKIP_NAMED[named] then
			model, handle, grip = ToolModels.fromNamed(named, "Normal", famId)
		end
	end
	if not handle and named and ToolModels.fromNamed and (p and p.chestTool) then
		model, handle, grip = ToolModels.fromNamed(named, "Normal", famId)
	end
	if not handle then
		if (passId == "lunar_pick" or passId == "lunar_eclipse") and ToolModels.buildLunar then
			model, handle, grip = ToolModels.buildLunar(passId)
		elseif passId == "bp_eclipse" and ToolModels.buildLunar then
			model, handle, grip = ToolModels.buildLunar("bp_eclipse")
		else
			--[[
				A FORGED TOOL LOOKS LIKE ITS ORE.

				Without the look, build() colours itself from an eight-step ramp
				indexed by lookTier -- a cosmetic shop rung -- so all 82 ore
				tools shared eight palettes and the ore was visible nowhere on
				the thing it made. The ore row already carries a colour, a real
				material, metalness and roughness; oreLook turns that into the
				head colour, the haft, the material, the gleam and the
				silhouette.

				Only for a forged tool: row.oreTier is what marks one, and a shop
				rung keeps the ramp it was authored against.
			]]
			local oreLook
			local oTier = row and tonumber(row.oreTier)
			if oTier and ToolModels.oreLook then
				local oreDef = C.ORES and C.ORES[math.floor(oTier)]
				oreLook = oreDef and ToolModels.oreLook(oreDef, C.ORE_COUNT or #(C.ORES or {})) or nil
			end
			model, handle, grip = ToolModels.build(famId, lookTier, count, oreLook)
		end
	end
	if not handle then
		warn("[Mine] ToolModels.build returned no handle", famId, lookTier, passId, named)
		return
	end

	local tool = Instance.new("Tool")
	tool.Name = "Pickaxe"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = (row and row.name) or "Pickaxe"
	tool.Grip = grip

	handle.Parent = tool
	for _, c in ipairs(model:GetChildren()) do
		if c ~= handle then
			c.Parent = tool
		end
	end
	model:Destroy()

	tool:SetAttribute("Family", famId)
	tool:SetAttribute("Tier", lookTier)
	--[[
		Breaking power, stamped separately from `Tier` on purpose.

		`Tier` above is lookTier: a cosmetic ladder rung clamped to the shop
		family's length, used to pick a model. It is NOT the ore tier, and the
		swing gate must never read it. OreTier is only present on a forged ore
		tool; its absence is what marks a tool as having no ore behind it.
	]]
	-- BreakPower is stamped on EVERY tool, from its base stats, so the swing
	-- gate has one thing to read whatever a player is holding. OreTier rides
	-- alongside it as identity, only on a forged tool.
	tool:SetAttribute("BreakPower", C.toolBreakingPower(row or {}))
	if row and tonumber(row.oreTier) then
		tool:SetAttribute("OreTier", math.floor(tonumber(row.oreTier)))
		tool:SetAttribute("OreToolUid", tostring(row.oreToolEquipped or ""))
	end
	if p and p.chestTool then
		tool:SetAttribute("ChestToolId", p.chestTool)
		tool:SetAttribute("Secret", true)
	end
	--[[
		FINISHES YOU CAN SEE ACROSS THE PIT.

		Shiny is no longer a gold tint -- gold is a card variant and the two
		read as the same thing at a glance. A shiny tool keeps its own colours,
		gains a mirror finish and throws sparks. A shadow tool goes almost pure
		black and burns red.
	]]
	if row and (row.shiny or row.shadow or row.variant) then
		if ToolModels.applyFinish then
			if row.variant and row.variant ~= "Normal" and row.variant ~= "Shiny" then
				ToolModels.applyFinish(tool, row.variant)
			end
			if row.nightmare then
				ToolModels.applyFinish(tool, "Nightmare")
			elseif row.shadow then
				ToolModels.applyFinish(tool, "Shadow")
			elseif row.shiny then
				ToolModels.applyFinish(tool, "Shiny")
			end
		else
			local nightmare = row.nightmare and true or false
			local shadow = (not nightmare) and row.shadow and true or false
			tool:SetAttribute(nightmare and "Nightmare" or shadow and "Shadow" or "Shiny", true)
			for _, d in ipairs(tool:GetDescendants()) do
				if d:IsA("BasePart") then
					if nightmare then
						d.Color = d.Color:Lerp(Color3.fromRGB(220, 8, 28), 0.72)
						d.Material = Enum.Material.Neon
						d.Reflectance = 0.05
					elseif shadow then
						d.Color = d.Color:Lerp(Color3.fromRGB(10, 8, 12), 0.88)
						d.Material = Enum.Material.Glass
						d.Reflectance = math.max(d.Reflectance, 0.25)
					else
						d.Reflectance = math.max(d.Reflectance, 0.6)
						d.Material = Enum.Material.Foil
					end
				end
			end
			local att = Instance.new("Attachment")
			att.Name = "FinishFx"
			att.Parent = handle
			local sparks = Instance.new("ParticleEmitter")
			sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparks.Rate = shadow and 26 or 18
			sparks.Lifetime = NumberRange.new(0.45, 0.9)
			sparks.Speed = NumberRange.new(0.6, 2.2)
			sparks.SpreadAngle = Vector2.new(180, 180)
			sparks.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, shadow and 0.5 or 0.42),
				NumberSequenceKeypoint.new(1, 0),
			})
			sparks.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(1, 1),
			})
			sparks.Color = shadow
				and ColorSequence.new(Color3.fromRGB(255, 40, 40), Color3.fromRGB(90, 0, 0))
				or ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 230, 255))
			sparks.LightEmission = 1
			sparks.LightInfluence = 0
			sparks.Acceleration = Vector3.new(0, -2, 0)
			sparks.Parent = att
			local glow = Instance.new("PointLight")
			glow.Color = shadow and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(220, 240, 255)
			glow.Brightness = shadow and 2.2 or 1.4
			glow.Range = 10
			glow.Parent = handle
		end
	end
	-- Mark before Parent so MineAntiGear ChildAdded watchers keep this tool.
	MineAntiGear.mark(tool)
	tool.Parent = plr:FindFirstChild("Backpack") or char
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum:EquipTool(tool) end
	-- Re-mark after EquipTool moves the instance into the character (ChildAdded
	-- watchers on Character also defer-strip unmarked Tools).
	MineAntiGear.mark(tool)
end

-- The backpack is worn, not carried: it welds to the torso and swaps whenever
-- the player upgrades. Without this the bag upgrade was invisible.
local function giveBackpackModel(plr)
	local char = plr.Character
	if not char then return end
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not torso then return end
	local old = char:FindFirstChild("WornPack")
	if old then old:Destroy() end

	local p = profiles[plr.UserId]
	local tier = (p and p.backpackTier) or 1
	local count = #C.BACKPACKS
	for _, row in ipairs((p and p.chestTools) or {}) do
		if type(row) == "table" and tonumber(row.slots) then
			tier = count
			break
		end
	end
	local bagRow = C.BACKPACKS[tier]
	if p and (p.equippedBag == "founders" or p.equippedBag == "wormhole") then
		for i, r in ipairs(C.BACKPACKS) do
			if type(r) == "table" and r.skin == p.equippedBag then
				tier = i
				bagRow = r
				break
			end
		end
	end
	local model, body = ToolModels.backpack(tier, count, bagRow)
	model.Name = "WornPack"
	if not body then
		body = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	end
	if not body then
		model:Destroy()
		return
	end

	--[[
		Sit it on the spine, derived rather than guessed.

		This was a fixed `CFrame.new(0, 0.1, 0.72)`. 0.72 studs is roughly right
		for a default R15 UpperTorso and wrong for everything else -- Roblox
		avatars scale, so on a broad or tall character the same constant leaves
		the bag hanging well off the back, and on a small one it sinks into the
		shirt.

		Measure both bodies instead: half the torso's depth plus half the bag's,
		less a little so it presses into the fabric rather than floating a
		hairline off it. The bag's depth comes from the model's bounding box, not
		from the body part, because the storm flap overhangs the front and is
		part of what you see.

		PivotTo moves the whole model. The parts are weldAll'd to `body` in the
		factory so setting body.CFrame would drag them too, but that relies on
		the factory's welding, and a mount that silently depends on somebody
		else's welds is one refactor away from scattering bag parts at the
		world origin.
	]]
	local _, bagSize = model:GetBoundingBox()
	local back = torso.Size.Z * 0.5 + bagSize.Z * 0.5 - 0.12
	model:PivotTo(torso.CFrame * CFrame.new(0, 0.1, back))
	local w = Instance.new("WeldConstraint")
	w.Part0 = torso
	w.Part1 = body
	w.Parent = body
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			d.CastShadow = false
		end
	end
	model.Parent = char
end

-- Haul popups are batched over a short window. Six separate "+1 Iron" lines
-- for one blast is the single biggest reason a big hit felt like a small one.
-- One popup per block, fired at the block, carrying what that block was worth.
-- These were batched into a single total, which is tidier and completely wrong:
-- a blast that clears twelve should throw twelve numbers, because that is the
-- feedback that makes it feel like it did something.
local function bumpHaul(plr, coins, pos)
	net:FireClient(plr, "haul", { coins = coins, pos = pos })
end

-- What a specific chest pays. Every chest declares its own coin and gem range
-- and its own per-tier pack chances, and the directory shows the player exactly
-- these numbers -- so this function must read the same table the UI reads, or
-- the game is lying to them.
local mint -- forward

local function grantChestTool(plr, p, toolId)
	if not toolId then return end
	p.chestTools = p.chestTools or {}
	for _, row in ipairs(p.chestTools) do
		if ((type(row) == "table") and row.id or row) == toolId then return end
	end
	local ct = Tools.chestTool(toolId)
	if not ct then return end
	-- No temperament: those are bought with tokens (Verbs.rollTemper).
	table.insert(p.chestTools, {
		uid = instanceHex16(),
		id = ct.id, name = ct.name, family = ct.family,
		rarity = ct.rarity or ct.rarityId,
		rarityId = ct.rarity or ct.rarityId,
		temperRolls = 0,
	})
	net:FireClient(plr, "toast", "Found " .. ct.name .. "  -  " .. tostring(ct.rarity or ct.rarityId or "?") .. " tool")
	markDirty(plr)
end

local function openChestBlock(plr, p, chestId, b, part)
	local rng = Random.new()
	local luck = (b.chestLuck or 1)
	local zone = C.zoneById(p.zoneId) or C.ZONES[1]
	local layer = part and (part:GetAttribute("CY") or 1) or 1
	local ZoneChests = require(shared:WaitForChild("MineZoneChests"))
	local ZonePacks = require(shared:WaitForChild("MineZonePacks"))

	-- Prefer the identity baked onto the block; meadow/EH always that section's chest.
	local def = ZoneChests.def(tostring(chestId or ""))
	local rank = nil
	if (zone.id == "meadow" or zone.id == "bigbang") and ZoneChests.exclusiveFor then
		def = ZoneChests.exclusiveFor(zone.id, layer)
		rank = "native"
	elseif not def then
		local pick = ZoneChests.roll(zone.id, rng, { luck = luck, layer = layer })
		if not pick or not pick.def then
			return
		end
		def = pick.def
		rank = pick.rank
	else
		for _, row in ipairs(ZoneChests.pool(zone.id) or {}) do
			if row.chestId == def.id then
				rank = row.rank
				break
			end
		end
	end

	p.found = p.found or {}
	local chestKey = tostring(def.id)
	local firstTime = not p.found[chestKey] and not p.found[def.id]
	p.found[chestKey] = (tonumber(p.found[chestKey]) or tonumber(p.found[def.id]) or 0) + 1
	if typeof(def.id) ~= "string" then
		p.found[def.id] = nil
	end
	bumpStat(plr, p, "chests")
	introAdvance(plr, p, 4)
	do
		-- Per-layer chest counts for the layer quests.
		local sec = tostring(Dig.Depth.sectionNumber(layer))
		p.stats.chestSec = p.stats.chestSec or {}
		p.stats.chestSec[sec] = (tonumber(p.stats.chestSec[sec]) or 0) + 1
	end
	if (tonumber(p.intro) or 1) == 22 then
		p.introStepChests = (p.introStepChests or 0) + 1
		if p.introStepChests >= 3 then
			introAdvance(plr, p, 22)
		else
			net:FireClient(plr, "toast", string.format("Chest %d of 3!", p.introStepChests))
		end
	end

	-- Fixed gem/coin bands from the chest def only (no zone/layer scaling).
	local coins, gems = ZoneChests.rollCurrency(def, rng)
	coins = math.max(1, math.floor(coins * (b.coinBonus or 1)))
	gems = math.floor(gems * (b.gemFind or 1))
	p.coins = (p.coins or 0) + coins
	p.gems = (p.gems or 0) + gems
	local scrapDust = 0
	do
		local sc = math.max(0, tonumber(b.scrap) or 0)
		if sc > 0 then
			scrapDust = math.floor(sc)
			if rng:NextNumber() < (sc - scrapDust) then
				scrapDust += 1
			end
			if scrapDust > 0 then
				p.dust = (p.dust or 0) + scrapDust
			end
		end
	end

	local packNames, packIds = {}, {}
	-- PACK luck: stamped on the row, and it is what siphons that pack's
	-- card odds when it is opened. Not the chest channel.
	local stampedLuck = math.max(1, Dig.packLuck(b))
	local setId = (C.setForLayer and C.setForLayer(zone, layer)) or ((zone.sets and zone.sets[1]) or "dragons_dawn")
	if zone.id == "bigbang" then
		if not (C.isEventHorizonSet and C.isEventHorizonSet(setId)) then
			setId = (zone.sets and zone.sets[1]) or "genesis_spark"
		end
	end
	local drops = ZoneChests.rollPackDrops(zone.id, def, rng)
	-- Tutorial / stamped chests: PackQty forces that many packs (meadow IntroChest = 2).
	local wantQty = tonumber(part and part:GetAttribute("PackQty"))
	if wantQty then
		wantQty = math.max(1, math.floor(wantQty))
		local guard = 0
		while #drops < wantQty and guard < 8 do
			guard += 1
			local extra = ZoneChests.rollPackDrops(zone.id, def, rng)
			if #extra > 0 then
				table.insert(drops, extra[1])
			else
				local fallback = ZonePacks.id(zone.id, "pack_common") or ZonePacks.id(zone.id, "currency_common")
				if fallback then
					table.insert(drops, fallback)
				else
					break
				end
			end
		end
		while #drops > wantQty do
			table.remove(drops)
		end
	end
	for _, packId in ipairs(drops) do
		local zpack = ZonePacks.get(packId)
		local row = {
			kind = "chest",
			chestId = def.id,
			packId = packId,
			packName = (zpack and zpack.name) or packId,
			zoneId = zone.id,
			layer = layer,
			setId = setId,
			rank = rank,
		}
		if stampedLuck > 1 then
			row.luck = stampedLuck
		end
		table.insert(p.packs, row)
		table.insert(packNames, (zpack and zpack.name) or packId)
		table.insert(packIds, packId)
		local slot = zpack and zpack.slot or packId
		local rarePack = slot == "pack_legendary" or (type(slot) == "string" and string.find(slot, "legendary", 1, true))
		if rarePack then
			net:FireClient(plr, "foundTool", {
				name = row.packName,
				kind = "pack",
				packId = packId,
				rarityId = "Legendary",
				title = "BONKERS PACK",
				blurb = "That one does not come around often. It is in your bag.",
			})
		end
	end

	net:FireClient(plr, "chestOpened", {
		id = def.id,
		name = def.name,
		kind = "zone",
		coins = coins,
		gems = gems,
		dust = scrapDust > 0 and scrapDust or nil,
		pack = packNames[1],
		packs = packNames,
		packIds = packIds,
		rank = rank,
		pos = part and part.Position or nil,
		first = firstTime,
	})
	if rollChestTool then
		pcall(rollChestTool, plr, p, def.id, b, { layer = layer, zoneId = zone and zone.id, setId = setId })
	end
	--[[
		A GRADED CHARM, 0.5% OF CHESTS. Owner, 2026-10-07: charms "can be found in
		chests (0.5%) or bought with tokens".

		The 0.5% decides only WHETHER a charm drops; rollChestCharm then draws which
		one against MineTemper's rarity weights, so the half-percent is spent mostly
		on F and D and the single SSS is rare twice over.

		`Charms` is the module upvalue from the top of this file, deliberately --
		the `rollChestTool` call directly above reads a LOCAL declared ~2,600 lines
		below, which makes it a global read that is always nil, so that branch never
		runs (open-questions #7). Writing this against the upvalue is what keeps it
		from being the same silent no-op.

		Chest luck scales it, like the persist-bag roll below. No first-charm
		guarantee here: that rule belongs to the zone grant and the ore case, which
		is where a new player meets their first charm.
	]]
	do
		local roll = Charms.rollChestCharm and (tonumber(Charms.CHARM_CHEST_CHANCE) or 0) > 0
		if roll and Random.new():NextNumber() < Charms.CHARM_CHEST_CHANCE * ((b and b.chestLuck) or 1) then
			local cdef = Charms.rollChestCharm(Random.new())
			if cdef then
				p.charms = p.charms or {}
				-- A tally, not a latch: see the note on the zone grant.
				p.charms[cdef.id] = (tonumber(p.charms[cdef.id]) or 0) + 1
				local wearing = type(p.equippedCharm) == "string" and p.equippedCharm ~= ""
				if not wearing then
					p.equippedCharm = cdef.id
				end
				local how = wearing and "equip it in Inventory → Equipment" or "equipped"
				net:FireClient(plr, "toast", "Charm found: " .. cdef.name .. " — " .. how)
				net:FireClient(plr, "foundTool", {
					kind = "charm",
					charmId = cdef.id,
					name = cdef.name,
					title = "CHARM FOUND",
					-- The grade IS the rarity here, unlike the zone grant where the
					-- depth band stands in for one.
					rarityId = Charms.RARITY_LABEL and Charms.RARITY_LABEL[cdef.rarity] or "Legendary",
					blurb = (cdef.blurb or "") .. "  ·  " .. how,
				})
				markDirty(plr)
			end
		end
	end
	-- Mid/deep: small chance at a zone persist bag (even zones 1/band, odd share the tool bands).
	do
		local band = (C.depthBand and C.depthBand(layer)) or "shallow"
		if band ~= "shallow" and zone and zone.id then
			local rng = Random.new()
			local chance = (band == "deep") and 0.004 or 0.008
			if rng:NextNumber() < chance * ((b and b.chestLuck) or 1) then
				p.persistBags = p.persistBags or {}
				local bagId = tostring(zone.id) .. "_" .. band .. "_bag"
				if not p.persistBags[bagId] then
					p.persistBags[bagId] = true
					-- Capacity bump: mid +25%, deep +50% of current bought cap feel.
					p.backpackBonus = (p.backpackBonus or 0) + ((band == "deep") and 0.50 or 0.25)
					net:FireClient(plr, "toast", "Persist bag found (" .. band .. ") — haul bonus kept on rebirth")
				end
			end
		end
	end
	markDirty(plr)
end
--[[
	Battle pass progress. One block is one point, and the day's earning is
	capped -- see MineScrolls for why, and for the two numbers that set the
	season length.

	The day key is UTC so it rolls at the same instant for everybody, rather
	than handing whoever lives in the right timezone two caps in one sitting.
]]
local function passDayKey()
	return os.date("!%Y-%m-%d")
end

local function awardPassXp(plr, p, points, source)
	p.pass = Scrolls.reconcilePass(p.pass or Scrolls.emptyPass())
	local pass = p.pass
	local today = passDayKey()
	if pass.day ~= today then
		pass.day, pass.dayXp = today, 0
	end
	points = math.floor(tonumber(points) or 0)
	if points <= 0 then
		return
	end
	-- Quest-driven only. Dig/sell/pack grind no longer feeds the battle pass;
	-- the old flat daily dig cap is gone. Completing quests IS the daily budget.
	local fromQuest = source == "quest" or source == "daily" or source == "contract" or source == "milestone"
	if not fromQuest then
		return
	end
	local before = Scrolls.passTier(pass.xp or 0)
	pass.dayXp = (pass.dayXp or 0) + points
	pass.xp = (pass.xp or 0) + points
	local after = Scrolls.passTier(pass.xp)
	if after > before then
		net:FireClient(plr, "toast", "Battle Pass tier " .. after .. " reached")
	end
	markDirty(plr)
end

local function finishBreak(plr, part, p, zone, kind, layer)
	p._userId = plr.UserId
	--[[
		FLAG, DO NOT EJECT.
	
		The old watcher teleported anyone standing past their own dug depth,
		which threw honest players out of shafts they were entitled to be in far
		more often than it caught anyone. This writes a row for a human instead.
	
		Measured against how deep THE MINE has been dug on this server in the
		last twenty minutes, not against this player's own progress -- so pets,
		blasts, echo and anyone working at the bottom of somebody else's shaft
		are all normal and silent. Only someone mining far below any hole that
		exists says anything.
	]]
	if layer > (Dig.Auth.serverDepth(zone.id) + Const.FLAG_DEPTH_SLACK) then
		pcall(function()
			DiscordLink.flag("deep_dig", plr.UserId, plr.Name, {
				zone = tostring(zone.id),
				layer = layer,
				mineDepth = Dig.Auth.serverDepth(zone.id),
				ownDeepest = (p.deepest and p.deepest[tostring(zone.id)]) or 0,
				prestige = p.prestige or 0,
			})
		end)
	end
	do
		--[[
			Deepest / plaza only if the dig was allowed; break loot still
			resolves either way.

			canCreditDepth is the gate that actually holds. canDigLayer ends in
			an unconditional `return true` on purpose -- refusing a SWING only
			means standing in rock that will not break -- so on its own it let a
			single block broken at layer 5000 credit depth 5000. Owner,
			2026-10-06: the chunk gate is "to ensure hackers dont break one block
			in every chunk and unlock the depth points".
		]]
		if Dig.Auth.canDigLayer(p, zone.id, layer)
			and Dig.Auth.canCreditDepth(p, zone.id, layer) then
			Dig.Auth.noteDig(p, zone.id, layer, part:GetAttribute("CX"), part:GetAttribute("CZ"))
			if Dig.Auth.creditDeepest(p, zone.id, layer) then
				local zid = tostring(zone.id)
				local depthNow = p.deepest[zid] or p.deepest[zone.id] or layer
				-- Live cycle: credit the dug layer (section-accurate). Never mineshaft.
				pcall(function()
					local Live = require(script.Parent:WaitForChild("MineDepthLive"))
					Live.writeProfile(p, zid, layer)
					Live.noteDigCredit(plr, zid, layer, "dig")
				end)
				pcall(function()
					LeaderboardService.queueDepth(plr.UserId, zid, depthNow)
					if LeaderboardService.flushAndPaintDepth then
						LeaderboardService.flushAndPaintDepth(plr.UserId, zid)
					end
					if LeaderboardService.refreshDepthBoards then
						LeaderboardService.refreshDepthBoards()
					end
				end)
				if (tonumber(p.intro) or 1) == 21 and (tonumber(depthNow) or 0) >= 30 then
					introAdvance(plr, p, 21)
				end
			end
			pcall(function()
				local zid = tostring(zone.id)
				Dig.Plazas.onDepthCredit(zid, p.deepest[zid] or p.deepest[zone.id] or layer)
			end)
		end
	end
	-- Zone charms: first break into a band on odd islands grants once.
	do
		local band = Charms.bandForLayer(layer)
		local def = Charms.CHARM_ZONES[zone.id] and Charms.zoneBandCharm(zone.id, band)
		if def then
			p.charms = p.charms or {}
			--[[
				A roll, not a guarantee (MineCharms.zoneDropChance). Your first
				charm still lands outright -- the early game is balanced around
				wearing one -- and every charm after that has to be found.
			]]
			-- Charms.ownsAnyCharm, not `next(p.charms)`: a tally left at zero by a
			-- removal is a key with a falsy value, and `next` would read that as
			-- ownership -- quietly cancelling the first-charm guarantee for
			-- somebody who owns nothing.
			local ownsAny = Charms.ownsAnyCharm(p)
			local chance = (Charms.zoneDropChance and Charms.zoneDropChance(ownsAny)) or 1
			--[[
				Charms tally instead of latching. `p.charms[id]` was `true`, so a
				charm you owned could never drop again; it is a COUNT now, which
				stays truthy for every reader that only asks "do I have one".
				A legacy `true` reads as one copy.
			]]
			if Random.new():NextNumber() < chance then
				p.charms[def.id] = (tonumber(p.charms[def.id]) or 0) + 1
				-- Nothing on yet (for a new player, this is their first block):
				-- put it on, so the first charm is a boost they feel rather than
				-- a menu they have to find.
				local wearing = type(p.equippedCharm) == "string" and p.equippedCharm ~= ""
				if not wearing then
					p.equippedCharm = def.id
				end
				local how = wearing and "equip it in Inventory → Equipment" or "equipped"
				net:FireClient(plr, "toast", "Charm unlocked: " .. def.name .. " — " .. how)
				net:FireClient(plr, "foundTool", {
					kind = "charm",
					charmId = def.id,
					name = def.name,
					title = "CHARM UNLOCKED",
					rarityId = (band == "deep" and "Divine") or (band == "mid" and "Mythic") or "Legendary",
					blurb = (def.blurb or "") .. "  ·  " .. how,
				})
			end
		end
	end
	if math.floor(tonumber(p.intro) or 0) == 28 and not p.introCharmGot then
		p.charms = p.charms or {}
		p.charms.sod = true
		p.introCharmGot = true
		if type(p.equippedCharm) ~= "string" or p.equippedCharm == "" then
			p.equippedCharm = "sod"
		end
		net:FireClient(plr, "toast", "Charm unlocked: Sod Charm")
		net:FireClient(plr, "foundTool", {
			kind = "charm", charmId = "sod", name = "Sod Charm",
			title = "CHARM UNLOCKED", rarityId = "Legendary",
			blurb = "+110% Mine Speed",
		})
		introAdvance(plr, p, 28)
	end
	awardPassXp(plr, p, 1)
	introAdvance(plr, p, 1)
	bumpStat(plr, p, "blocks")
	--[[
		One stack up the charm RAMP.

		Only here, and deliberately NOT on the AFK block (which also bumps the
		"blocks" stat): the ramp exists to reward a long active session, and an
		idle source feeding it would let a player park on the AFK block and sit at
		full stacks indefinitely. That is a permanent bonus wearing a ramp's
		clothes -- the same failure the charm conditions were just fixed for.
	]]
	Charms.bumpRamp(p)
	-- Dig deeper, and the next slice of the mine appears below you.
	task.spawn(ensureZone, zone, layer + Const.ENSURE_BAND)
	-- One coin per point of HP -- see MineConfig.coinsFor. This is the whole
	-- coin economy, and it is why a zone-6 clod of dirt is worth 1,465 and a
	-- zone-1 one is worth 1.
	local bb = boosts(p)
	-- Step 4 teaches chests. Meadow already plants a starter chest near the pit
	-- centre (see ensureZone). This still advances after a dozen non-chest breaks
	-- so a dry unlucky stretch cannot stall the tutorial; opening a chest sooner
	-- also advances. Step 5's grantPack remains a safety net for an empty bag.
	if (tonumber(p.intro) or 1) == 4 and kind ~= "chest" then
		p.introChestPity = nil
		p.introStepBlocks = (p.introStepBlocks or 0) + 1
		if p.introStepBlocks >= 12 then
			p.introStepBlocks = nil
			introAdvance(plr, p, 4)
		end
	end
	-- The haul was already paid, point of HP by point of HP, on the way down --
	-- see payDamage. Breaking the block owes nothing further; only a chest has
	-- anything left to resolve, and that is its own loot table.
	if kind == "ore" then
		--[[
			AN ORE BLOCK HANDS OVER THE ORE. No pack in between.

			It used to bank a "<id>_ore_pack" that the player opened later. That
			cost a step for nothing: the pack's ore was already decided (its row
			carried oreId), so opening it revealed nothing that was not already
			settled, and a bag of hundreds of single-ore packs was the single
			most-complained-about screen in the game.

			The reveal does not disappear, it moves to the ORE CASE below -- a 2%
			drop whose contents genuinely are unknown until opened. A reveal
			should be for something actually random.

			Quantity comes from C.oreYieldFor(tier) -- the band table whose bell
			peaks on Epic, matching where the cost bell peaks. Rolled here rather
			than restated, so direct drops and any legacy pack stay identical.

			THE ORE FINDER IS STILL NOT APPLIED HERE, on purpose. It is a
			quality stat, not a quantity one ("better roll quality, not more
			loot"), and it already did its work in oreWeights via oreFindShift
			when this block chose which ore to be. Paying it again as extra
			material would be spending one stat twice.

			ORE HAUL IS, and it is the only thing that multiplies this roll.
			Owner, 2026-10-06: endgame enchants are meant to buff ore, and
			measurement showed nothing did -- an Exotic tool came to ~12 MILLION
			blocks broken with no gear able to move it (see
			docs/ore-yield-and-vein-balance.md §4). Ore Haul is the stat that
			moves it, and it is a separate key from the finder precisely so
			quality and quantity stay two different things.

			CAPPED, because the warning this comment used to carry is correct:
			yield multipliers on a flat per-block rate are how the boost stack
			compounds. MineConfig.oreHaulMult clamps it at ORE_HAUL_CAP however
			tall the stack gets.
		]]
		local ore = C.oreById(part:GetAttribute("OreId"))
		if ore then
			local lo, hi = C.oreYieldFor(ore.tier)
			lo = math.max(1, math.floor(tonumber(lo) or 1))
			hi = math.max(lo, math.floor(tonumber(hi) or lo))
			-- Roll first, multiply after: multiplying the band ends would lose
			-- the low end to flooring and quietly narrow the spread.
			local got = math.random(lo, hi)
			local haul = C.oreHaulMult(b and b.oreHaul)
			if haul > 1 then
				-- Floored, like every other payout here, and never below the
				-- unboosted roll -- a boost must not be able to cost you ore.
				got = math.max(got, math.floor(got * haul))
			end
			--[[
				Into the POUCH, up to what it holds, and through Dig.addOre so the
				capacity check lives in one place rather than at every site that
				grants ore. A full pouch refuses rather than silently eating it.

				Discovery is recorded inside addOre and does NOT depend on having
				room: it drives the Forge recipe list, and a full pouch quietly
				blocking discovery would hide the recipe you needed for a reason
				nothing on screen tells you.
			]]
			local kept, spilled = Dig.addOre(p, ore.id, got)
			if kept > 0 then
				net:FireClient(plr, "toast", ("+%d %s"):format(kept, ore.name))
				net:FireClient(plr, "loot", {
					text = ("+%d %s"):format(kept, ore.name),
					color = ore.color or Color3.fromRGB(255, 220, 140),
					pos = part.Position,
				})
			end
			if spilled > 0 then
				Dig.pouchFullToast(plr, p)
			end

			--[[
				THE ORE CASE is the rare half of the loot split.

				One case per ore, 2% per ore block, luck-scaled. This IS the rare
				drop -- there is no second roll inside the case. Opening one pays
				a skin or a charm, guaranteed, which makes this 2% the only number
				standing between a block and a prize. It replaced the old
				rare-tool wall drop entirely: tools are forged now, not found.

				It is rolled even when the pouch was full. The case is not ore and
				does not take pouch space, so a full pouch costs you material --
				it does not cost you the chase.
			]]
			-- ORE luck, not generic luck: the case is the rare drop off an ore,
			-- and a chest hat should not move it.
			local caseChance = (tonumber(C.ORE_CASE_CHANCE) or 0)
				* math.max(1, Dig.oreLuck(bb))
			if caseChance > 0 and Random.new():NextNumber() < caseChance then
				p.packs = p.packs or {}
				table.insert(p.packs, {
					packId = ore.id .. "_ore_case",
					packName = ore.name .. " Case",
					kind = "ore_case",
					oreId = ore.id,
					layer = layer,
				})
				net:FireClient(plr, "toast", ore.name .. " CASE!")
				net:FireClient(plr, "loot", {
					text = "CASE",
					color = ore.color or Color3.fromRGB(255, 196, 64),
					pos = part.Position,
				})
			end
			-- TODO(runes): roll this ore's rune here, 2% down to 0.5% by tier,
			-- F-SSS. Needs the rune overhaul; nothing rolls one yet.
		end
	elseif kind == "core" then
		grantChestTool(plr, p, "geothermal_nuke")
	elseif kind == "chest" or kind == "crate" then
		openChestBlock(plr, p, part:GetAttribute("ChestType"), bb, part)
	elseif kind == "lucky_block" then
		local id = part:GetAttribute("LuckyBlockId") or LuckyBlocks.rollPitId(Random.new())
		-- Some come already graded (MineLuckyBlocks.PRESET_WEIGHTS).
		LuckyBlocks.grant(p, id, LuckyBlocks.rollPresetGrade(), 1)
		local def = LuckyBlocks.def(id)
		net:FireClient(plr, "toast", (def and def.name or "Lucky Block") .. "!")
		net:FireClient(plr, "loot", {
			text = "LUCKY",
			color = (def and def.color) or Color3.fromRGB(255, 196, 64),
			pos = part.Position,
		})
	else
		--[[
			A LUCKY BLOCK IS A ROLL ON EVERY BLOCK OF DIRT.

			They used to be placed in the mine like chests, which meant you only
			got one by digging past it. Now each ordinary break rolls
			LUCKY_BLOCK_CHANCE (the same rate the placed ones had), and Lucky
			Find multiplies it -- 1 + luckyFind, so the stat is extra chance on
			top of the base rather than the only chance there is.
		]]
		local lf = math.max(0, tonumber(bb.luckyFind) or 0)
		local p0 = C.LUCKY_BLOCK_CHANCE or 0.00020
		local extra = p0 * (1 + lf)
		local rngFind = Random.new()
		while extra > 0 do
			local slice = math.min(1, extra)
			if rngFind:NextNumber() < slice then
				local id = LuckyBlocks.rollPitId(rngFind)
				LuckyBlocks.grant(p, id, LuckyBlocks.rollPresetGrade(rngFind), 1)
				local def = LuckyBlocks.def(id)
				net:FireClient(plr, "toast", (def and def.name or "Lucky Block") .. "!")
				net:FireClient(plr, "loot", {
					text = "LUCKY",
					color = (def and def.color) or Color3.fromRGB(255, 196, 64),
					pos = part.Position,
				})
			end
			extra -= slice
		end
		local pv = math.max(0, tonumber(bb.pulverize) or 0)
		if pv > 0 then
			local n = math.floor(pv)
			if rngFind:NextNumber() < (pv - n) then
				n += 1
			end
			if n > 0 then
				p.dust = (p.dust or 0) + n
			end
		end
	end
	-- Chest loot numbers come from chestOpened at the block (coins/gems/pack).
	local cx, cz = part:GetAttribute("CX") or 0, part:GetAttribute("CZ") or 0
	-- VOXEL_SKIP (not nil): concurrent ensureZone must not refill dug cells.
	if voxels[zone.id] then voxels[zone.id][keyOf(zone.id, cx, layer, cz)] = Const.VOXEL_SKIP end
	part:Destroy()
	-- Coalesced: see markDirty. One block is not worth a whole profile.
	markDirty(plr)
	-- Broken stays broken unless REGEN_SEC is deliberately raised.
	if (C.REGEN_SEC or 0) <= 0 then
		return
	end
	task.delay(C.REGEN_SEC, function()
		if workspace:FindFirstChild("MineWorld") then
			local live = profiles[plr.UserId]
			local key = keyOf(zone.id, cx, layer, cz)
			if voxels[zone.id] then voxels[zone.id][key] = nil end
			spawnVoxel(zone, cx, layer, cz, rollKind(zone, cx, layer, cz, live and boosts(live) or { luck = 1, rareOre = 1 }, Random.new()), live and boosts(live) or { rareOre = 1 })
		end
	end)
end

-- One cell of a blast. Deliberately simpler than swingBlock: no reach
-- check, no cooldown, no echo -- the blast already paid for those at the
-- centre. It only applies damage and lets finishBreak do the rest.
-- One point of HP is one dirt in the bag and one coin, credited as the damage
-- lands rather than when the block finally gives way. A 2,600 HP clod that pays
-- nothing for eight swings and then everything at once reads as a game that is
-- ignoring you -- and a chest, which is broken like anything else, paid nothing
-- at all. The "+N" the player sees is the hit number that was always there; this
-- only makes the bag agree with it.
--
-- The block's real MaxHP comes from its section, not from MineConfig.BLOCKS, so
-- paying per point of damage is also what keeps a deep clod worth more than a
-- shallow one without anything having to look the price up.
function Dig.seedHaulMix(p)
	if type(p) ~= "table" then
		return
	end
	if type(p.haulMix) ~= "table" then
		p.haulMix = {}
	end
	if next(p.haulMix) ~= nil then
		return
	end
	local coinPay = math.max(0, math.floor(tonumber(p.haulCoins) or 0))
	local spacePay = math.max(0, math.floor(tonumber(p.haulSpace) or 0))
	local bagLoad = math.max(0, math.floor(tonumber(p.load) or 0))
	local totalPay = coinPay + spacePay
	local coinLoad = (totalPay > 0) and math.floor(bagLoad * coinPay / math.max(1, totalPay)) or ((spacePay > 0) and 0 or bagLoad)
	local spaceLoad = math.max(0, bagLoad - coinLoad)
	if coinPay > 0 or coinLoad > 0 then
		p.haulMix["legacy|dirt|mixed|shallow|coin"] = {
			zone = "legacy", kind = "dirt", section = "mixed", band = "shallow", currency = "coin",
			load = coinLoad, pay = coinPay,
		}
	end
	if spacePay > 0 or spaceLoad > 0 then
		p.haulMix["bigbang|dirt|mixed|shallow|space"] = {
			zone = "bigbang", kind = "dirt", section = "mixed", band = "shallow", currency = "space",
			load = spaceLoad, pay = spacePay,
		}
	end
end

function Dig.addHaul(p, zoneId, layer, kind, currency, take, pay)
	Dig.seedHaulMix(p)
	p.haulMix = p.haulMix or {}
	local sec = Dig.Depth and Dig.Depth.sectionFor and Dig.Depth.sectionFor(layer)
	local sectionId = (sec and sec.id) or "dirt"
	local band = (sec and sec.band) or "shallow"
	zoneId = tostring(zoneId or "meadow")
	kind = tostring(kind or "dirt")
	currency = (currency == "space") and "space" or "coin"
	local key = zoneId .. "|" .. kind .. "|" .. sectionId .. "|" .. band .. "|" .. currency
	local rec = p.haulMix[key]
	if type(rec) ~= "table" then
		rec = { zone = zoneId, kind = kind, section = sectionId, band = band, currency = currency, load = 0, pay = 0 }
		p.haulMix[key] = rec
	end
	rec.load = math.max(0, math.floor((tonumber(rec.load) or 0) + (take or 0)))
	rec.pay = math.max(0, math.floor((tonumber(rec.pay) or 0) + (pay or 0)))
end

function Dig.recountHaul(p)
	local coins, space, load = 0, 0, 0
	if type(p.haulMix) == "table" then
		for _, rec in pairs(p.haulMix) do
			if type(rec) == "table" then
				load += math.max(0, math.floor(tonumber(rec.load) or 0))
				local pile = math.max(0, math.floor(tonumber(rec.pay) or 0))
				if rec.currency == "space" then
					space += pile
				else
					coins += pile
				end
			end
		end
	end
	p.haulCoins = coins
	p.haulSpace = space
	p.load = load
end

local function payDamage(plr, p, kind, landed, zoneId, layer)
	landed = math.floor(landed or 0)
	if landed <= 0 or not C.BLOCKS[kind] then
		return 0
	end
	-- Core chips are samples / nuke loot, not haul filler.
	if C.BLOCKS[kind].noHaul then
		return 0
	end
	local room = cap(p) - (p.load or 0)
	if room <= 0 then
		-- The rock still breaks and chests still roll; you just stop being paid.
		if not p.warnedFull then
			p.warnedFull = true
			net:FireClient(plr, "bagFull", {})
		end
		return 0
	end
	local take = math.min(landed, room)
	local b = boosts(p)
	-- p.load is NOT bumped here. seedHaulMix (called from addHaul, next line)
	-- treats a non-zero p.load with an empty haulMix as a legacy bag and mints
	-- a phantom "mixed" pile for it -- so bumping first invented 20 free slots
	-- of worthless dirt on the first block of every session, which the bag now
	-- shows to the player. recountHaul below sets p.load from haulMix, which is
	-- the real total.
	local pay = math.floor(take * (b.coinBonus or 1))
	local currency = (zoneId == "bigbang") and "space" or "coin"
	Dig.addHaul(p, zoneId or (p and p.zoneId) or "meadow", layer or 1, kind, currency, take, pay)
	Dig.recountHaul(p)
	-- The counter has to move on the hit that earned it. markDirty coalesces to
	-- ten a second, so this is a flag rather than a snapshot per swing.
	markDirty(plr)
	return take
end

function Dig.tuneProto(tool)
	if type(tool) ~= "table" then
		return tool
	end
	local id = tostring(tool.id or "")
	local special = tostring(tool.special or "")
	if special == "prototype_bag" or string.sub(id, 1, 9) == "proto_bag" then
		return tool
	end
	local proto = special == "prototype" or special == "prototype_expl" or string.sub(id, 1, 6) == "proto_"
	if not proto then
		return tool
	end
	local n, kind = Tools.protoParse(id)
	if not n then
		n = tonumber(tool.section)
		kind = (tool.family == "drill" and "drill") or (tool.family == "explosive" and "expl") or "pick"
	end
	if not n or not Tools.protoDef then
		return tool
	end
	local fresh = Tools.protoDef(n, nil, kind)
	if type(fresh) ~= "table" then
		return tool
	end
	local copy = table.clone(tool)
	copy.power = fresh.power
	copy.spacePower = fresh.spacePower
	if fresh.special then
		copy.special = fresh.special
	end
	return copy
end

local function swingNeighbour(plr, part, dmg, p)
	if not part or not part.Parent or part.Name ~= "MineBlock" then
		return
	end
	local zone = C.zoneById(part:GetAttribute("ZoneId"))
	local kind = part:GetAttribute("Kind")
	local layer = part:GetAttribute("CY") or 1
	local spec = C.BLOCKS[kind]
	if not spec then
		return
	end
	p._userId = plr.UserId
	if not Dig.Auth.canDigLayer(p, zone and zone.id, layer) then
		return
	end
	local Matter = require(shared.MineSpaceMatter)
	local tool = Dig.heldTool and Dig.heldTool[p]

	--[[
		PROCS OBEY THE BREAKING GATE TOO.

		They did not, and it was an omission rather than a decision.
		Dig.Breaking.canBreak was wired in on 2026-10-05 and only into the main
		swing -- swingNeighbour predates it and never got the check, so until now
		`canBreak` had exactly ONE call site in the whole codebase while TWO
		paths deal damage. Blast, zap, ricochet, earthquake and echo all arrive
		here, so any of them chipped rock the tool itself could not scratch.

		That matters more since ZONE_STEP went to 100: the gate is the backbone
		of progression now, and a proc that routes around it routes around the
		whole ladder. Owner, 2026-10-05, asked for the full rule -- if canBreak
		is false the hit lands for zero, ore included.

		Silent on purpose. The main swing fires a throttled "tooWeak" toast
		because the player aimed at that block; a proc lands wherever the chain
		took it, and a toast for every neighbour the chain brushed would be
		noise for something nobody targeted.
	]]
	do
		local zi = (C.zoneIndex and C.zoneIndex(part:GetAttribute("ZoneId") or (zone and zone.id))) or 1
		local okBreak = Dig.Breaking.canBreak(
			tool, zi, layer, tonumber(part:GetAttribute("OreTier")), #C.ORES, p.maxUnlockedZone)
		if not okBreak then
			return
		end
	end
	local chip = Matter.chip(part, tool, dmg)
	if not chip.ok then
		return
	end
	local pos = part.Position
	payDamage(plr, p, kind, chip.landed, zone and zone.id, layer)
	if chip.landed > 0 then
		maybeGrantCoreSample(plr, p, zone, kind)
	end
	-- Always show the number at the block, including killing blows.
	net:FireClient(plr, "hit", {
		pos = pos,
		hp = math.max(0, chip.after),
		max = chip.max,
		name = spec.name or kind,
		kind = kind,
		dmg = math.max(1, math.floor(chip.landed)),
		echo = false,
	})
	if chip.broke then
		finishBreak(plr, part, p, zone, kind, layer)
	end
end

--[[
	Blast and Zap at one block, plus the Echo strike that reuses them.

	These two procs were inline in swingBlock and hard-keyed to the cell you
	aimed at, which is why Echo -- the one proc whose whole job is to land
	somewhere else -- could never roll anything. procsAt takes the block it is
	standing on, so the centre and an echoed block run the identical rules.

	Echo is deliberately NOT rolled in here. If it were, an echo could echo, and
	a stacked Echo would turn one swing into a chain with no ceiling.
]]
--[[
	THE THREE LUCK CHANNELS (TODO 6.2).

	Generic `luck` was doing three unrelated jobs at once -- ore cases, chest
	spawns, and the luck stamped onto pack rows -- so a hat that wanted to be
	about one of them had to be about all three.

	`luck` stays the shared base, so prestige, VIP, the event pass, skills, runes
	and the Umbra gear set all behave exactly as before. These read it times the
	one channel asked for, so a source that only sets oreLuck moves ore cases and
	nothing else.

	Chest luck needs no helper: `b.luck * b.chestLuck` was already that channel
	and reads plainly at its one call site.
]]
function Dig.oreLuck(b)
	if type(b) ~= "table" then
		return 1
	end
	return math.max(0, (tonumber(b.luck) or 1)) * math.max(0, (tonumber(b.oreLuck) or 1))
end

function Dig.packLuck(b)
	if type(b) ~= "table" then
		return 1
	end
	return math.max(0, (tonumber(b.luck) or 1)) * math.max(0, (tonumber(b.packLuck) or 1))
end

Dig.PROC_SKIP = { chest = true, crate = true, core = true, lucky_block = true }
Dig.FACE6 = { { 1, 0, 0 }, { -1, 0, 0 }, { 0, 1, 0 }, { 0, -1, 0 }, { 0, 0, 1 }, { 0, 0, -1 } }

function Dig.procsAt(plr, p, b, zone, cells, part, cx, cy, cz, dmg, kind, broke, forceBlast)
	if not (zone and cells and part and cx and cy and cz) then
		return
	end
	local rng = Random.new()
	--[[
		Proc DAMAGE comes from procPower; proc CHANCE from each proc's own
		stat. Read once here so the four procs below cannot disagree about
		what a player's proc damage is mid-swing.
	]]
	local pp = tonumber(b.procPower) or 0
	-- Omni Blast is a destroy-proc: chest / core / cube deaths stay
	-- centre-only, both as the source and as a neighbour.
	if broke and not Dig.PROC_SKIP[kind] then
		--[[
			CLAMPED. Blast fires once or not at all, so anything over 1.0 was
			discarded by the comparison below -- 156 of 504 pets roll this stat
			and three of them already total 204%, which is why blast reads as
			ambient rather than as a build.

			Clamping does not nerf anyone who was at 100%: it makes the points
			ABOVE 100% visible as waste, so the curve can be re-cut to cost
			something.
		]]
		local chance = forceBlast and 1 or math.min(1, b.blastChance or 0)
		if chance > 0 and rng:NextNumber() < chance then
			net:FireClient(plr, "loot", { text = "BLAST", color = Color3.fromRGB(255, 140, 70), pos = part.Position })
			for _, d in ipairs(Dig.FACE6) do
				local other = cells[keyOf(zone.id, cx + d[1], cy + d[2], cz + d[3])]
				if other and typeof(other) == "Instance" and other.Parent then
					if not Dig.PROC_SKIP[other:GetAttribute("Kind")] then
						pcall(swingNeighbour, plr, other,
							C.procDamage(dmg, "blast", pp), p)
					end
				end
			end
		end
	end
	--[[
		RICOCHET: the hit jumps to one block beside it AND BOUNCES BACK.

		This is the only proc that returns. Blast spreads to six neighbours, zap
		wanders up to sixteen blocks away, echo lands a full hit on a neighbour
		which then rolls its own procs -- all three move damage AWAY from what
		you are aiming at, which is waste when the valuable block is the one in
		front of you.

		Ricochet concentrates instead: one hit out, one hit back into the
		original block. It is the proc you take when you care about the ore you
		are swinging at rather than the dirt around it, and that is a build
		identity rather than a damage number.

		It briefly rerolled the other procs where it landed, which made it a
		copy of Dig.echoAt -- and echo is already being wound down (MineStats:
		"Legacy: paid out as Swing Rate"). Two procs doing one job is worse than
		a weak proc.

		Still break-only, like Blast: a ricochet off a block that survived the
		swing would fire on every tick of a long dig. Still not a chain: the
		return hit goes through swingNeighbour, which re-enters nothing.
	]]
	if broke and not Dig.PROC_SKIP[kind] then
		-- Clamped for the same reason as blast: one jump, so over 1.0 is a
		-- boolean rather than a rate.
		-- Clamped like blast: one jump out and one back, so a value over 1.0 is
		-- a boolean rather than a rate.
		local ric = math.min(1, tonumber(b.ricochet) or 0)
		if ric > 0 and rng:NextNumber() < ric then
			local opts = {}
			for _, d in ipairs(Dig.FACE6) do
				local nx, ny, nz = cx + d[1], cy + d[2], cz + d[3]
				local other = cells[keyOf(zone.id, nx, ny, nz)]
				if other and typeof(other) == "Instance" and other.Parent
					and not Dig.PROC_SKIP[other:GetAttribute("Kind")] then
					-- Coords travel with the part: procsAt needs the cell, and a
					-- block carries no Cx/Cy/Cz attribute to read them back off.
					table.insert(opts, { part = other, cx = nx, cy = ny, cz = nz })
				end
			end
			if #opts > 0 then
				local pick = opts[rng:NextInteger(1, #opts)]
				local hit = pick.part
				local ricDmg = C.procDamage(dmg, "ricochet", pp)
				net:FireClient(plr, "loot", { text = "RICOCHET",
					color = Color3.fromRGB(140, 220, 255), pos = hit.Position })
				pcall(swingNeighbour, plr, hit, ricDmg, p)
				--[[
					AND BACK.

					The return lands on the block that was swung at. It has
					already broken -- this branch is break-only -- so the bounce
					goes to whatever is standing there now, which on a deep seam
					is the next block the generator has pushed up into the cell.
					When the cell is empty the bounce is simply lost, which is
					the honest outcome: you cleared what you were aiming at.
				]]
				local home = cells[keyOf(zone.id, cx, cy, cz)]
				if home and typeof(home) == "Instance" and home.Parent
					and not Dig.PROC_SKIP[home:GetAttribute("Kind")] then
					net:FireClient(plr, "loot", { text = "RICOCHET",
						color = Color3.fromRGB(140, 220, 255), pos = home.Position })
					pcall(swingNeighbour, plr, home, ricDmg, p)
				end
			end
		end
	end

	--[[
		EARTHQUAKE: the block starts shaking and bleeds 20% of your tool damage
		a second until it dies or the quake runs out.

		Marked here and ticked by the loop below, because the damage has to keep
		landing while the player swings at something else -- that is the whole
		point of it. Rolled on a hit rather than on a break: a quake on a block
		that is already gone has nothing to shake.
	]]
	if not broke and not Dig.PROC_SKIP[kind] then
		-- Clamped: a quake either starts on this swing or it does not. The
		-- STACK is where the depth lives now, not the roll.
		local eq = math.min(1, tonumber(b.earthquake) or 0)
		if eq > 0 and rng:NextNumber() < eq then
			-- The PER-TICK figure is stored, not the swing: the tick loop then
			-- subtracts what it was given rather than re-deriving a share, so
			-- the quake a player started keeps its damage even if the stat
			-- changes under it mid-shake.
			Dig.startQuake(plr, p, part, C.procDamage(dmg, "quake", pp))
		end
	end

	--[[
		Chain Zap: one chain from this block, now with an end to it.

		Was 32 hops at 0.9x on both chance and damage -- 9.7x a swing off one
		roll, and at a high zap the chain barely decayed, so the hop cap was
		doing all the balancing and the falloff none. C.ZAP_MAX_HOPS hops at
		C.ZAP_FALLOFF, starting from PROC_SHARE.zap rather than a full swing.

		It still never doubles back into the cell it just left, and chain hits
		still re-proc nothing.
	]]
	--[[
		NOT clamped, and that is the point. Owner, 2026-10-05: "zap over 100 CAN
		make sense because its a chance decay".

		`chance` is multiplied by ZAP_FALLOFF every hop, so a stat above 1.0 is
		not thrown away -- it buys guaranteed early hops and moves the point
		where the chain starts failing. Zap is the only one of the four where a
		value over 1.0 is a curve rather than a boolean.
	]]
	local startZap = b.zap or 0
	if startZap <= 0 or rng:NextNumber() >= startZap then
		return
	end
	local falloff = tonumber(C.ZAP_FALLOFF) or 0.75
	local maxHops = math.max(1, math.floor(tonumber(C.ZAP_MAX_HOPS) or 6))
	local zapBase = C.procDamage(dmg, "zap", pp)
	local chance = startZap
	local fromCx, fromCy, fromCz = cx, cy, cz
	local prevDx, prevDy, prevDz = 0, 0, 0
	for hops = 1, maxHops do
		local opts = {}
		for _, d in ipairs(Dig.FACE6) do
			if not (d[1] == -prevDx and d[2] == -prevDy and d[3] == -prevDz) then
				local nx, ny, nz = fromCx + d[1], fromCy + d[2], fromCz + d[3]
				local other = cells[keyOf(zone.id, nx, ny, nz)]
				if other and typeof(other) == "Instance" and other.Parent then
					table.insert(opts, { part = other, dx = d[1], dy = d[2], dz = d[3], nx = nx, ny = ny, nz = nz })
				end
			end
		end
		if #opts == 0 then
			break
		end
		local pick = opts[rng:NextInteger(1, #opts)]
		net:FireClient(plr, "loot", { text = "ZAP", color = Color3.fromRGB(250, 220, 80), pos = pick.part.Position })
		--[[
			FALLOFF IS ODDS ONLY. Owner, 2026-10-05.

			Every hop hits for the same zapBase. The decay lives entirely in
			`chance` below, so a long chain is rare rather than weak -- the
			sixteenth block takes exactly what the first did.

			It used to decay both, which meant the far end of a chain was
			simultaneously unlikely AND nearly worthless: at hop 16 it dealt
			0.89^15 = 17% of a hop. Paying twice for the same falloff is what
			made the tail of the chain not worth reaching.
		]]
		pcall(swingNeighbour, plr, pick.part, zapBase, p)
		chance *= falloff
		if rng:NextNumber() >= chance then
			break
		end
		prevDx, prevDy, prevDz = pick.dx, pick.dy, pick.dz
		fromCx, fromCy, fromCz = pick.nx, pick.ny, pick.nz
	end
end

--[[
	THE QUAKE REGISTRY.

	[userId] = { [part] = { dmg = n, dies = clock } }, with the part itself as
	the key so "cannot stack" needs no comparison: a second proc on a block
	already shaking finds its own entry and leaves it alone rather than
	refreshing or adding to it.

	Keyed on the Instance and not on a voxel key on purpose -- a mine reset
	destroys parts without telling anyone, and a destroyed part's entry is
	dropped by the liveness check in the tick rather than lingering as a
	coordinate that now names a different rock.

	On Dig so it costs no top-level local; this script sits at 197 of Luau's 200.
]]
Dig.QUAKE = {}

--[[
	The quake stack bank, per player.

	  n      how many stacks are up, capped at QUAKE_MAX_STACKS
	  dies   when the whole bank expires, pushed out by every fresh proc
	  swing  the player's swing damage as of the last proc, so the bleed
	         tracks the tool they are actually holding

	Separate from Dig.QUAKE, which stays a set of the blocks currently shaking:
	that is what the client reads and what keeps the damage off rubble.
]]
Dig.QUAKE_STACK = {}

function Dig.startQuake(plr, p, part, dmg)
	if not (plr and part and part.Parent) then
		return false
	end
	local uid = plr.UserId
	local mine = Dig.QUAKE[uid]
	if not mine then
		mine = {}
		Dig.QUAKE[uid] = mine
	end
	--[[
		A proc always feeds the bank, even on a block already shaking.

		The old code returned early here, which is what made a second quake on
		the same block worth nothing. The STACK is the reward now; the block set
		below is only about which blocks are visibly shaking.
	]]
	local bank = Dig.QUAKE_STACK[uid]
	if not bank or os.clock() >= (bank.dies or 0) then
		bank = { n = 0 }
		Dig.QUAKE_STACK[uid] = bank
	end
	bank.n = math.min(bank.n + 1, math.max(1, math.floor(tonumber(C.QUAKE_MAX_STACKS) or 100)))
	bank.dies = os.clock() + (tonumber(C.EARTHQUAKE_SEC) or 5)
	bank.swing = math.max(1, math.floor(tonumber(dmg) or 1))

	if mine[part] then
		-- Already shaking: the stack above is the whole effect.
		return true
	end
	local n = 0
	for other in pairs(mine) do
		if other.Parent then
			n += 1
		else
			mine[other] = nil
		end
	end
	if n >= (tonumber(C.EARTHQUAKE_MAX_BLOCKS) or 5) then
		return false
	end
	-- No frozen dmg: the bank decides what a tick is worth, so a block that
	-- started shaking early keeps up with a stack that has since grown.
	mine[part] = { dies = os.clock() + (tonumber(C.EARTHQUAKE_SEC) or 5) }
	-- The client reads this to shake the block; the damage does not depend on it.
	pcall(function()
		part:SetAttribute("Quaking", true)
	end)
	net:FireClient(plr, "loot", { text = "QUAKE",
		color = Color3.fromRGB(196, 150, 96), pos = part.Position })
	return true
end

--[[
	One tick a second, for every player's quaking blocks.

	A single loop rather than a task per block: five blocks a player across a
	full server is a lot of tasks to schedule for one subtraction each, and a
	task that outlives its block is how a mine reset turns into a leak.
]]
task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for uid, mine in pairs(Dig.QUAKE) do
			local plr = Svc.Players:GetPlayerByUserId(uid)
			local prof = plr and profiles[uid] or nil
			if not (plr and prof) then
				Dig.QUAKE[uid] = nil
				Dig.QUAKE_STACK[uid] = nil
			else
				--[[
					One tick is stacks x share x swing, to every shaking block.

					The bank expires as a whole: five seconds with no quake and
					the stack count is gone, which is what stops a player
					banking 100 stacks and carrying them between veins.
				]]
				local bank = Dig.QUAKE_STACK[uid]
				if bank and now >= (bank.dies or 0) then
					Dig.QUAKE_STACK[uid] = nil
					bank = nil
				end
				local share = tonumber(C.QUAKE_STACK_SHARE) or 0.1
				local tick = bank and math.max(1,
					math.floor((bank.swing or 1) * share * (bank.n or 0))) or 0
				for part, q in pairs(mine) do
					if not part.Parent or now >= q.dies then
						if part.Parent then
							pcall(function()
								part:SetAttribute("Quaking", nil)
							end)
						end
						mine[part] = nil
					elseif tick > 0 then
						pcall(swingNeighbour, plr, part, tick, prof)
					end
				end
			end
		end
	end
end)

-- One Echo: a full-power hit on a DIFFERENT live block beside the one you swung
-- at, and then that block rolls its own procs. Returns the block it hit, or nil
-- when the swing had no neighbour left to echo into.
function Dig.echoAt(plr, p, b, zone, cells, cx, cy, cz, dmg)
	if not (zone and cells and cx and cy and cz) then
		return nil
	end
	local opts = {}
	for _, d in ipairs(Dig.FACE6) do
		local nx, ny, nz = cx + d[1], cy + d[2], cz + d[3]
		local other = cells[keyOf(zone.id, nx, ny, nz)]
		if other and typeof(other) == "Instance" and other.Parent then
			table.insert(opts, { part = other, cx = nx, cy = ny, cz = nz })
		end
	end
	if #opts == 0 then
		return nil
	end
	local pick = opts[Random.new():NextInteger(1, #opts)]
	local kind = pick.part:GetAttribute("Kind")
	net:FireClient(plr, "loot", { text = "ECHO", color = Color3.fromRGB(255, 210, 90), pos = pick.part.Position })
	if not pcall(swingNeighbour, plr, pick.part, dmg, p) then
		return pick.part
	end
	local broke = (not pick.part.Parent) or ((pick.part:GetAttribute("HP") or 1) <= 0)
	Dig.procsAt(plr, p, b, zone, cells, pick.part, pick.cx, pick.cy, pick.cz, dmg, kind, broke, false)
	return pick.part
end

-- A charge stuck to the rock: the real tool model, a blinking light, and a fuse
-- you can watch burn down. Purely cosmetic -- the damage is resolved by
-- detonate() when the timer ends, so a client that never sees this still takes
-- exactly the same hit.
local ToolModels = require(game.ReplicatedStorage:WaitForChild("ToolModelFactory"))

--[[
	Throw `tool` from `from` along `dir`, and stick it to the first surface it
	crosses.

	Returns the landing position and how long the flight took, so the caller can
	start the fuse from the moment it actually lands rather than from the throw.
]]
-- THROW_* live on Const (register budget)

local function flingCharge(tool, from, dir, fuse, ignore)
	local ok, model = pcall(function()
		local fam = tool.family or "explosive"
		local list = Tools.TOOLS[fam]
		return ToolModels.build(fam, tool.tier or 1, list and #list or 15)
	end)
	if not ok or not model then
		return from, 0
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
		end
	end
	model.Name = "StuckCharge"
	model.Parent = workspace

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model, ignore }

	local unit = dir.Magnitude > 0.001 and dir.Unit or Vector3.new(0, 0, -1)
	local reach = (Tools.reachOf and Tools.reachOf(tool)) or 26
	local speed = Const.THROW_SPEED * math.max(1, reach / 26)
	local maxT = Const.THROW_MAX * math.max(1, reach / 26)
	local vel = unit * speed + Vector3.new(0, Const.THROW_LIFT, 0)
	local pos = from
	local landed, normal = nil, Vector3.new(0, 1, 0)
	local t, step = 0, 1 / 40
	local spin = 0

	while t < maxT do
		local nextPos = pos + vel * step
		local hit = workspace:Raycast(pos, nextPos - pos, params)
		if hit then
			landed = hit.Position
			normal = hit.Normal
			break
		end
		pos = nextPos
		vel -= Vector3.new(0, Const.THROW_GRAV * step, 0)
		spin += step * 7
		model:PivotTo(CFrame.new(pos) * CFrame.Angles(spin, spin * 0.6, 0))
		t += step
		task.wait(step)
		if not model.Parent then
			return pos, t
		end
	end

	landed = landed or pos
	-- Sit it ON the surface it struck, backed off along the normal so it is not
	-- buried in the block it just hit.
	local rest = landed + normal * 0.8
	model:PivotTo(CFrame.lookAt(rest, rest + normal) * CFrame.Angles(math.rad(-90), 0, 0))

	-- Fuse: blink faster as it burns down.
	task.spawn(function()
		local core = model.PrimaryPart
		if core then
			local pl = Instance.new("PointLight")
			pl.Color = Color3.fromRGB(255, 130, 60)
			pl.Range = 16
			pl.Brightness = 2
			pl.Parent = core
			local t1 = os.clock()
			while model.Parent and os.clock() - t1 < fuse do
				local left = 1 - (os.clock() - t1) / fuse
				pl.Enabled = not pl.Enabled
				task.wait(0.05 + left * 0.2)
			end
		else
			task.wait(fuse)
		end
		if model and model.Parent then
			model:Destroy()
		end
	end)

	return landed, t
end

-- Resolve a charge's pattern. Every cell, including the one you aimed at, goes
-- through swingNeighbour so the HP cap and the bag rules apply uniformly.
-- Cosmetic only. Explosion is used with zero pressure so it cannot fling the
-- player or break joints; the damage is decided entirely by detonate().
local function blastFx(pos, tint)
	local ex = Instance.new("Explosion")
	ex.Position = pos
	ex.BlastRadius = 0
	ex.BlastPressure = 0
	ex.DestroyJointRadiusPercent = 0
	ex.ExplosionType = Enum.ExplosionType.NoCraters
	ex.Visible = true
	ex.Parent = workspace

	local flash = Instance.new("Part")
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = tint or Color3.fromRGB(255, 170, 80)
	flash.Size = Vector3.new(4, 4, 4)
	flash.CFrame = CFrame.new(pos)
	flash.Parent = workspace
	local pl = Instance.new("PointLight")
	pl.Color = flash.Color
	pl.Brightness = 6
	pl.Range = 40
	pl.Parent = flash
	task.spawn(function()
		for i = 1, 10 do
			flash.Size = Vector3.new(4 + i * 2.4, 4 + i * 2.4, 4 + i * 2.4)
			flash.Transparency = i / 10
			pl.Brightness = 6 * (1 - i / 10)
			task.wait(0.03)
		end
		flash:Destroy()
	end)
end

local function detonate(plr, p, zone, cx, cy, cz, aim, tool, dmg, b)
	local grid = voxels[zone.id]
	if not grid then
		return
	end
	local cells = Patterns.resolve(tool, cx, cy, cz, aim, b)
	-- One burst per pod centre. A cluster spreads on purpose, and without a
	-- bang at each impact it just looks like blocks disappearing at range.
	local seen = {}
	for _, c in ipairs(cells) do
		if (c.factor or 0) >= 0.99 then
			local other = grid[keyOf(zone.id, c.cx, c.cy, c.cz)]
			local k = c.cx .. ":" .. c.cz
			if other and typeof(other) == "Instance" and other.Parent and not seen[k] then
				seen[k] = true
				blastFx(other.Position, Color3.fromRGB(255, 170, 80))
			end
		end
	end
	for _, c in ipairs(cells) do
		local other = grid[keyOf(zone.id, c.cx, c.cy, c.cz)]
		if other and typeof(other) == "Instance" and other.Parent then
			local share = math.max(1, math.floor(dmg * (c.factor or 1)))
			pcall(swingNeighbour, plr, other, share, p)
		end
	end
	markDirty(plr)
end

local function swingBlock(plr, part)
	if not part or part.Name ~= "MineBlock" then return end
	local p = profiles[plr.UserId]
	if p and p.gotFirstPick == false then
		net:FireClient(plr, "toast", "Grab your FREE pickaxe from the Blacksmith first")
		return
	end
	if not Gate.canMine(plr, part) then
		net:FireClient(plr, "toast", "Unlock this zone first")
		return
	end
	do
		local layer = tonumber(part:GetAttribute("CY") or part:GetAttribute("Layer") or part:GetAttribute("Y")) or 1
		local zoneId = part:GetAttribute("ZoneId")
		p._userId = plr.UserId
		local okDig, why = Dig.Auth.canDigLayer(p, zoneId, layer)
		if not okDig then
			if why == "too_deep" or why == "air_gap" then
				net:FireClient(plr, "toast", "Mine deeper yourself — hole-hopping blocked")
			elseif why == "need_rebirth" then
				local zi = (C.zoneIndex and C.zoneIndex(zoneId or p.zoneId)) or 1
				local seam = (layer > 1500) and 1500 or 500
				local need = (Dig.Depth.rebirthForLayer and Dig.Depth.rebirthForLayer(layer, zi)) or 10
				net:FireClient(plr, "toast", (Dig.Depth.rebirthToast and Dig.Depth.rebirthToast(need, zi, seam))
					or string.format("Rebirth %d required", need))
			elseif why == "need_seam" then
				-- The seam gate is the one refusal a player can act on immediately,
				-- so it opens the purchase rather than explaining itself in a toast.
				--
				-- Throttled: this fires on every swing into locked rock, and a
				-- player who keeps swinging would otherwise rebuild the panel ten
				-- times a second. The client also refuses to reopen while it is up,
				-- so this is the cheap half of a belt-and-braces guard.
				local zi = (C.zoneIndex and C.zoneIndex(zoneId or p.zoneId)) or 1
				local seam = Dig.Depth.gateForLayer and Dig.Depth.gateForLayer(layer)
				local price = seam and Dig.Depth.seamPrice and Dig.Depth.seamPrice(seam, zi)
				local now = os.clock()
				if price and (now - (tonumber(p._seamPromptAt) or 0)) > 1.5 then
					p._seamPromptAt = now
					net:FireClient(plr, "seamGate", {
						seam = seam,
						price = price,
						minutes = Dig.Depth.SEAM_MINUTES,
						coins = math.floor(p.coins or 0),
					})
				end
			elseif why == "need_mid" or why == "need_deep" then
				net:FireClient(plr, "toast", "Reach the depth plaza to unlock this band")
			end
			return
		end
	end
	-- A full bag stops you gaining DIRT. It does not stop you mining: the rock
	-- still breaks, ore still pays gems, chests still roll. Refusing the swing
	-- outright meant a full bag bricked the game until you walked back.
	if (p.load or 0) >= cap(p) and not p.warnedFull then
		p.warnedFull = true
		net:FireClient(plr, "bagFull", {})
	elseif (p.load or 0) < cap(p) then
		p.warnedFull = false
	end
	local zone = C.zoneById(part:GetAttribute("ZoneId"))
	local kind = part:GetAttribute("Kind")
	local layer = part:GetAttribute("CY") or 1
	local spec = C.BLOCKS[kind]
	if not spec then return end

	local maxHp = part:GetAttribute("MaxHP") or C.blockHp(kind, zone, layer)
	if p.toolEquipped == false then
		net:FireClient(plr, "toast", "Equip a tool first")
		return
	end
	local tool, fam = equippedTool(p)
	tool = Dig.tuneProto(tool) or tool
	Dig.heldTool = Dig.heldTool or setmetatable({}, { __mode = "k" })
	Dig.heldTool[p] = tool
	do
		local Matter = require(shared.MineSpaceMatter)
		local why = Matter.reject(tool, part)
		if why then
			Dig.eventToast = Dig.eventToast or {}
			local nowT = os.clock()
			if (Dig.eventToast[plr.UserId] or 0) + 2 < nowT then
				Dig.eventToast[plr.UserId] = nowT
				net:FireClient(plr, "toast", why == "weak" and "Too weak out here." or "Too heavy in this gravity.")
			end
			return
		end
	end
	local b = boosts(p)
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	-- Ranged tools buy REACH; everything else works at arm's length.
	local reach = Tools.reachOf(tool) * (1 + math.max(0, tonumber(b.reach) or 0))
	if not root or (root.Position - part.Position).Magnitude > reach then return end
	-- Swings are paid from a small budget that refills at this tool's own
	-- cadence (swing-speed skills and auto-mine included) plus a third for lag.
	-- The client paces itself the same way, so nobody playing normally ever
	-- meets it; a script firing "swing" in a loop does. Explosives are metered
	-- by their cooldown just below.
	if not tool.cooldown then
		local nowB = os.clock()
		local manual = math.max(0.05, tonumber(tool.rate) or 2.5) / math.max(0.05, tonumber(b.swingSec) or 1)
		local refill = math.max(manual, tonumber(b.autoMine) or 0) * 1.35
		local bucket = swingBudget[plr.UserId]
		if not bucket then
			bucket = { tokens = 3, at = nowB }
			swingBudget[plr.UserId] = bucket
		end
		bucket.tokens = math.min(3, bucket.tokens + math.max(0, nowB - bucket.at) * refill)
		bucket.at = nowB
		if bucket.tokens < 1 then
			return
		end
		bucket.tokens -= 1
	end
	-- Explosives are thrown, not swung: the cooldown is enforced here, not
	-- trusted from the client.
	if tool.cooldown then
		local now = os.clock()
		local cd = tool.cooldown / (1 + math.max(0, tonumber(b.shortFuse) or 0))
		if (p.lastThrow or 0) + cd > now then return end
		p.lastThrow = now
	end
	-- Drills spin up when you change direction. Chest tools with zero turn skip
	-- this, which is what makes the Apex Spear worth its drop rate.
	-- Spin-up follows the TRIGGER, not the aim.
	--
	-- It used to key off the block column (CX:CZ), so it reset every time the
	-- column changed -- which is every time a block broke and the ray moved on
	-- to the next one. Holding the button restarted the spin for ever and the
	-- drill never actually dug. Now it winds once when you start, stays wound
	-- while you keep digging, and only unwinds when you let go.
	local nowDig = os.clock()
	local SPIN_GRACE = 0.35
	local turn = (tool.turn or 0) / (1 + math.max(0, tonumber(b.coolant) or 0))
	if turn > 0 then
		if (nowDig - (p.lastDigAt or 0)) > SPIN_GRACE then
			p.turnReadyAt = nowDig + turn
			-- One event per wind-up; the client runs the bar off the duration.
			net:FireClient(plr, "spin", turn)
		end
		p.lastDigAt = nowDig
		if (p.turnReadyAt or 0) > nowDig then
			return
		end
	else
		p.lastDigAt = nowDig
	end
	--[[
		BREAKING POWER. Zero damage, not reduced damage.

		This sits BEFORE dmg is computed, and returns rather than scaling, on
		purpose. Anything that let a fraction through would mean a wall could be
		ground past given enough swings, which is the whole thing breaking power
		exists to prevent.

		Server-side and attribute-driven: the tier comes off the block the
		generator stamped (OreTier), never from the client, so a forged request
		cannot claim a soft block. The tool is the one the server has the player
		holding, not one they named.
	]]
	do
		local layer = tonumber(part:GetAttribute("CY") or part:GetAttribute("Layer")) or 1
		local zi = (C.zoneIndex and C.zoneIndex(part:GetAttribute("ZoneId") or p.zoneId)) or 1
		local oreTier = tonumber(part:GetAttribute("OreTier"))
		-- maxUnlockedZone decides which reach applies: ore in the zone you are
		-- still working is asked for nearly straight, ore in a zone you have
		-- already passed drops to the full reach. See MineBreaking.reachFor.
		local okBreak, need, have = Dig.Breaking.canBreak(
			tool, zi, layer, oreTier, #C.ORES, p.maxUnlockedZone)
		if not okBreak then
			-- Throttled: a player holding the button swings into the wall ten
			-- times a second and only needs telling once.
			local nowWeak = os.clock()
			if (nowWeak - (tonumber(p._tooWeakAt) or 0)) > 1.2 then
				p._tooWeakAt = nowWeak
				net:FireClient(plr, "tooWeak", {
					need = need,
					have = have,
					ore = part:GetAttribute("OreName"),
				})
			end
			return
		end
	end
	--[[
		No scale here. The 10,000x pass is Event Horizon only
		(MineDepth.HP_SCALE), and zone 11's side of it is handled where it
		belongs: its blocks scale through the depth curve and its tools scale
		their own power in MineHorizonTools, so the two cancel without the
		normal game's swing ever knowing about it.
	]]
	local dmg = tool.power or 1
	do
		-- No one-shot rule lives here any more. "Dirt always breaks in one
		-- swing" ignored the block's HP outright, and block HP is the one thing
		-- the whole depth curve is built on. Dirt King is a Dirt Break
		-- percentage now (MineCards.TRAITS).
		local spd = (b.mineSpeed or 1)
		if fam == "explosive" then
			spd *= (1 + math.max(0, tonumber(b.shortFuse) or 0))
		end
		-- Round by chance, not down. +18% on a power-5 pick used to floor
		-- straight back to 5, so every small boost -- a pet, a charm, a skill --
		-- did nothing at all early on. Now 5.9 is a 6 nine swings in ten, and
		-- over a run of swings the boost lands in full.
		local raw = dmg * spd * (b.dirtBreak or 1)
		dmg = math.floor(raw)
		if math.random() < (raw - dmg) then
			dmg += 1
		end
		dmg = math.max(1, dmg)
	end
	local function applyDmg(amount, echo)
		if not part or not part.Parent then return true end
		local Matter = require(shared.MineSpaceMatter)
		local chip = Matter.chip(part, tool, amount)
		if not chip.ok then
			return false
		end
		local pos = part.Position
		payDamage(plr, p, kind, chip.landed, zone and zone.id, layer)
		if chip.landed > 0 then
			maybeGrantCoreSample(plr, p, zone, kind)
		end
		net:FireClient(plr, "hit", {
			pos = pos,
			hp = math.max(0, chip.after),
			max = chip.max,
			name = spec.name or kind,
			kind = kind,
			dmg = math.max(1, math.floor(chip.landed)),
			echo = echo,
		})
		if chip.broke then
			finishBreak(plr, part, p, zone, kind, layer)
			return true
		end
		return false
	end
	-- The pattern engine decides which cells this tool touches and how hard.
	-- Every cell used to take FULL power, which overstated every blast in the
	-- game against the budget the shop was pricing.
	local cx, cy, cz = part:GetAttribute("CX"), part:GetAttribute("CY"), part:GetAttribute("CZ")
	local aim = root and (part.Position - root.Position) or Vector3.new(0, 0, -1)

	-- High Roller decides what it is at the moment you throw it.
	local useTool = tool
	if tool.special == "gamble" then
		local jackpot = Random.new():NextNumber() < (tool.jackpotChance or 0.6)
		useTool = {
			power = jackpot and (tool.jackpotPower or tool.power) or tool.power,
			bombs = jackpot and (tool.jackpotBombs or 1) or 1,
			pattern = tool.pattern, radius = tool.radius, special = tool.special,
		}
		net:FireClient(plr, "loot", {
			text = jackpot and "JACKPOT" or "fizzle",
			color = jackpot and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(150, 150, 160),
			pos = part.Position,
		})
		dmg = useTool.power
	end

	-- Explosives never reach here: they are thrown with throwAt, which takes a
	-- direction rather than a block.

	local cells = voxels[zone.id]
	local touched = (cx and cells)
		and Patterns.resolve(useTool, cx, cy, cz, aim, b)
		or { { cx = cx, cy = cy, cz = cz, factor = 1 } }

	-- Exotic Edge reads the rock: quadruple on ore and crystal, single on dirt.
	local function powerFor(cellKind, base)
		if tool.special == "exotic" then
			return (cellKind == "dirt") and math.floor(base / 4) or base
		end
		return base
	end

	local hitCentre = false
	for _, c in ipairs(touched) do
		if c.cx == cx and c.cy == cy and c.cz == cz then
			hitCentre = true
		else
			local other = cells and cells[keyOf(zone.id, c.cx, c.cy, c.cz)]
			if other and typeof(other) == "Instance" and other.Parent then
				local share = math.max(1, math.floor(dmg * (c.factor or 1)))
				local ok = pcall(swingNeighbour, plr, other,
					powerFor(other:GetAttribute("Kind"), share), p)
				if not ok then break end
			end
		end
	end

	-- The cell you aimed at always takes a full-power hit.
	local centreDmg = powerFor(kind, dmg)
	local centreBroken = false
	if hitCentre or #touched == 0 then
		centreBroken = applyDmg(centreDmg, false)
	else
		centreBroken = applyDmg(centreDmg, false)
	end

	-- ECHO, BLAST, ZAP -- all three live in Dig.procsAt / Dig.echoAt now.
	--
	-- Echo used to re-hit the SAME cell for one more tick of damage, which is
	-- the least interesting thing a proc can do and reads as nothing on screen.
	-- It strikes a DIFFERENT block beside the one you hit now, and that block
	-- rolls its own Blast and its own Zap -- but never its own Echo, so even
	-- 100% Echo is one extra block per swing, not a chain reaction.
	Dig.procsAt(plr, p, b, zone, cells, part, cx, cy, cz, centreDmg, kind, centreBroken, tool and tool.omniBlast)
	local echoChance = (tool.special == "echo") and 1 or (b.echo or 0)
	if echoChance > 0 and Random.new():NextNumber() < echoChance then
		if not Dig.echoAt(plr, p, b, zone, cells, cx, cy, cz, centreDmg) and not centreBroken then
			-- Nothing left beside it: pay the old second hit rather than nothing.
			net:FireClient(plr, "loot", { text = "ECHO", color = Color3.fromRGB(255, 210, 90), pos = part.Position })
			applyDmg(centreDmg, true)
		end
	end

end

-- Throwing at a POINT rather than at a block.
--
-- Every other tool works by clicking a block, because every other tool hits the
-- block you clicked. A charge does not: it lands where you aimed and takes out
-- whatever happens to be around it. Requiring a block under the crosshair meant
-- you could not lob one into open air, down a shaft, or at a wall you had
-- already cleared -- which is most of what a charge is for.
-- Aim is a DIRECTION, not a destination. The charge goes where the throw takes
-- it, which is the difference between throwing something and guiding it.
local function throwAt(plr, dir)
	local p = profiles[plr.UserId]
	if not p or typeof(dir) ~= "Vector3" or dir.Magnitude < 0.001 then
		return
	end
	do
		local zone = C.zoneById(p.zoneId)
		if zone and not Gate.zoneUnlocked(p, zone) then
			net:FireClient(plr, "toast", "Unlock this zone first")
			return
		end
	end
	local tool = equippedTool(p)
	if not tool or not tool.cooldown then
		return
	end
	tool = Dig.tuneProto(tool) or tool
	Dig.heldTool = Dig.heldTool or setmetatable({}, { __mode = "k" })
	Dig.heldTool[p] = tool
	do
		local Matter = require(shared.MineSpaceMatter)
		local inEvent = p.zoneId == "bigbang"
		local class = Matter.classOf(tool)
		local why = (inEvent and class == "normal" and "weak") or ((not inEvent) and class == "event" and "heavy") or nil
		if why then
			net:FireClient(plr, "toast", why == "weak" and "Too weak out here." or "Too heavy in this gravity.")
			return
		end
	end
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	-- Boosts first: Short Fuse cuts the cooldown, and a thrown charge takes the
	-- same Mine Speed x Dirt Break a swing does. It used to throw at the bare
	-- tool power -- pets, skills, runes, gear and charms never reached a charge,
	-- which is most of why every bomb dug slower than a pickaxe.
	local b = boosts(p)
	local fuseMult = 1 + math.max(0, tonumber(b.shortFuse) or 0)
	local now = os.clock()
	if (p.lastThrow or 0) + (tool.cooldown / fuseMult) > now then
		return
	end
	p.lastThrow = now

	-- Rounded by chance like a swing (see swingBlock), so small boosts count.
	-- No 10,000x scale: that pass is Event Horizon only and its charges carry
	-- it in their own power. See MineDepth.HP_SCALE.
	local function boosted(power)
		local raw = (power or 1) * (b.mineSpeed or 1) * fuseMult * (b.dirtBreak or 1)
		local whole = math.floor(raw)
		if math.random() < (raw - whole) then
			whole += 1
		end
		return math.max(1, whole)
	end
	local dmg = boosted(tool.power)
	local useTool = tool
	if tool.special == "gamble" then
		local jackpot = Random.new():NextNumber() < (tool.jackpotChance or 0.6)
		useTool = {
			power = jackpot and (tool.jackpotPower or tool.power) or tool.power,
			bombs = jackpot and (tool.jackpotBombs or 1) or 1,
			pattern = tool.pattern, radius = tool.radius, special = tool.special,
			family = tool.family, tier = tool.tier,
		}
		dmg = boosted(useTool.power)
		net:FireClient(plr, "loot", {
			text = jackpot and "JACKPOT" or "fizzle",
			color = jackpot and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(150, 150, 160),
		})
	end

	local char = plr.Character
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
	local from = (hand and hand.Position) or (root.Position + Vector3.new(0, 2, 0))
	local fuse = math.clamp((tool.cooldown or 1.5) * 0.55, 0.45, 1.6)

	net:FireClient(plr, "throw", {})

	-- Out of the hand while it is in the air.
	local heldTool = char and char:FindFirstChildOfClass("Tool")
	local hidden = {}
	if heldTool then
		for _, d in ipairs(heldTool:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 1 then
				table.insert(hidden, { d, d.Transparency })
				d.Transparency = 1
			end
		end
	end

	task.spawn(function()
		local landed = flingCharge(tool, from, dir, fuse, char)
		for _, pair in ipairs(hidden) do
			if pair[1] and pair[1].Parent then
				pair[1].Transparency = pair[2]
			end
		end

		local zone = C.zoneById(p.zoneId) or C.ZONES[1]
		local origin = pitOrigin(zone)
		local size, grid = C.BLOCK, C.GRID
		local off = (grid - 1) * 0.5
		local cx = math.floor((landed.X - origin.X) / size + off + 0.5)
		local cz = math.floor((landed.Z - origin.Z) / size + off + 0.5)
		local cy = math.max(1, math.floor(-((landed.Y - origin.Y) + size * 0.5) / size + 0.5))

		task.wait(fuse)
		local live = profiles[plr.UserId]
		if not live then return end
		detonate(plr, live, zone, cx, cy, cz, dir, useTool, dmg, b)
		if tool.special == "blackhole" then
			for _ = 1, (tool.ticks or 4) - 1 do
				task.wait(tool.tick or 1.5)
				local still = profiles[plr.UserId]
				if not still then return end
				detonate(plr, still, zone, cx, cy, cz, dir, useTool, dmg, b)
			end
		end
	end)
end

local function sellAll(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	-- NEVER derive sell desk from player Y (VIP/noclip exploit). Clamp to earned deepest.
	do
		local desk, _seam = Dig.Auth.clampDesk(p, p.zoneId, p._sellDesk)
		p._sellDesk = desk
	end
	local gems, keep = 0, {}
	local coins = 0
	for _, item in ipairs(p.backpack) do
		if item.kind == "chest" or item.kind == "crate" then
			table.insert(keep, item)
		else
			-- Dirt/ore chips: paid via haulCoins below (priced as mined). Clear
			-- them from the bag so the depth pad actually empties what you see.
		end
	end
	-- The haul was priced as it was mined, with the boosts you had at the time.
	local haul, space = 0, 0
	local leftover = false
	do
		local desk = p._sellDesk or "surface"
		local seam = nil
		local okShop, Shop = pcall(function() return require(shared:WaitForChild("MineDepthShop")) end)
		if okShop and Shop and Shop.deskSeam then seam = Shop.deskSeam(desk) end
		-- Profile deepest + rebirth — never trust pad proximity / Y.
		if seam then
			local okSeam, why, need = Dig.Auth.canAccessSeam(p, p.zoneId, seam)
			if not okSeam then
				p._sellDesk = "surface"
				local zGate = C.zoneById(p.zoneId) or C.ZONES[1]
				local ziGate = C.zoneIndex and C.zoneIndex(zGate.id) or 1
				if why == "need_depth" then
					net:FireClient(plr, "toast", "Reach depth " .. tostring(need or seam) .. " to sell at this desk.")
				elseif Dig.Depth.rebirthToast and need then
					net:FireClient(plr, "toast", Dig.Depth.rebirthToast(need, ziGate, seam))
				else
					net:FireClient(plr, "toast", "This sell desk is locked.")
				end
				return
			end
		end
		Dig.seedHaulMix(p)
		local z = C.zoneById(p.zoneId) or C.ZONES[1]
		local zi = C.zoneIndex and C.zoneIndex(z.id) or 1
		local band = (okShop and Shop and Shop.deskBand and Shop.deskBand(desk)) or "shallow"
		local currency = (z.id == "bigbang") and "space" or "coin"
		p.haulMix = p.haulMix
		local drop = {}
		for key, rec in pairs(p.haulMix) do
			if type(rec) ~= "table" then
				p.haulMix[key] = nil
			else
				local pile = math.max(0, math.floor(tonumber(rec.pay) or 0))
				local pileLoad = math.max(0, math.floor(tonumber(rec.load) or 0))
				-- Any desk buys any dirt. Every refusal here stranded a bag: the
				-- surface desk turned away deep dirt, and a depth desk turned away the
				-- shallow dirt you picked up on the way down -- so a mixed bag could be
				-- refused at BOTH ends with nowhere left to sell it.
				--
				-- Depth desks stay better because sellPayout multiplies for a seam;
				-- they no longer also get to say no. Currency still separates bigbang's
				-- space economy from coins, which is the one split that is real.
				local zoneOk = true
				--[[
					The surface desk is the UNIVERSAL buyer.
				
					It used to take only `shallow` dirt, and sections turn `mid` at layer
					481. So a bag filled any deeper was refused outright -- no coins, and
					`leftover` withheld the gems too -- while the record stayed in haulMix,
					so the bag never emptied. The only other buyer is the mid desk, which is
					gated behind seam 500. A player who dug past 481 before earning that had
					no reachable way to sell anything, ever: full bag, no coins, run over.
				
					Depth desks stay strictly better -- sellPayout only multiplies for a
					seam, so selling deep dirt up top pays the plain price it was mined for.
				]]
				local bandOk = true
				if rec.currency == currency and bandOk and zoneOk then
					if seam and okShop and Shop.sellPayout then
						pile = Shop.sellPayout(pile, zi, seam)
					end
					if currency == "space" then
						space += pile
					else
						haul += pile
					end
					drop[#drop + 1] = key
				elseif pile > 0 or pileLoad > 0 then
					leftover = true
				end
			end
		end
		for _, key in ipairs(drop) do
			p.haulMix[key] = nil
		end
		p._sellDesk = nil
	end
	coins += haul
	if not leftover then
		gems += math.floor(p.haulGems or 0)
		p.haulGems = 0
	end
	p.backpack = keep
	Dig.recountHaul(p)
	p.warnedFull = false
	p.gems += gems
	p.coins = (p.coins or 0) + coins * ((p.coinDouble and 2) or 1)
	p.spaceCoins = (p.spaceCoins or 0) + space * ((p.coinDouble and 2) or 1)
	snap(plr)
	if leftover then
		if haul > 0 or space > 0 then
			net:FireClient(plr, "toast", "Sold this outpost's dirt. The other dirt stays in the bag.")
		else
			net:FireClient(plr, "toast", "This buyer doesn't take that dirt.")
		end
	end
	if coins > 0 or gems > 0 or space > 0 then
		bumpStat(plr, p, "sells")
		-- Sell haul: meaningful pass XP (dig is 1/block; sell is a session beat).
		awardPassXp(plr, p, 25)
		introAdvance(plr, p, 2)
		p.sellHasteUntil = os.clock() + 20
		net:FireClient(plr, "sold", { coins = coins, gems = gems, space = space, haste = 20 })
	else
		net:FireClient(plr, "toast", "Nothing to sell")
	end
end

mint = function(def, userId, rollFinish)
	local id
	for _ = 1, 12 do
		local candidate = makeSerial(def)
		-- Accept won OR datastore error; only skip a candidate that is truly taken.
		if not userId or claimSerial(candidate, userId) ~= "taken" then
			id = candidate
			break
		end
	end
	id = id or makeSerial(def)
	local rosterPet = PetRoster and PetRoster.BY_NAME and PetRoster.BY_NAME[def.name]
	local card = {
		id = id,
		serial = id, -- PPP + 16-hex instance; never regenerated on trade/equip
		speciesHex = string.sub(id, 1, 3),
		setId = def.setId,
		index = def.index,
		cardKey = def.cardKey,
		name = def.name,
		rarityId = def.rarityId or (rosterPet and rosterPet.tier) or nil,
		typeId = def.typeId,
		animal = def.animal or (rosterPet and rosterPet.animal) or nil,
		variant = "Normal",
		powerLevel = 1,
		createdAt = DateTime.now().UnixTimestampMillis,
	}
	--[[
		rollFinish: give a pet the same shiny/shadow luck a pack gives.

		A pet bought from the store always came out Normal. The only pets that
		could ever be shiny or shadow were the ones a pack rolled, which meant
		paying for a pet was opting OUT of the best thing that can happen to
		one -- exactly backwards for the thing people spend Robux on.

		Same numbers as a pack open: MinePackConfig.SHINY_CHANCE (a percent),
		and one shiny in a hundred comes out Shadow instead
		(MineConfig.SHADOW_OF_SHINY). Pack opens decide the finish themselves
		before they call in here, so they pass nothing and are untouched.
	]]
	if rollFinish then
		local frng = Random.new()
		if frng:NextNumber() * 100 < (tonumber(Packs.SHINY_CHANCE) or 0) then
			if frng:NextNumber() < (tonumber(C.SHADOW_OF_SHINY) or 0.01) then
				card.shadow = true
			else
				card.shiny = true
			end
		end
	end
	return card
end

-- `chestId` is the chest this came from, decided at break time with the
-- breaker's luck. The reveal already uses it for naming and card count.
--
-- NOT YET WIRED: the chest's own rarity/variant tables. Card identity still
-- comes from Cards.rollPack (MineCards sets + mint), so switching the odds over
-- means replacing card minting with the MinePetRoster / MinePackConfig.SET_CARDS
-- pipeline -- that is the roster integration on the TODO, and doing half of it
-- here would break merging, salvaging and the binder.
-- `pk` is the pack entry from p.packs when there is one. A pack whose contents
-- were decided when the chest broke carries them in pk.rolled, and they are
-- minted here rather than re-rolled -- otherwise the odds would be rolled twice
-- and the pack you were holding would not be the pack you opened.
local function openPack(plr, setId, chestId, pk, collect)
	local p = profiles[plr.UserId]
	local chest = chestId and Packs.CHEST_BY_ID[chestId] or nil
	local made = {}

	--[[
		ONE ROLL POINT, AT OPEN, FROM THE PACK'S OWN TABLES.

		There used to be two. A pack found in the meadow had its contents decided
		at CHEST-BREAK and carried them on the entry as `rolled`; every other
		pack was rolled at OPEN from MineCards' set-tier table. Two tables that
		disagreed, and the pack inspector could only print one -- so for the
		commonest source of packs in the game it printed odds that did not
		govern.

		The pack's own table wins, because it is the one that tells packs apart:
		loam_pack is Exotic 0.03% and heirloom_pack is 1.50%, where the set-tier
		table gives every pack in a set the same number. Collapsing onto the set
		tier would have flattened the whole pack ladder.

		Rolling at open rather than at chest-break also means a pack sitting in
		the bag is not already decided: change the odds and every unopened pack
		follows, instead of a save full of packs frozen at whatever the rates
		were the day they dropped.

		`rolled` is still read if an old save has it, so packs banked before this
		change open as they were promised.
	]]
	local rng = Random.new()
	local packDef = (pk and pk.packId) and Packs.PACK_BY_ID[pk.packId] or nil
	do
		local ZonePacks = require(shared:WaitForChild("MineZonePacks"))
		local zdef = (pk and pk.packId) and ZonePacks.get(pk.packId) or nil
		if zdef then
			packDef = packDef or zdef
			if zdef.kind == "currency" then
				local crng = Random.new()
				local clo, chi = zdef.coins[1], zdef.coins[2]
				local glo, ghi = zdef.gems[1], zdef.gems[2]
				local coins = crng:NextInteger(clo, math.max(clo, chi))
				local gems = crng:NextInteger(glo, math.max(glo, ghi))
				p.coins = (p.coins or 0) + coins
				p.gems = (p.gems or 0) + gems
				-- Currency pouches are not card/equipment packs — skip packs quests.
				introAdvance(plr, p, 5)
				awardPassXp(plr, p, 10)
				local loot = {
					{ kind = "coins", name = coins .. " coins", rarityId = "Common" },
					{ kind = "gems", name = gems .. " gems", rarityId = "Rare" },
				}
				local design = {
					packId = zdef.id,
					name = zdef.name,
					setName = "Currency",
					kind = "currency",
				}
				if collect then
					design.cards = loot
					table.insert(collect, design)
					return
				end
				snap(plr)
				net:FireClient(plr, "opened", loot, design)
				return
			elseif zdef.kind == "ore_case" then
				--[[
					AN ORE CASE ALWAYS PAYS. A skin, or a charm. Nothing else.

					There is no roll here deciding whether the case was worth
					opening -- the 2% that dropped it already was that roll. The
					only question left is which of the two it is: one quarter
					charm, three quarters skin, which puts a charm at 0.5% per
					ore block broken.

					This replaced a version that rolled for a TOOL inside the
					case and paid ore when it missed. Tools are not found any
					more; they are forged. Ore is not a consolation prize; the
					block already dropped ore on its own.

					The charm is the one for THIS ore -- every ore has exactly
					one, generated from the roster, so there is no band lookup to
					come up empty. A skin is rolled from the same kit catalog and
					gets the same reel ceremony a bought case gets, because it is
					the same prize and should not read as a lesser one.
				]]
				local Temper = require(shared.MineTemper)
				local ore = C.oreById(zdef.oreId)
				local crng = Random.new()
				--[[
					A quarter charms, three quarters skins -- EXCEPT for a player
					who owns no charm yet, where the case pays the charm outright.
					Charms.caseCharmShare owns that rule, the same one the zone
					grant uses, so the two sources cannot drift apart on what
					"your first one" means.
				]]
				local share = Charms.caseCharmShare(
					Charms.ownsAnyCharm(p),
					tonumber(C.ORE_CASE_CHARM_SHARE) or 0.25)
				-- One of the ore's TWO charms, rolled evenly. They are different
				-- kinds rather than tiers, so weighting either would quietly make
				-- the other a consolation prize.
				local charm = ore and Charms.rollOreCharm and Charms.rollOreCharm(ore.id, crng) or nil

				if charm and crng:NextNumber() < share then
					--[[
						Charms tally rather than latch, the same as the zone
						grant: `p.charms[id]` is a COUNT that stays truthy for
						every reader asking only "do I own one".
					]]
					p.charms = p.charms or {}
					p.charms[charm.id] = (tonumber(p.charms[charm.id]) or 0) + 1
					-- Wearing nothing: put it on. A charm is most of a player's
					-- power budget, and the first one should be felt rather than
					-- found in a menu.
					local wearing = type(p.equippedCharm) == "string" and p.equippedCharm ~= ""
					if not wearing then
						p.equippedCharm = charm.id
					end
					bumpStat(plr, p, "packs")
					introAdvance(plr, p, 5)
					awardPassXp(plr, p, 10)
					local how = wearing and "equip it in Inventory → Equipment" or "equipped"
					local loot = { {
						kind = "charm",
						name = charm.name,
						rarityId = (ore and ore.band) or "Rare",
						blurb = (charm.blurb or "") .. "  ·  " .. how,
					} }
					local design = {
						packId = zdef.id,
						name = zdef.name,
						setName = "Ore Case",
						kind = "charm",
					}
					if collect then
						design.cards = loot
						table.insert(collect, design)
						return
					end
					snap(plr)
					net:FireClient(plr, "opened", loot, design)
					net:FireClient(plr, "toast", "Charm unlocked: " .. charm.name .. " — " .. how)
					return
				end

				-- A skin. Same roll and same ceremony as a bought temper case.
				local kit, rarity = Temper.rollTemperament(crng)
				if kit then
					p.tempers = p.tempers or {}
					local had = p.tempers[kit.id]
					if had then
						had.rarity = Temper.betterGrade(had.rarity, rarity)
						had.n = (tonumber(had.n) or 1) + 1
					else
						p.tempers[kit.id] = { rarity = Temper.normalizeRarity(rarity), n = 1 }
					end
					bumpStat(plr, p, "packs")
					introAdvance(plr, p, 5)
					awardPassXp(plr, p, 10)
					if collect then
						table.insert(collect, {
							packId = zdef.id,
							name = zdef.name,
							setName = "Ore Case",
							kind = "skin",
							cards = { {
								kind = "skin",
								name = kit.name,
								rarityId = Temper.normalizeRarity(rarity),
							} },
						})
						return
					end
					local reel, at = Temper.caseReel(crng, kit, rarity)
					snap(plr)
					net:FireClient(plr, "temperCase", {
						reel = reel, at = at, id = kit.id, name = kit.name,
						rarity = Temper.normalizeRarity(rarity),
						word = Temper.wordOf(rarity),
						dupe = had ~= nil,
						source = "ore_case",
						oreName = (ore and ore.name) or nil,
					})
					return
				end

				--[[
					The kit catalog came up empty, which it cannot do unless
					MineTemper is broken. Pay the charm rather than eat the case:
					a guarantee that silently pays nothing is worse than a
					guarantee that pays the other half of itself.
				]]
				if charm then
					p.charms = p.charms or {}
					p.charms[charm.id] = (tonumber(p.charms[charm.id]) or 0) + 1
					snap(plr)
					net:FireClient(plr, "toast", "Charm unlocked: " .. charm.name)
				else
					--[[
						Neither half could pay, which needs both MineTemper and the
						charm roster to be broken at once. GIVE THE CASE BACK: the
						caller removed it from the bag before opening it, so the
						toast was telling the truth only by accident.
					]]
					if pk then
						p.packs = p.packs or {}
						table.insert(p.packs, pk)
					end
					snap(plr)
					net:FireClient(plr, "toast", "That case could not be opened -- it is still in your bag")
				end
				return
			elseif zdef.kind == "ore" then
				--[[
					An ore pack ALWAYS pays ore. No rarity roll, no dud.

					That is the point of it. Chests carry the variance now; ore is
					the reliable line that keeps a tool you already own worth
					upgrading. Only the amount moves.
				]]
				local ore = C.oreById(zdef.oreId)
				local lo = (zdef.yield and zdef.yield[1]) or 1
				local hi = (zdef.yield and zdef.yield[2]) or lo
				local orng = Random.new()
				local got = orng:NextInteger(math.min(lo, hi), math.max(lo, hi))
				--[[
					The finder the pack was MINED with, not the one worn now --
					the pack stamped it at break time, so swapping pets after
					banking a pack cannot re-price what is already in the bag.

					Still CAPPED. An uncapped multiplier on a legacy pack is
					still an uncapped multiplier: upgrade costs are sized in HOURS
					of supply, so this is not "nicer drops", it is a shortcut past
					the cost curve for whoever stacked pets hardest.
					ORE_PACK_FIND_CAP holds the best case to about 2x unboosted.
				]]
				local find = math.max(0, tonumber(pk and pk.oreFind) or 0)
				find = math.min(find, tonumber(C.ORE_PACK_FIND_CAP) or 1)
				got = math.max(1, math.floor(got * (1 + find) + 0.5))
				local kept, spilled = Dig.addOre(p, zdef.oreId, got)
				if spilled > 0 then
					Dig.pouchFullToast(plr, p)
				end
				--[[
					Nothing fit. GIVE THE PACK BACK.

					Every caller of openPack table.removes the pack FIRST and then
					opens it, so returning here without re-inserting would delete
					it -- the player would lose the pack and get nothing for it.
					`collect` runs are the ten-pack path and re-insert the same
					way, since they removed it the same way.
				]]
				if kept <= 0 then
					if pk then
						p.packs = p.packs or {}
						table.insert(p.packs, pk)
					end
					net:FireClient(plr, "toast",
						"Pouch is full -- that pack stays in your bag until you make room")
					snap(plr)
					return
				end
				-- What the reveal shows is what actually went in.
				got = kept
				bumpStat(plr, p, "packs")
				--[[
					The reveal needs something to celebrate with, and every ore is
					Common on the card rarity scale, so grade it by BAND.

					`ore.band` is derived once in MineConfig from ORE_YIELD_BANDS,
					which already divides the roster into exactly these eight
					groups. Spelling the cutoffs out again here is what broke it
					last time: they were the 121-ore cuts
					(24/48/72/96/108/114/118), and after the trim to 82 the top
					four sat past the end of the roster -- nothing could grade
					above Epic, and the Legendary, Mythic, Divine and Exotic
					reveals were dead code.
				]]
				local tier = (ore and ore.tier) or 1
				local grade = (ore and ore.band)
					or select(1, C.oreBandForTier(tier))
					or "Common"
				local loot = { {
					kind = "ore",
					name = (ore and ore.name) or zdef.oreName or tostring(zdef.oreId),
					rarityId = grade,
					sub = string.format("%d ore", got),
					ore = { oreId = zdef.oreId, amount = got, tier = tier },
				} }
				local design = {
					packId = zdef.id,
					name = zdef.name,
					setName = "Ore",
					kind = "ore",
				}
				if collect then
					design.cards = loot
					table.insert(collect, design)
					return
				end
				snap(plr)
				net:FireClient(plr, "opened", loot, design)
				return
			--[[
				A legacy fossil PACK used to cash out HERE, on open, because the
				pack rows were still registered. They are not any more, and an
				unopened one is cashed out on load instead (see retireFossils),
				so by the time anyone can open a pack there is no fossil pack
				left to open.
			]]
			elseif zdef.kind == "cards" then
				-- Prefer zone pack odds; fall through to card open with packDef = zdef.
				packDef = zdef
				-- No forever-tool tease from fossil packs — tools are chest/fossil-bench/event/pass only.
			end
		end
	end
	--[[
		FOSSIL, RUNE AND GEAR PACKS.

		Everything a card pack does, with a different roller and a different
		bucket, and then it leaves before any of the card machinery below runs.
		Deliberately the same entry point, the same reveal payload and the same
		worst-to-best order: a player opening a Gear Vault should not be able to
		tell they are in a different code path, and the client should not need
		to learn a second shape to draw one.

		Items carry `rarityId` off the shared eight-name ladder, which is what
		makes that possible -- the sort below, the reveal's colour and hold
		timing, and the pull-grade screen effects all read that one field and
		neither know nor care that this is a rune.

		Written inline, and MineLootPacks required here rather than at the top of
		the file, because this script is at Luau's ceiling of 200 top-level
		locals: two more names up there and NOTHING in MineServer compiles.
	]]
	local Loot = require(shared:WaitForChild("MineLootPacks"))
	if packDef and Loot.isLoot(packDef.kind) then
		local loot = Loot.roll(packDef, rng, instanceHex16)
		for _, item in ipairs(loot) do
			if item.kind == "gear" and item.gear then
				p.gear = p.gear or {}
				local piece = item.gear
				local onGearQuest = math.floor(tonumber(p.intro) or 0) == 29
				if onGearQuest then
					local Gear = require(shared.MineGear)
					local rng = Random.new()
					local rarity, catalog = "SSS", nil
					for _, g in ipairs({ "SSS", "SS", "S", "A" }) do
						catalog = Gear.catalogFor("hat", g, nil, rng)
						if catalog then
							rarity = g
							break
						end
					end
					if catalog then
						local setId = catalog.setId or Gear.SETS[rng:NextInteger(1, #Gear.SETS)].id
						local made = Gear.makePiece(piece.id, setId, "hat", rarity, catalog)
						if made then
							piece = made
						end
					end
					p.introGearOpened = (p.introGearOpened or 0) + 1
				end
				table.insert(p.gear, piece)
				if onGearQuest then
					if p.introGearOpened >= 3 then
						introAdvance(plr, p, 29)
					else
						introSend(plr, p)
					end
				elseif math.floor(tonumber(p.intro) or 0) == 38 then
					introAdvance(plr, p, 38)
				end
			elseif item.kind == "rune" and item.rune then
				p.runes = p.runes or {}
				table.insert(p.runes, item.rune)
			end
		end
		-- Best last, exactly as for cards, and for the same reason: the order
		-- never going down is what tells you the next one is at least as good.
		table.sort(loot, function(x, y)
			local rx = (Cards.RARITY_RANK and Cards.RARITY_RANK[x.rarityId or ""]) or 0
			local ry = (Cards.RARITY_RANK and Cards.RARITY_RANK[y.rarityId or ""]) or 0
			if rx ~= ry then
				return rx < ry
			end
			return tostring(x.name or "") < tostring(y.name or "")
		end)
		-- Equipment packs count; gear/rune summons do not.
		if packDef.kind ~= "gear" and packDef.kind ~= "rune" then
			bumpStat(plr, p, "packs")
		end
		introAdvance(plr, p, 5)
		awardPassXp(plr, p, 15)
		if packDef.id then
			p.packsOpened = p.packsOpened or {}
			p.packsOpened[packDef.id] = (p.packsOpened[packDef.id] or 0) + 1
		end
		local design = {
			packId = packDef.id,
			name = (pk and pk.packName) or packDef.name or "Pack",
			setName = ({ rune = "Runes", gear = "Gear" })[packDef.kind] or "Loot",
			kind = packDef.kind,
		}
		if collect then
			design.cards = loot
			table.insert(collect, design)
			return
		end
		snap(plr)
		net:FireClient(plr, "opened", loot, design)
		return
	end
	-- Depth-scaled odds when this pack was dug at a known layer.
	if packDef and type(packDef) == "table" and pk and tonumber(pk.layer) and Packs.depthCardOdds then
		local maxL = C.LAYERS or 50
		if pk.zoneId == "meadow" or (tonumber(pk.layer) or 0) > (C.LAYERS or 50) then
			maxL = C.MINE1_LAYERS or 2500
		elseif pk.zoneId and C.zoneLayers then
			maxL = C.zoneLayers(pk.zoneId)
		elseif pk.packId and Packs.PACK_BY_ID and Packs.PACK_BY_ID[pk.packId] then
			maxL = C.MINE1_LAYERS or 2500
		end
		local heat = 0
		local slot = packDef.slot or ""
		local pid = tostring(pk.packId or "")
		if slot == "pack_legendary" or string.find(pid, "legendary", 1, true) or string.find(pid, "apex", 1, true) then
			heat = 2
		elseif slot == "pack_rare" or string.find(pid, "_rare", 1, true) then
			heat = 1
		end
		packDef = table.clone(packDef)
		packDef.odds = Packs.depthCardOdds(pk.layer, maxL, heat)
		packDef.depthLayer = nil
	end
	if pk and (pk.kind == "prototype" or (Tools.protoKindFromPack and Tools.protoKindFromPack(pk))) then
		local ZonePacks = require(shared:WaitForChild("MineZonePacks"))
		local rng = Random.new()
		local idx = tonumber(pk.section) or (((C.sectionIndex and C.sectionIndex(pk.layer or 1)) or math.floor(((pk.layer or 1) - 1) / 25)) + 1)
		local zoneId = pk.zoneId or "meadow"
		local r = rng:NextNumber() * 100
		local loot = {}
		local function addPack(slot, n)
			for _ = 1, (n or 1) do
				local packId = ZonePacks.id(zoneId, slot)
				local zpack = ZonePacks.get(packId)
				table.insert(p.packs, {
					packId = packId,
					packName = (zpack and zpack.name) or packId,
					zoneId = zoneId,
					layer = pk.layer,
					setId = pk.setId,
				})
				local rarityId = (slot == "pack_legendary") and "Legendary" or (slot == "pack_rare") and "Epic" or "Rare"
				table.insert(loot, { kind = "pack", name = (zpack and zpack.name) or slot, rarityId = rarityId })
			end
		end
		if r < 4 then
			-- Prototype crates used to mint forever tools on open. Never again —
			-- packs pay in packs/currency only. Jackpot = more legendaries.
			addPack("pack_legendary", 4)
			addPack("pack_rare", 1)
		elseif r < 24 then
			addPack("pack_legendary", (r < 12) and 2 or 1)
			addPack("pack_rare", 1)
		elseif r < 54 then
			addPack("pack_rare", (r < 34) and 2 or 1)
			addPack("pack_common", 1)
		elseif r < 79 then
			addPack("pack_common", 2)
			local gems = rng:NextInteger(80, 220) * idx
			p.gems = (p.gems or 0) + gems
			table.insert(loot, { kind = "gems", name = gems .. " gems", rarityId = "Rare" })
		else
			local coins = rng:NextInteger(400, 1200) * idx
			local gems = rng:NextInteger(40, 120) * idx
			p.coins = (p.coins or 0) + coins
			p.gems = (p.gems or 0) + gems
			table.insert(loot, { kind = "coins", name = coins .. " coins", rarityId = "Epic" })
			table.insert(loot, { kind = "gems", name = gems .. " gems", rarityId = "Legendary" })
		end
		table.sort(loot, function(x, y)
			local rx = (Cards.RARITY_RANK and Cards.RARITY_RANK[x.rarityId or ""]) or 0
			local ry = (Cards.RARITY_RANK and Cards.RARITY_RANK[y.rarityId or ""]) or 0
			if rx ~= ry then return rx < ry end
			return tostring(x.name) < tostring(y.name)
		end)
		bumpStat(plr, p, "packs")
		awardPassXp(plr, p, 25)
		local design = {
			packId = pk.packId,
			name = pk.packName or "Prototype bundle",
			setName = "Prototype",
			kind = "prototype",
		}
		if collect then
			design.cards = loot
			table.insert(collect, design)
			return
		end
		snap(plr)
		net:FireClient(plr, "opened", loot, design)
		return
	end
	-- Event Horizon packs mint only Event Horizon pets.
	if pk and pk.zoneId == "bigbang" then
		if not (C.isEventHorizonSet and C.isEventHorizonSet(setId)) then
			local zone = C.zoneById("bigbang")
			setId = (C.setForLayer and C.setForLayer(zone, pk.layer or 1))
				or (zone and zone.sets and zone.sets[1])
				or "genesis_spark"
		end
	end
	local want = (packDef and packDef.cards) or (chest and chest.cards) or 3
	local rowShiny = pk and tonumber(pk.shiny)
	local shinyPct = rowShiny or (packDef and tonumber(packDef.shiny)) or Packs.SHINY_CHANCE or 0
	local legacy = (pk and type(pk.rolled) == "table" and #pk.rolled > 0) and pk.rolled or nil
	if legacy then
		want = #legacy
	else
		-- Luck siphons odds (Epic-first into chase). Same card count.
		-- A sealed row can also stamp its own shiny percent (Shiny Packs).
		local packLuck = tonumber(pk and pk.luck) or 1
		if packDef and (packLuck > 1 or rowShiny) then
			packDef = table.clone(packDef)
			if packLuck > 1 then
				packDef.luck = packLuck
			end
			if rowShiny then
				packDef.shiny = rowShiny
			end
		end
	end
	-- God Pack: any card pack, half that pack's Exotic rate, Mythic+ only.
	local isGodPack = false
	if not legacy and packDef and Packs.rollIsGodPack then
		isGodPack = Packs.rollIsGodPack(packDef, rng) and true or false
	end
	-- Only needed when the pack has no odds table of its own (a crate, or an
	-- entry that never carried a packId).
	local fallback
	if not legacy and not (packDef and packDef.odds) then
		fallback = Cards.rollPack(setId, rng, want)
	end
	-- Card -> { exact, form } odds for the reveal only; see Packs.pullOdds.
	local pulled = {}
	-- What share of this pack's shinies come out Shadow. One in a hundred
	-- everywhere, one in twenty in the Shiny Pack. Read once, and the same
	-- number prices the "1 in X" below, so the odds shown are the odds rolled.
	local shadowShare = (Packs.shadowOfShiny and Packs.shadowOfShiny(packDef and packDef.id, C.SHADOW_OF_SHINY))
		or (C.SHADOW_OF_SHINY or 0.01)

	for slot = 1, want do
		local def, variant, isShiny, poolN
		if legacy then
			local r = legacy[slot]
			variant, isShiny = r.variant, r.shiny
			local pool = Cards.indicesOfRarity and Cards.indicesOfRarity(setId, r.tier or "Common") or {}
			if #pool == 0 and Cards.indicesOfRarity then
				pool = Cards.indicesOfRarity(setId, "Common") or {}
			end
			local index = (#pool > 0) and pool[rng:NextInteger(1, #pool)] or 1
			def = Cards.getCard and Cards.getCard(setId, index) or nil
		elseif packDef and packDef.odds then
			local roll = (isGodPack and Packs.rollGodCard)
				and Packs.rollGodCard(packDef, rng)
				or Packs.rollCard(packDef, rng)
			variant, isShiny = roll.variant, roll.shiny
			local pool = Cards.indicesOfRarity and Cards.indicesOfRarity(setId, roll.tier) or {}
			if #pool == 0 and Cards.indicesOfRarity then
				pool = Cards.indicesOfRarity(setId, "Common") or {}
			end
			-- This pack's slice of that rarity, not the whole set: two packs of
			-- one set used to be the same pack in a different wrapper.
			if Packs.cardPoolFor then
				pool = Packs.cardPoolFor(packDef, pool)
			end
			local index = (#pool > 0) and pool[rng:NextInteger(1, #pool)] or 1
			def = Cards.getCard and Cards.getCard(setId, index) or nil
			poolN = #pool
		else
			def = fallback and fallback[slot]
			variant = "Normal"
			isShiny = rng:NextNumber() * 100 < shinyPct
		end
		if def then
			local c = mint(def, plr.UserId)
			if variant and variant ~= "Normal" then
				c.variant = variant
			end
			--[[
				Shiny and Shadow are luck, not rungs. They ride on top of
				whatever variant the card rolled -- the ladder is what merging
				climbs -- so a Golden card can be shiny as well.

				One shiny in a HUNDRED comes out Shadow instead. The Shiny
				Pack is the exception and the only one: one in twenty there,
				so it is the pack you open hunting a shadow rather than just
				more foil (MinePackConfig.SHADOW_OF_SHINY).
			]]
			if isShiny then
				if rng:NextNumber() < shadowShare then
					c.shadow = true
				else
					c.shiny = true
				end
			end
			-- The odds that actually rolled this card, in this form, from this
			-- pack. Kept off the saved card: the reveal gets a copy.
			if poolN and poolN > 0 and Packs.pullOdds then
				local exact, form = Packs.pullOdds(packDef, c, poolN, want, shadowShare)
				pulled[c] = { exact = exact, form = form }
			end
			table.insert(p.cards, c)
			table.insert(made, c)
		end
	end
	--[[
		BEST CARD LAST. ALWAYS.

		Cards come out of the mint in roll order, so the Legendary lands in
		slot one about as often as anywhere else and the remaining flips are a
		formality. Sorting the pack worst-to-best before it leaves the server
		fixes every reveal at once.

		It also makes the reveal READABLE, which is the real point: because the
		order never goes down, a good second card tells the player the third is
		at least as good. That escalation is the entire tension of opening a
		pack, and mint order was throwing it away.

		Done here rather than in the reveal so the client cannot be lied to
		about which card is the hit, and so a pack shown inside a batch comes
		out in the same order as one opened on its own.
	]]
	--[[
		By the odds when every card has them. A Rainbow Legendary is rarer than
		a plain Mythic, so it is the one that comes out last -- the rarity
		ladder alone got that backwards.
	]]
	local byOdds = #made > 0
	for _, c in ipairs(made) do
		if not (pulled[c] and pulled[c].form) then
			byOdds = false
			break
		end
	end
	-- In the order the reveal celebrates them (the rarity ladder, commons and
	-- uncommons capped) so the pack only ever gets louder, then by the true
	-- odds inside a band -- a Rainbow Legendary still lands after a Mythic.
	local bandOf = {}
	do
		local PackFX = require(shared:WaitForChild("MinePackFX"))
		local ORDER = PackFX.BAND_ORDER or {}
		for _, c in ipairs(made) do
			local _, band = PackFX.pullScore(c, Cards)
			bandOf[c] = ORDER[band] or 1
		end
	end
	table.sort(made, function(x, y)
		if (bandOf[x] or 1) ~= (bandOf[y] or 1) then
			return (bandOf[x] or 1) < (bandOf[y] or 1)
		end
		if byOdds then
			local fx, fy = pulled[x].form, pulled[y].form
			if fx ~= fy then
				return fx < fy
			end
			return tostring(x.name or "") < tostring(y.name or "")
		end
		local rx = (Cards.RARITY_RANK and Cards.RARITY_RANK[x.rarityId or ""]) or 0
		local ry = (Cards.RARITY_RANK and Cards.RARITY_RANK[y.rarityId or ""]) or 0
		if rx ~= ry then
			return rx < ry
		end
		local vx = (Cards.VARIANT_RANK and Cards.VARIANT_RANK[x.variant or "Normal"]) or 1
		local vy = (Cards.VARIANT_RANK and Cards.VARIANT_RANK[y.variant or "Normal"]) or 1
		-- Finishes sit above the ladder: shadow, then shiny.
		vx += (x.shadow and 10) or (x.shiny and 5) or 0
		vy += (y.shadow and 10) or (y.shiny and 5) or 0
		if vx ~= vy then
			return vx < vy
		end
		return tostring(x.name or "") < tostring(y.name or "")
	end)
	--[[
		What the reveal is sent: the minted cards with their odds on. Copies,
		so the odds never reach the save. `oneIn` (the exact card, in its form,
		from this pack) only travels past 1 in 200 -- the ribbon is for pulls
		worth bragging about -- while `oddsForm` rides on every card so the
		reveal can react to how rare it really was.

		(The chase-pet "YOU FOUND SOME CRAZY SHIT" caption that used to fire
		here is gone: the pet is already the last card of this very pack.)
	]]
	local shown = made
	if next(pulled) then
		shown = {}
		for i, c in ipairs(made) do
			local o = pulled[c]
			if o then
				local v = table.clone(c)
				v.oddsForm = o.form and math.floor(o.form * 10 + 0.5) / 10 or nil
				-- Rare and up only: a "1 in 651" on a Golden Common reads as
				-- a celebration the card does not deserve.
				local rank = (Cards.RARITY_RANK and Cards.RARITY_RANK[c.rarityId or ""]) or 1
				if o.exact and o.exact >= 200 and rank >= 3 then
					v.oneIn = math.floor(o.exact + 0.5)
				end
				shown[i] = v
			else
				shown[i] = c
			end
		end
	end
	local best, bestRank = nil, 0
	for _, c in ipairs(shown) do
		if type(c) == "table" then
			local rank = (Cards.RARITY_RANK and Cards.RARITY_RANK[c.rarityId or ""]) or 1
			local hot = rank >= 6 or (c.shiny and rank >= 5)
			if hot and rank >= bestRank then
				best, bestRank = c, rank
			end
		end
	end
	if best or isGodPack then
		local who = (plr.DisplayName ~= "" and plr.DisplayName) or plr.Name
		local text
		if best then
			local finish = ""
			if best.variant and best.variant ~= "Normal" and best.variant ~= "" then
				finish = tostring(best.variant) .. " "
			end
			if best.shiny then
				finish = "Shiny " .. finish
			end
			text = string.format("%s pulled %s%s%s", who, isGodPack and "a GOD PACK — " or "", finish, tostring(best.name or best.rarityId or "a chase card"))
		else
			text = who .. " pulled a GOD PACK"
		end
		net:FireAllClients("sysChat", {
			text = text,
			color = isGodPack and "#FF5AD8" or "#FFD56A",
		})
	end
	bumpStat(plr, p, "packs")
	introAdvance(plr, p, 5)
	awardPassXp(plr, p, 15)
	-- pk.packId only. `packDef0` is declared inside the else-branch above, so
	-- naming it here would read as a nil global rather than the pack def --
	-- silently dead, and no error to tell you.
	local openedId = pk and pk.packId
	if openedId then
		p.packsOpened = p.packsOpened or {}
		p.packsOpened[openedId] = (p.packsOpened[openedId] or 0) + 1
	end
	local set = Cards.SETS and Cards.SETS[setId]
	local design = {
		packId = pk and pk.packId or nil,
		name = (pk and pk.packName)
			or (pk and pk.tier and C.PACK_TIERS[pk.tier])
			or (chest and chest.name)
			or "Booster Pack",
		setName = (set and set.displayName) or setId,
	}
	if isGodPack then
		design.godpack = true
		design.name = "GOD PACK"
		net:FireClient(plr, "toast", "GOD PACK — Mythic and up!")
	end
	-- Collecting: the caller is assembling a run and will send and snapshot
	-- once at the end. Snapping per pack would be fifty snapshots for one
	-- "open 50", and firing per pack would race the reveal.
	-- New cards just landed; the first natural three-of-a-kind fires the
	-- one-shot merge nudge (never during the early tutorial, never twice).
	maybeMergePrompt(plr, p)
	if collect then
		design.cards = shown
		table.insert(collect, design)
		return
	end
	snap(plr)
	net:FireClient(plr, "opened", shown, design)
end

-- Chest flagships. These are the only tools in the game that are not bought,
-- and each one drops from exactly one named chest at roughly one in ten
-- thousand -- so a player can chase a specific chest for a specific tool rather
-- than hoping a generic rare fires.
--
-- Rolled on OPEN, not on break, because the chest is the thing being opened and
-- luck should read the same way it does for cards.
-- Declared here, not beside its definition below: rollChestTool calls it,
-- and a local declared after its reader is a nil global to that closure.
local rollBigBangPet
local function rollChestTool(plr, p, chestId, b, ctx)
	ctx = ctx or {}
	local zoneId = ctx.zoneId
	local layer = tonumber(ctx.layer) or 1
	local band = (C.depthBand and C.depthBand(layer)) or (Depth and Depth.bandForLayer and Depth.bandForLayer(layer)) or "shallow"
	-- Merge ultra-rare flagships + band forever ladder (80 tools: 3/2/3 × 10 zones).
	local pool = {}
	local seen = {}
	local function addPool(list)
		for _, t in ipairs(list or {}) do
			if t and t.id and not seen[t.id] then
				seen[t.id] = true
				table.insert(pool, t)
			end
		end
	end
	if chestId then
		addPool(Tools.dropsFor(chestId))
	end
	if zoneId and Tools.dropsForLayer then
		addPool(Tools.dropsForLayer(zoneId, layer))
	elseif zoneId and Tools.dropsForBand then
		addPool(Tools.dropsForBand(zoneId, band))
	end
	if #pool == 0 then
		return
	end
	local luck = (b and b.chestLuck or 1)
	local rng = Random.new()
	local got
	local function announce(name, shiny, kind, blurb, shadow, nightmare, oneIn, extra)
		local found = {
			name = name,
			shiny = shiny and true or false,
			shadow = shadow and true or false,
			nightmare = nightmare and true or false,
			oneIn = oneIn,
			kind = kind or "tool",
			blurb = blurb or "You found some crazy shit",
		}
		-- The model to draw (baseName/family), and the odds the reveal ranks by.
		for k, v in pairs(extra or {}) do
			found[k] = v
		end
		net:FireClient(plr, "foundTool", found)
	end
	if #pool > 0 then
		p.chestTools = p.chestTools or {}
		local held = {}
		for _, row in ipairs(p.chestTools) do
			held[(type(row) == "table") and row.id or row] = true
		end
		local candidates = {}
		for _, t in ipairs(pool) do
			-- Owning one no longer takes it out of the pool; it just makes it
			-- rarer (Const.DUPE_DROP_WEIGHT), so a band keeps dropping forever
			-- instead of going silent the moment you complete it.
			if t and t.id and foreverToolZoneOk(p, t) then
				table.insert(candidates, t)
			end
		end
		-- Widen to whole-zone tools so Epic find % is identical every layer.
		if zoneId and Tools.dropsForZone then
			for _, t in ipairs(Tools.dropsForZone(zoneId) or {}) do
				if t and t.id and not seen[t.id] and foreverToolZoneOk(p, t) then
					seen[t.id] = true
					table.insert(candidates, t)
				end
			end
		end
		-- Global rarity chance (Rare+). Same Epic % in zone 1 layer 10 and zone 10 layer 5000.
		local rarity = Tools.rollChestRarity and Tools.rollChestRarity(rng, luck)
		if not rarity then
			return
		end
		local matched = (Tools.toolsOfRarity and Tools.toolsOfRarity(candidates, rarity)) or {}
		if #matched == 0 then
			return
		end
		-- Prefer tools from the current layer/band pool when several share the rarity.
		local layerIds = {}
		for _, t in ipairs(pool) do
			if t and t.id then layerIds[t.id] = true end
		end
		local preferred = {}
		for _, t in ipairs(matched) do
			if layerIds[t.id] then table.insert(preferred, t) end
		end
		local finalists = (#preferred > 0) and preferred or matched
		local pick
		do
			local totalW = 0
			local weights = {}
			for i, t in ipairs(finalists) do
				local w = held[t.id] and (Const.DUPE_DROP_WEIGHT or 0.35) or 1
				weights[i] = w
				totalW += w
			end
			local roll = rng:NextNumber() * math.max(totalW, 1e-9)
			local acc = 0
			for i, t in ipairs(finalists) do
				acc += weights[i]
				if roll <= acc then
					pick = t
					break
				end
			end
			pick = pick or finalists[1]
		end
		if pick then
			-- Shiny and shadow live in lucky seams and nowhere else. A tool pulled
			-- from ordinary rock comes out plain however deep it was found.
			local shiny, shadow, nightmare = false, false, false
			if C.isLuckyLayer and C.isLuckyLayer(zoneId, layer) then
				if rng:NextNumber() < (C.LUCKY_SHADOW_CHANCE or 0.01) then
					local under = layer < (Tools.NIGHTMARE_MAX_LAYER or 2500)
					if under and rng:NextNumber() < (Tools.NIGHTMARE_OF_SHADOW or 0.05) then
						nightmare = true
					else
						shadow = true
					end
				elseif rng:NextNumber() < (C.LUCKY_SHINY_CHANCE or 0.30) then
					shiny = true
				end
			end
			--[[
				A SECOND COPY IS A COUNT, NOT A SECOND ROW.

				chestTools rows are addressed by id -- equipping, socketing,
				selling and the temper fit all look a tool up by it -- so two
				rows sharing an id would make every one of those ambiguous about
				which copy it meant. A plain duplicate bumps `count` on the row
				you already have.

				A FINISH is the exception: a Shiny or Shadow copy of a tool you
				own plain is a genuinely different object and earns its own row.
			]]
			local sameRow = nil
			if not (shiny or shadow or nightmare) then
				for _, row in ipairs(p.chestTools) do
					if type(row) == "table" and row.id == pick.id
						and not (row.shiny or row.shadow or row.nightmare) then
						sameRow = row
						break
					end
				end
			end
			if sameRow then
				sameRow.count = (tonumber(sameRow.count) or 1) + 1
			else
				table.insert(p.chestTools, {
					id = pick.id, name = pick.name, family = pick.family,
					shiny = shiny or nil, shadow = shadow or nil, nightmare = nightmare or nil,
				})
			end
			local label = ((nightmare and "Nightmare ") or (shadow and "Shadow ") or (shiny and "Shiny ") or "") .. pick.name
			-- The chance of THIS tool in THIS finish from THIS chest, with the
			-- luck that rolled it (MineTools.exactOneIn). The reveal only puts a
			-- "1 in X" on it past 1 in 150 -- actually rare -- but ranks by it
			-- either way.
			local oneIn = (Tools.exactOneIn and Tools.exactOneIn(pick.drop, luck, shiny, shadow, nightmare, layer))
				or (Tools.oneInOf and Tools.oneInOf(pick.drop, shiny, shadow, nightmare)) or nil
			net:FireClient(plr, "toast", string.format("%s! %s", label, pick.blurb or ""))
			net:FireClient(plr, "loot", {
				text = label, color = nightmare and Color3.fromRGB(220, 20, 40) or Color3.fromRGB(255, 210, 90), pos = nil,
			})
			announce(label, shiny, "tool", pick.blurb, shadow, nightmare, (oneIn and oneIn >= 150) and oneIn or nil, {
				baseName = pick.modelName or pick.name, family = pick.family,
				power = math.min(tonumber(pick.power) or 0, foreverPowerCap(p)),
				oddsForm = oneIn,
				-- The reveal escalates off the card's rarityId (MinePackReveal ranks it,
				-- and the top band gets twice the confetti). Nothing was sending one, so
				-- foundReveal fell through to its "Legendary" default and an Exotic got
				-- exactly the same ceremony as a Common. Send the real grade.
				rarityId = pick.rarity or pick.rarityId
					or ((pick.rarityTag == "extreme") and "Mythic")
					or ((pick.rarityTag == "rare") and "Rare")
					or nil,
			})
			got = pick
		end
	end
	-- Occasional dig potion from chests (independent of tool drop).
	do
		local rng2 = Random.new()
		local chance = 0.07 * ((b and b.chestLuck) or 1)
		if rng2:NextNumber() < math.min(0.22, chance) then
			pcall(function()
				local Potions = require(shared:WaitForChild("MinePotions"))
				local def = Potions.roll(rng2)
				if def and Potions.grant(p, def.id, 1) then
					net:FireClient(plr, "toast", "Potion: " .. def.name)
					net:FireClient(plr, "loot", {
						text = def.name, color = Color3.fromRGB(120, 220, 160), pos = nil,
					})
				end
			end)
		end
	end
	-- Prototype family crates. Bag is 2x the pick crate. Opening any crate is
	-- still 1-in-25 for the named item.
	local layer = tonumber(ctx.layer)
	if layer and Tools.BUNDLE_DROP then
		local idx = ((C.sectionIndex and C.sectionIndex(layer)) or math.floor((layer - 1) / 25)) + 1
		local kinds = { "pick", "bag", "expl", "drill" }
		for _, kind in ipairs(kinds) do
			local prefix, drop, blurb = "proto_bundle_", Tools.BUNDLE_DROP, "A sealed prototype crate. Something in here is illegal."
			if Tools.protoBundleMeta then
				prefix, drop, blurb = Tools.protoBundleMeta(kind)
			end
			if rng:NextNumber() < ((drop or Tools.BUNDLE_DROP) * luck) then
				local bundleName = (Tools.protoName and Tools.protoName(idx, kind) or ("p." .. idx)) .. " bundle"
				p.packs = p.packs or {}
				table.insert(p.packs, {
					kind = "prototype",
					protoKind = kind,
					packId = prefix .. idx,
					packName = bundleName,
					zoneId = ctx.zoneId,
					layer = layer,
					section = idx,
					setId = ctx.setId,
				})
				announce(bundleName, false, "bundle", blurb, nil, nil, nil, { packId = prefix .. idx })
			end
		end
	end
	rollBigBangPet(plr, p, chestId, b)
	return got
end

-- Event Horizon limited pets: Matter+/Matter-/Albert Minestein/Cosmo from Event Horizon chests.
local BIGBANG_PET_DROPS = {
	{ name = "Matter+", drop = 0.0001 },
	{ name = "Matter-", drop = 0.0001 },
	{ name = "Albert Minestein", drop = 0.00004 },
	{ name = "Cosmo", drop = 0.00004 },
}

function rollBigBangPet(plr, p, chestId, b)
	if type(chestId) ~= "string" or not string.find(chestId, "bigbang", 1, true) then
		return
	end
	p.cards = p.cards or {}
	local owned = {}
	for _, c in ipairs(p.cards) do
		if type(c) == "table" and type(c.name) == "string" then
			owned[c.name] = true
		end
	end
	local luck = (b and b.chestLuck or 1)
	local rng = Random.new()
	for _, row in ipairs(BIGBANG_PET_DROPS) do
		if not owned[row.name] and rng:NextNumber() < (row.drop or 0) * luck then
			local def = {
				setId = "genesis_spark",
				index = 1,
				cardKey = "bigbang:" .. row.name,
				name = row.name,
				rarityId = "Exotic",
				typeId = "Crystal",
				roleName = "Limited",
				kind = "Unit",
				setName = "Event Horizon",
			}
			local c = mint(def, plr.UserId)
			table.insert(p.cards, c)
			net:FireClient(plr, "toast", "Pet: " .. row.name)
			net:FireClient(plr, "loot", {
				text = row.name, color = Color3.fromRGB(255, 80, 120), pos = nil,
			})
			markDirty(plr)
			return c
		end
	end
	return nil
end

local function packOpenBoosts(pk, live)
	local stamped = pk and tonumber(pk.luck)
	if stamped and stamped > 1 then
		-- Tool odds for this pack open use stamped luck only (not live chestLuck).
		return { chestLuck = stamped, luck = stamped }
	end
	return live
end

local function openFrom(plr)
	local p = profiles[plr.UserId]
	local bb = boosts(p)
	for i, item in ipairs(p.backpack) do
		if item.kind == "chest" or item.kind == "crate" then
			table.remove(p.backpack, i)
			openPack(plr, item.setId or "dragons_dawn", item.chestId)
			rollChestTool(plr, p, item.chestId, bb, { layer = item.layer, zoneId = item.zoneId, setId = item.setId })
			return
		end
	end
	if #p.packs > 0 then
		local pk = table.remove(p.packs, 1)
		openPack(plr, pk.setId, pk.chestId, pk)
		-- Forever tools never roll from packs — only real chests / fossils / events / pass.
	else
		net:FireClient(plr, "toast", "No packs to open")
	end
end
-- Open one specific pack. The inventory lists them individually, so "open the
-- first one you find" is not good enough any more.
local function openAt(plr, payload)
	local p = profiles[plr.UserId]
	-- { uid = "..." } names one exact pack; a bare number is the old index.
	local uid = (type(payload) == "table") and payload.uid or nil
	local index = tonumber((type(payload) == "table") and payload.index or payload)
	local pk, at
	if uid then
		for i, entry in ipairs(p.packs or {}) do
			if type(entry) == "table" and entry.uid == uid then
				pk, at = entry, i
				break
			end
		end
	end
	if not pk and index then
		pk, at = p.packs[index], index
	end
	if not pk then
		return openFrom(plr)
	end
	table.remove(p.packs, at)
	if pk.kind == "lucky_block" or (pk.blockId and require(shared.MineLuckyBlocks).def(pk.blockId or pk.packId)) then
		openLuckyBlock(plr, pk)
		return
	end
	openPack(plr, pk.setId, pk.chestId, pk)
	-- Forever tools never roll from packs — only real chests / fossils / events / pass.
end

--[[
	Open a run of packs in one request.

	The reveal used to fire "openAt" once per pack and wait out the entire
	ceremony before asking for the next -- fine for one pack, a round trip
	between every card for ten. This hands the whole run back at once so the
	reveal plays them back to back at whatever speed the player taps.

	`packId` narrows the run to one kind, which is what "open all of THIS pack"
	means on the tile. Without it the run goes worst-pack-first, so a stack
	builds toward its best pack instead of spending it immediately.

	`count` is what the player ASKED for. Fewer in the bag means they get what
	they have and the reply says so -- the prompt offers "open 10" off a stack
	of 6 on purpose, and it has to pay out 6 rather than refuse.
]]
-- Share of AFK packs that come from your DEEPEST unlocked zone. The rest
-- come from the zones below it (Verbs.Afk.grantPack).
Const.AFK_TOP_ZONE_SHARE = 0.20
--[[
	How much likelier a tool you do NOT own is than a second copy of one you do.

	Duplicates were simply impossible: the chest roll filtered out anything you
	held, so once you owned a band's tools that band stopped dropping. Copies are
	worth having -- they trade and they sell -- but a 1-in-400 chase should not
	be handing you your fourth identical pick, so a duplicate rolls at a quarter
	weight and collection still leads.
]]
Const.DUPE_DROP_WEIGHT = 0.25
-- Const.OPEN_RUN_MAX on Const
local function openMany(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(p.packs) ~= "table" then
		return
	end
	payload = (type(payload) == "table") and payload or {}
	local packId = payload.packId
	local want = math.clamp(math.floor(tonumber(payload.count) or 1), 1, Const.OPEN_RUN_MAX)
	-- Gear / Rune cases: hard cap 3 concurrent reels. No Open All.
	do
		local def = packId and Packs.PACK_BY_ID[packId]
		if def and (def.kind == "gear" or def.kind == "rune") then
			want = math.min(want, 3)
		end
	end
	-- The pack the player actually tapped, by its own id. Only the first open
	-- of the run is pinned to it; the rest follow the usual order.
	local lead = (type(payload.uid) == "string") and payload.uid or nil

	local bb = boosts(p)
	local run = {}
	while #run < want do
		-- Re-scan every step: each open removes a pack and shifts the rest, so
		-- a cached index list would open the wrong packs after the first.
		local pick, pickRank = nil, math.huge
		if lead then
			for i, pk in ipairs(p.packs) do
				if pk.uid == lead then
					pick = i
					break
				end
			end
			lead = nil
		end
		if not pick then
			for i, pk in ipairs(p.packs) do
				if packId then
					if pk.packId == packId then
						pick = i
						break
					end
				else
					local rank = (Packs.packTier and Packs.packTier(pk.packId)) or 0
					if rank < pickRank then
						pickRank, pick = rank, i
					end
				end
			end
		end
		if not pick then
			break
		end
		local pk = table.remove(p.packs, pick)
		if pk.kind == "lucky_block" or (pk.blockId and require(shared.MineLuckyBlocks).def(pk.blockId or pk.packId)) then
			openLuckyBlock(plr, pk)
			-- Count as one opened for the run budget; no card reveal payload.
			table.insert(run, { luckyBlock = true, blockId = pk.blockId or pk.packId })
		else
			openPack(plr, pk.setId, pk.chestId, pk, run)
			-- Forever tools never roll from packs (including open-10).
		end
	end

	if #run == 0 then
		net:FireClient(plr, "toast", "No packs to open")
		return
	end
	-- Pin the kind that was actually opened. Continue-open and packsOpened
	-- attribution must follow this stack, not whatever the player taps next.
	if type(packId) ~= "string" or packId == "" then
		for _, design in ipairs(run) do
			local id = design and design.packId
			if type(id) == "string" and id ~= "" and not design.luckyBlock then
				packId = id
				break
			end
		end
	end
	-- How many of the SAME kind are still in the bag, so the prompt can offer
	-- another run without a second request -- and know when to stop offering.
	local left = 0
	local openedN = 0
	for _, design in ipairs(run) do
		if not design.luckyBlock then
			openedN += 1
		end
	end
	for _, pk in ipairs(p.packs) do
		if packId then
			if pk.packId == packId then
				left += 1
			end
		else
			left += 1
		end
	end
	snap(plr)
	net:FireClient(plr, "openedRun", run, { packId = packId, left = left, opened = openedN })
end

local function equip(plr, payload)
	local id, seat = payload, nil
	if type(payload) == "table" then
		id = payload.id or payload.cardId
		seat = tonumber(payload.slot or payload.seat or payload.pet)
	end
	local p = profiles[plr.UserId]
	if not cardById(p, id) then return end
	local already = false
	for _, e in ipairs(p.equipped) do
		if e == id then already = true break end
	end
	if already and not seat then return end
	for i, e in ipairs(p.equipped) do
		if e == id then table.remove(p.equipped, i) break end
	end
	local cap = C.effectivePetSlots and C.effectivePetSlots(p) or p.petSlots
	if seat then
		seat = math.clamp(math.floor(seat), 1, cap)
		if seat > #p.equipped + 1 then
			seat = #p.equipped + 1
		end
		table.insert(p.equipped, seat, id)
		while #p.equipped > cap do
			table.remove(p.equipped)
		end
	else
		if #p.equipped >= cap then table.remove(p.equipped, 1) end
		table.insert(p.equipped, id)
	end
	introAdvance(plr, p, 6)
	walk(plr)
	snap(plr)
end

local function unequip(plr, id)
	local p = profiles[plr.UserId]
	for i, e in ipairs(p.equipped) do
		if e == id then table.remove(p.equipped, i) break end
	end
	walk(plr)
	snap(plr)
end

local function merge(plr, ids, useDust)
	local p = profiles[plr.UserId]
	if type(ids) ~= "table" or #ids < 1 then return end
	local a = cardById(p, ids[1])
	if not a then return end
	local nextV = C.nextVariant(a.variant or "Normal")
	if not nextV then net:FireClient(plr, "toast", "Already Rainbow") return end
	local matched = {}
	for _, c in ipairs(p.cards) do
		if c.cardKey == a.cardKey and c.rarityId == a.rarityId and (c.variant or "Normal") == (a.variant or "Normal") then
			table.insert(matched, c)
		end
	end
	local dustAssist = false
	if #matched < 3 then
		if useDust and #matched >= 2 then
			local cost = math.floor(80 * (C.RARITY_MULT[a.rarityId] or 1))
			cost = C.vipPrice(cost, hasVipPass(plr))
			if p.dust < cost then net:FireClient(plr, "toast", "Need dust to fill the 3rd copy") return end
			p.dust -= cost
			dustAssist = true
		else
			net:FireClient(plr, "toast", "Need 3 identical copies (same rarity + variant)")
			return
		end
	end
	local keep, burnCount, burned = matched[1], dustAssist and 1 or 2, 0
	for i = #p.cards, 1, -1 do
		local c = p.cards[i]
		if c.id ~= keep.id and c.cardKey == keep.cardKey and c.rarityId == keep.rarityId and (c.variant or "Normal") == (keep.variant or "Normal") then
			if burned < burnCount then table.remove(p.cards, i) burned += 1 end
		end
	end
	keep.variant = nextV
	bumpStat(plr, p, "merges")
	snap(plr)
	net:FireClient(plr, "toast", keep.name .. " became " .. nextV .. " (" .. keep.rarityId .. ")")
end

--[[
	The Scrapper. It only ever ate cards, and only ever paid stardust, so a bad
	rune or a Common helmet had nowhere to go and just sat in the list forever.

	`payload` is { kind = "card"|"rune"|"gear"|"pack", id = ..., into = "dust"|"gems" }.
	Cards and unopened card packs can go either way; runes and gear always pay gems, because stardust is
	the card economy and mixing them would let you launder one into the other.
]]
--[[
	Scrap a whole selection in one request.

	scrapItem handles exactly one item and ends with its own snapshot and its
	own toast. Scrapping forty duplicates through it is forty snapshots and
	forty toasts, which is why the Scrapper had no multi-select: the plumbing
	could not carry one.

	This resolves every id first, pays once, snapshots once, and reports one
	total. Unknown or protected ids are skipped rather than failing the batch --
	a selection built against a slightly stale snapshot should still scrap the
	forty things that are real.
]]
-- Const.SCRAP_MAX on Const
--[[
	What a pack is worth as scrap.

	DEFINED ABOVE scrapMany, and that matters: it used to sit below it, and a
	`local function` is not in scope inside a function written earlier in the
	file -- the name compiles as a global read instead. So the pack arm of bulk
	scrapping called a nil value and threw on every use. Verified with a minimal
	repro before moving it.
]]
local function packScrapDustFor(pk)
	if type(pk) ~= "table" then
		return 0
	end
	local packId = pk.packId
	if type(packId) == "string" and packId ~= "" then
		return Packs.packScrapDust and Packs.packScrapDust(packId) or 0
	end
	-- Legacy setId-only crates: treat as a soft mid pack (loam odds) so they are not stuck.
	if pk.setId and Packs.PACK_BY_ID and Packs.PACK_BY_ID.loam_pack then
		return Packs.packScrapDust(Packs.PACK_BY_ID.loam_pack)
	end
	return 0
end

--[[
	WHAT A BULK SCRAP WOULD DO -- read only, nothing is removed.

	Split out of scrapMany so the REVIEW screen and the commit are built by the
	same function. A review that is computed separately from the thing it
	authorises eventually disagrees with it, and then the player has approved a
	number they are not paid.

	Returns rows (what goes), blocked (what cannot, and why), and the totals. An
	id that is equipped, socketed, worn or simply absent lands in `blocked` with a
	reason rather than being silently dropped: "nothing happened to three of
	these" is the single most confusing outcome a bulk action can have.

	SOCKETED GEAR IS BLOCKED, which the old partial path did not do. A rune in a
	piece is permanent, so scrapping the piece strands it -- the same reason
	MineGear.canUpgrade already refuses to fuse a socketed piece. Quietly eating
	a rune is not a trade anybody agreed to.
]]
local function scrapPlan(p, kind, ids, into)
	local out = { rows = {}, blocked = {}, dust = 0, gems = 0, n = 0 }
	if type(p) ~= "table" or type(ids) ~= "table" then
		return out
	end
	into = (into == "gems") and "gems" or "dust"

	local want, order = {}, {}
	for i, id in ipairs(ids) do
		if i > Const.SCRAP_MAX then
			break
		end
		if id ~= nil and not want[id] then
			want[id] = true
			table.insert(order, id)
		end
	end

	local function add(id, name, dust, gems)
		table.insert(out.rows, { id = id, name = name, dust = dust or 0, gems = gems or 0 })
		out.dust += dust or 0
		out.gems += gems or 0
		out.n += 1
	end
	local function block(id, name, why)
		table.insert(out.blocked, { id = id, name = name or tostring(id), why = why })
	end

	if kind == "card" then
		local equipped = {}
		for _, id in ipairs(p.equipped or {}) do
			equipped[id] = true
		end
		local byId = {}
		for _, c in ipairs(p.cards or {}) do
			byId[c.id] = c
		end
		for _, id in ipairs(order) do
			local c = byId[id]
			if not c then
				block(id, nil, "not in your bag")
			elseif equipped[id] then
				block(id, c.name, "out with you")
			else
				local d = C.salvageDust(c)
				if into == "gems" then
					add(id, c.name, 0, math.max(1, math.floor(d / 10)))
				else
					add(id, c.name, d, 0)
				end
			end
		end
	elseif kind == "rune" then
		local byId = {}
		for _, r in ipairs(p.runes or {}) do
			byId[r.id] = r
		end
		for _, id in ipairs(order) do
			local r = byId[id]
			if not r then
				block(id, nil, "not in your bag")
			elseif runeBusy(p, id) then
				block(id, r.name, "socketed")
			else
				add(id, r.name, 0, Runes.scrapGems(r))
			end
		end
	elseif kind == "gear" then
		local worn = {}
		for _, id in pairs(p.equippedGear or {}) do
			if id then
				worn[id] = true
			end
		end
		local byId = {}
		for _, g in ipairs(p.gear or {}) do
			byId[g.id] = g
		end
		for _, id in ipairs(order) do
			local g = byId[id]
			if not g then
				block(id, nil, "not in your bag")
			elseif worn[id] then
				block(id, g.name or g.setName, "worn")
			else
				local socketed = false
				for _, rid in pairs(g.sockets or {}) do
					if rid then
						socketed = true
						break
					end
				end
				if socketed then
					block(id, g.name or g.setName, "has a rune in it")
				else
					add(id, g.name or g.setName, 0, Gear.scrapGems(g))
				end
			end
		end
	elseif kind == "pack" then
		--[[
			Each id names one pack by its own uid. The bag can shift between the
			list being drawn and the confirm, and an index would then scrap
			whatever slid into that position; a bare index is still honoured for
			an old client.
		]]
		local list = p.packs or {}
		for _, id in ipairs(order) do
			local hit
			for _, pk in ipairs(list) do
				if pk.uid ~= nil and pk.uid == id then
					hit = pk
					break
				end
			end
			if not hit then
				local idx = tonumber(id)
				hit = idx and list[idx] or nil
			end
			if not hit then
				block(id, nil, "not in your bag")
			else
				local d = packScrapDustFor(hit)
				if d <= 0 then
					block(id, hit.packName or hit.packId, "no scrap value")
				elseif into == "gems" then
					add(id, hit.packName or hit.packId, 0, math.max(1, math.floor(d / 10)))
				else
					add(id, hit.packName or hit.packId, d, 0)
				end
			end
		end
	end
	return out
end

--[[
	BULK SCRAP. Two calls: review, then commit.

	Without `payload.confirm` this is the ASK -- the server builds the plan and
	sends it back for the review screen, having changed nothing. With it, the
	scrap happens.

	ALL OR NOTHING. If anything in the selection cannot be scrapped, the whole
	batch is refused and the reason named. The old path scrapped what it could
	and skipped the rest, which for a REVIEWED batch is a broken promise: the
	player approved a specific list and a specific total, so paying less than
	that is worse than paying nothing and saying why.
]]
local function scrapMany(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(payload) ~= "table" then
		return
	end
	local kind = payload.kind
	if kind ~= "card" and kind ~= "rune" and kind ~= "gear" and kind ~= "pack" then
		return
	end
	local into = (payload.into == "gems") and "gems" or "dust"
	local ids = type(payload.ids) == "table" and payload.ids or {}
	if #ids == 0 then
		return
	end

	local plan = scrapPlan(p, kind, ids, into)

	if not payload.confirm then
		net:FireClient(plr, "confirmScrap", {
			kind = kind,
			into = into,
			rows = plan.rows,
			blocked = plan.blocked,
			dust = plan.dust,
			gems = plan.gems,
			n = plan.n,
		})
		return
	end

	if #plan.blocked > 0 then
		local first = plan.blocked[1]
		net:FireClient(plr, "toast", string.format(
			"Nothing scrapped -- %s is %s%s",
			tostring(first.name), tostring(first.why),
			(#plan.blocked > 1) and (" (and " .. (#plan.blocked - 1) .. " more)") or ""))
		snap(plr)
		return
	end
	if plan.n == 0 then
		net:FireClient(plr, "toast", "Nothing scrappable in that selection")
		return
	end

	--[[
		Removal is by the ids the plan already resolved, walking each list
		backwards so the indices stay valid as entries come out.
	]]
	local go = {}
	for _, row in ipairs(plan.rows) do
		go[row.id] = true
	end
	if kind == "card" then
		for i = #(p.cards or {}), 1, -1 do
			if go[p.cards[i].id] then
				table.remove(p.cards, i)
			end
		end
	elseif kind == "rune" then
		for i = #(p.runes or {}), 1, -1 do
			if go[p.runes[i].id] then
				table.remove(p.runes, i)
			end
		end
	elseif kind == "gear" then
		for i = #(p.gear or {}), 1, -1 do
			if go[p.gear[i].id] then
				table.remove(p.gear, i)
			end
		end
	elseif kind == "pack" then
		local list = p.packs or {}
		for i = #list, 1, -1 do
			local pk = list[i]
			local hit = (pk.uid ~= nil and go[pk.uid]) or go[i]
			if hit then
				table.remove(list, i)
			end
		end
	end

	local dust, gems = plan.dust, plan.gems
	if dust > 0 then
		dust = C.vipPayout(dust, hasVipPass(plr))
	end
	p.dust = (p.dust or 0) + dust
	p.gems = (p.gems or 0) + gems
	local paid = (dust > 0) and (Verbs._benchNum(dust) .. " stardust")
		or (Verbs._benchNum(gems) .. " gems")
	net:FireClient(plr, "toast", string.format("Scrapped %d for %s", plan.n, paid))
	markDirty(plr)
	snap(plr)
end

local function scrapItem(plr, payload)
	local p = profiles[plr.UserId]
	if type(payload) ~= "table" then
		return
	end
	local kind, id = payload.kind, payload.id
	local into = payload.into == "gems" and "gems" or "dust"

	if kind == "card" then
		for i, c in ipairs(p.cards or {}) do
			if c.id == id then
				local dust = C.salvageDust(c)
				if into == "gems" then
					-- Deliberately a poor rate. Gems are the cross-run currency;
					-- this is an escape hatch, not a second income.
					local gems = math.max(1, math.floor(dust / 10))
					p.gems = (p.gems or 0) + gems
					net:FireClient(plr, "toast", "Scrapped " .. tostring(c.name) .. " for " .. gems .. " gems")
				else
					local dust = C.vipPayout(C.salvageDust(c), hasVipPass(plr))
					p.dust = (p.dust or 0) + dust
					net:FireClient(plr, "toast", "Scrapped " .. tostring(c.name) .. " for " .. dust .. " stardust")
				end
				table.remove(p.cards, i)
				unequip(plr, id)
				markDirty(plr)
				snap(plr)
				return
			end
		end
	elseif kind == "pack" then
		-- By uid first; an index only for an old client.
		local idx, pk
		for i, entry in ipairs(p.packs or {}) do
			if entry.uid ~= nil and entry.uid == id then
				idx, pk = i, entry
				break
			end
		end
		if not pk then
			idx = tonumber(id)
			pk = idx and (p.packs or {})[idx]
		end
		if not pk then
			net:FireClient(plr, "toast", "Nothing to scrap")
			return
		end
		local dust = packScrapDustFor(pk)
		if dust <= 0 then
			net:FireClient(plr, "toast", "That pack cannot be scrapped for stardust")
			return
		end
		if into == "gems" then
			local gems = math.max(1, math.floor(dust / 10))
			p.gems = (p.gems or 0) + gems
			net:FireClient(plr, "toast", "Scrapped pack for " .. gems .. " gems")
		else
			local dust = C.vipPayout(dust, hasVipPass(plr))
			p.dust = (p.dust or 0) + dust
			net:FireClient(plr, "toast", "Scrapped pack for " .. dust .. " stardust")
		end
		table.remove(p.packs, idx)
		markDirty(plr)
		snap(plr)
		return
	elseif kind == "rune" then
		for i, r in ipairs(p.runes or {}) do
			if r.id == id then
				if runeBusy(p, id) then
					net:FireClient(plr, "toast", "Unsocket it first")
					return
				end
				local gems = Runes.scrapGems(r)
				p.gems = (p.gems or 0) + gems
				table.remove(p.runes, i)
				markDirty(plr)
				snap(plr)
				walk(plr)
				net:FireClient(plr, "toast", "Scrapped rune for " .. gems .. " gems")
				return
			end
		end
	elseif kind == "gear" then
		for i, g in ipairs(p.gear or {}) do
			if g.id == id then
				p.equippedGear = p.equippedGear or {}
				if p.equippedGear[g.slot] == id then
					net:FireClient(plr, "toast", "Take it off first")
					return
				end
				local gems = Gear.scrapGems(g)
				p.gems = (p.gems or 0) + gems
				table.remove(p.gear, i)
				markDirty(plr)
				snap(plr)
				walk(plr)
				net:FireClient(plr, "toast", "Scrapped " .. tostring(g.rarity) .. " " .. tostring(g.slot)
					.. " for " .. gems .. " gems")
				return
			end
		end
	end
	net:FireClient(plr, "toast", "Nothing to scrap")
end

local function salvage(plr, id)
	local p = profiles[plr.UserId]
	for i, c in ipairs(p.cards) do
		if c.id == id then
			p.dust += C.vipPayout(C.salvageDust(c), hasVipPass(plr))
			table.remove(p.cards, i)
			unequip(plr, id)
			if math.floor(tonumber(p.intro) or 0) == 33 then
				p.introScrapped = (p.introScrapped or 0) + 1
				if p.introScrapped >= 5 then
					p.dust += 250
					net:FireClient(plr, "toast", "Scrapped 5 pets — +250 stardust")
					introAdvance(plr, p, 33)
				else
					introSend(plr, p)
				end
			end
			snap(plr)
			return
		end
	end
end

local function powerUp(plr, id)
	local p = profiles[plr.UserId]
	local c = cardById(p, id)
	if not c then return end
	if (c.powerLevel or 1) >= C.MAX_POWER then net:FireClient(plr, "toast", "Max power") return end
	local cost = C.vipPrice(C.powerDustCost(c.powerLevel or 1), hasVipPass(plr))
	if p.dust < cost then net:FireClient(plr, "toast", "Need " .. cost .. " dust") return end
	p.dust -= cost
	c.powerLevel = (c.powerLevel or 1) + 1
	snap(plr)
end
--[[
	TOOLS ARE NOT BOUGHT ANY MORE. THEY ARE FORGED.

	Owner, 2026-10-05: "i think its time to get rid of all coin bought tools".

	The tabs are gone from the shop rail, but a rail is a client drawing and this
	is the rule. Every path that used to sell a tool for coins stops here, so a
	modified client firing `buyTool` by hand gets the same answer as one that
	cannot see the button.

	What still comes through: BACKPACKS, which are haul capacity rather than a
	tool, and the `eh_` event items, which are their own economy. Both are
	reached by toolId through MineShopBuy below and neither is in Tools.TOOLS,
	so the family check is what separates them -- not a list of exceptions that
	would drift as items are added.

	The wooden pickaxe is unaffected: it is GIVEN, never sold, and it still
	levels on coins (MineConfig.isCoinTool). That is the one place coins still
	touch a tool, and the owner kept it deliberately as the on-ramp to the Forge.

	THE LIST LIVES IN MineConfig, NOT HERE. It was briefly a top-level local in
	this script, and that one register broke the entire server: MineServer sits
	at Luau's 200-local ceiling, so the compile failed with "Out of local
	registers when trying to allocate id", MineNet was never created, and every
	client hung on WaitForChild("MineNet") with no other symptom. Same ceiling
	MineClient has, same failure mode. Do not add top-level locals to either file.
]]
local function buyTool(plr, payload)
	local p = profiles[plr.UserId]
	if not p then return end
	--[[
		A toolId buy is resolved against the surface ladder, which carries the
		row's family, so the refusal has to happen after the row is known -- see
		the guard inside the toolId branch. A bare family string is refused here.
	]]
	if type(payload) ~= "table" or not payload.toolId then
		local fam = tostring((type(payload) == "table" and payload.family) or payload or "pickaxe")
		if (C.FORGE_ONLY_FAMILIES or {})[fam] then
			net:FireClient(plr, "toast", "Tools are forged from ore now - open the Forge")
			return
		end
	end
	-- New surface ladder: buy by toolId from MineShopLadders (desk == surface only).
	if type(payload) == "table" and payload.toolId then
		local okBuy, ShopBuy = pcall(function()
			return require(shared:WaitForChild("MineShopBuy"))
		end)
		local okL, Ladders = pcall(function()
			return require(shared:WaitForChild("MineShopLadders"))
		end)
		if okBuy and ShopBuy and okL and Ladders then
			-- The ladder row carries its family, so the refusal lands here --
			-- after the id resolves and before any coins move. Backpacks and
			-- event items resolve to rows with no tool family and pass through.
			local row = Ladders.byId and Ladders.byId(tostring(payload.toolId))
			if row and (C.FORGE_ONLY_FAMILIES or {})[tostring(row.family or "")] then
				net:FireClient(plr, "toast", "Tools are forged from ore now - open the Forge")
				return
			end
			ShopBuy.buySurface(plr, p, payload, {
				ShopLadders = Ladders, C = C, net = net,
				givePickaxe = givePickaxe, giveBackpackModel = giveBackpackModel,
				introAdvance = introAdvance, snap = snap,
			})
		end
		return
	end
	-- Legacy call sites pass a bare family string; the shop passes a table.
	local family, wantTier = payload, nil
	if type(payload) == "table" then
		family, wantTier = payload.family, payload.tier
	end
	family = tostring(family or "pickaxe")
	local list = Tools.TOOLS[family]
	if not list or #list == 0 then
		net:FireClient(plr, "toast", "That family is not in the game yet")
		return
	end
	equippedTool(p)
	local owned = p.tools[family] or 0
	-- A tier may be named outright. The ladder is a highest-rung marker, not a
	-- list of receipts, so buying ahead grants everything under it -- there is
	-- no reason to make someone click through eleven picks they will never hold.
	local nextTier = tonumber(wantTier) or (owned + 1)
	local row = list[nextTier]
	if not row then
		net:FireClient(plr, "toast", "Fully upgraded")
		return
	end
	if nextTier <= owned then
		net:FireClient(plr, "toast", "You already own " .. row.name)
		return
	end
	local needZone = Tools.minZone(family, nextTier)
	if (p.maxUnlockedZone or 1) < needZone then
		local zone = C.ZONES[needZone]
		net:FireClient(plr, "toast", string.format("%s unlocks in %s (zone %d)", row.name, zone and zone.name or ("zone " .. needZone), needZone))
		return
	end
	if (p.coins or 0) < row.price then
		net:FireClient(plr, "toast", string.format("%s costs %s coins", row.name, tostring(row.price)))
		return
	end
	p.coins -= row.price
	p.tools[family] = math.max(owned, nextTier)
	p.toolTier = p.toolTier or {}
	p.toolTier[family] = nextTier
	if family == "pickaxe" then
		p.pickaxeTier = nextTier
	end
	p.toolFamily = family
	givePickaxe(plr)
	giveBackpackModel(plr)
	introAdvance(plr, p, 3)
	net:FireClient(plr, "toast", "Bought " .. row.name)
	snap(plr)
end

-- Depth-plaza catalog buy. Same coin ladder as surface shop, but skips island
-- minZone so reaching the seam desk is the unlock (not buying zone 5/7).
local function buyDepthTool(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(payload) ~= "table" then
		return
	end
	local toolId = tostring(payload.toolId or payload.id or "")
	if string.sub(toolId, 1, 3) == "eh_" then
		local okBuy, ShopBuy = pcall(function()
			return require(shared:WaitForChild("MineShopBuy"))
		end)
		if okBuy and ShopBuy and ShopBuy.buyEvent then
			ShopBuy.buyEvent(plr, p, toolId, { net = net, snap = snap, givePickaxe = givePickaxe })
		end
		return
	end
	--[[
		The depth desks sell off the SAME ladders the surface shop did, so
		refusing only at the surface would have left every outpost below 500m
		still selling pickaxes. Same rule, same message, second door.

		Event items (`eh_`) returned above before reaching this, and backpacks
		carry no tool family, so both still sell.
	]]
	do
		local okL, Ladders = pcall(function()
			return require(shared:WaitForChild("MineShopLadders"))
		end)
		local row = okL and Ladders and Ladders.byId and Ladders.byId(toolId)
		if row and (C.FORGE_ONLY_FAMILIES or {})[tostring(row.family or "")] then
			net:FireClient(plr, "toast", "Tools are forged from ore now - open the Forge")
			return
		end
	end
	local desk = tostring(payload.desk or "")
	local seam = tonumber(payload.seam) or Dig.Shop.deskSeam(desk)
	if toolId == "" or not seam then
		net:FireClient(plr, "toast", "Depth shop is closed")
		return
	end
	desk = desk ~= "" and desk or Dig.Depth.bandUnlockKey(seam)
	local z = C.zoneById(payload.zoneId or p.zoneId) or C.ZONES[1]
	local zi = (C.zoneIndex and C.zoneIndex(z.id)) or 1
	local okSeam, why, need = Dig.Auth.canAccessSeam(p, z.id, seam)
	if not okSeam then
		if why == "need_depth" then
			net:FireClient(plr, "toast", "Reach depth " .. tostring(need or seam) .. " to unlock these shop options.")
		elseif Dig.Depth.rebirthToast and need then
			net:FireClient(plr, "toast", Dig.Depth.rebirthToast(need, zi, seam))
		else
			net:FireClient(plr, "toast", "This depth shop is locked.")
		end
		return
	end
	desk = select(1, Dig.Auth.clampDesk(p, z.id, desk))
	local okShop, Shop = pcall(function()
		return require(shared:WaitForChild("MineDepthShop"))
	end)
	Shop = (okShop and Shop) or Dig.Shop
	local rowOffer = Shop.catalogHas and Shop.catalogHas(zi, seam, toolId, desk)
	if not rowOffer then
		net:FireClient(plr, "toast", "Not sold at this desk")
		return
	end
	local needDepth = math.floor(tonumber(rowOffer.minDepth) or 0)
	local gotDepth = (p.deepest and p.deepest[z.id]) or 0
	if needDepth > gotDepth then
		net:FireClient(plr, "toast", "Reach depth " .. tostring(needDepth) .. " to unlock these shop options.")
		return
	end
	if rowOffer.family == "backpack" or string.match(toolId, "^bag_") then
		local tier = tonumber(rowOffer.tier) or tonumber(string.match(toolId, "^bag_(%d+)$"))
		if not tier then
			net:FireClient(plr, "toast", "Unknown bag")
			return
		end
		buy(plr, { what = "backpack", tier = tier })
		return
	end
	local family, tier, row = rowOffer.family, rowOffer.tier, nil
	if Shop.resolve then
		row, family, tier = Shop.resolve(toolId)
	else
		for fam, list in pairs(Tools.TOOLS or {}) do
			for i, t in ipairs(list) do
				if t.id == toolId then
					family, tier, row = fam, i, t
					break
				end
			end
			if row then break end
		end
	end
	if not row then
		net:FireClient(plr, "toast", "Unknown tool")
		return
	end
	local price = (Shop.priceOf and Shop.priceOf(row)) or rowOffer.price or row.price or 0
	equippedTool(p)
	local owned = p.tools[family] or 0
	if tier <= owned then
		net:FireClient(plr, "toast", "You already own " .. row.name)
		return
	end
	if (p.coins or 0) < price then
		net:FireClient(plr, "toast", string.format("%s costs %s coins", row.name, tostring(price)))
		return
	end
	p.coins -= price
	p.tools[family] = math.max(owned, tier)
	p.toolTier = p.toolTier or {}
	p.toolTier[family] = tier
	if family == "pickaxe" then
		p.pickaxeTier = tier
	end
	p.toolFamily = family
	p.toolEquipped = true
	p.chestTool = nil
	givePickaxe(plr)
	giveBackpackModel(plr)
	net:FireClient(plr, "toast", "Bought " .. row.name .. " (depth)")
	snap(plr)
	local refresh = (Shop.catalog and Shop.catalog(zi, seam, desk)) or {}
	for _, crow in ipairs(refresh) do
		local fam = crow.family
		local tr = crow.tier or 0
		crow.owned = fam and ((p.tools and (p.tools[fam] or 0) or 0) >= tr) or false
	end
	net:FireClient(plr, "openPanel", "depth_shop", {
		seam = seam,
		desk = desk,
		zoneId = z.id,
		catalog = refresh,
		ownedTools = p.tools or {},
		backpackTier = p.backpackTier or 1,
		coins = p.coins or 0,
		gems = p.gems or 0,
		spaceCoins = p.spaceCoins or 0,
		eventTools = p.eventTools,
		deepest = (p.deepest and p.deepest[z.id]) or 0,
	})
end

-- Switch families. You can only hold what you own.
local function equipTool(plr, payload)
	local p = profiles[plr.UserId]
	local family, wantTier = payload, nil
	if type(payload) == "table" then
		family, wantTier = payload.family, tonumber(payload.tier)
	end
	family = tostring(family or "pickaxe")
	equippedTool(p)
	local owned = p.tools[family] or 0
	if owned <= 0 then
		net:FireClient(plr, "toast", "You do not own a " .. family .. " yet")
		return
	end
	-- Any rung you own, not just the top one.
	p.toolTier = p.toolTier or {}
	p.toolTier[family] = math.clamp(wantTier or p.toolTier[family] or owned, 1, owned)
	-- A chest or fossil tool overrides the ladder entirely, so choosing a
	-- ladder tool has to put those down or nothing appears to change.
	p.chestTool, p.shopToolId = nil, nil
	p.toolFamily = family
	p.toolEquipped = true
	givePickaxe(plr)
	giveBackpackModel(plr)
	snap(plr)
end

-- Put the tool away. Mining stops too -- an unequipped pickaxe that still
-- breaks rock would just be a cosmetic toggle.
local function unequipTool(plr)
	local p = profiles[plr.UserId]
	p.toolEquipped = false
	local char = plr.Character
	local held = char and char:FindFirstChild("Pickaxe")
	if held then
		held:Destroy()
	end
	local bag = plr:FindFirstChild("Backpack")
	local stowed = bag and bag:FindFirstChild("Pickaxe")
	if stowed then
		stowed:Destroy()
	end
	snap(plr)
end

-- Walk-free travel to a lobby counter. The pads are the real destination, so
-- the button and the building can never drift apart.
local function zoneIdAtCharacter(plr, fallback)
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return fallback
	end
	local pos = root.Position
	if C.blockOverlapsLobby and C.blockOverlapsLobby(pos, 0) then
		return "lobby"
	end
	local bestId, bestDist
	for _, z in ipairs(C.ZONES or {}) do
		local origin = C.zoneOrigin and C.zoneOrigin(z)
		if origin then
			local d = (Vector3.new(pos.X, origin.Y, pos.Z) - origin).Magnitude
			if not bestDist or d < bestDist then
				bestDist, bestId = d, z.id
			end
		end
	end
	return bestId or fallback
end

local function gotoStation(plr, id)
	id = tostring(id or "sell")
	local p = profiles[plr.UserId]
	local fallbackZone = (p and p.zoneId) or (C.ZONES[1] and C.ZONES[1].id)
	-- Sell goes to the mine you are standing in, not the last enterZone target.
	local zoneId = (id == "sell") and zoneIdAtCharacter(plr, fallbackZone) or fallbackZone
	if zoneId == "lobby" then
		zoneId = nil
	end
	local world = workspace:FindFirstChild("MineWorld")
	local shop, ring

	-- If selling while deep in THIS pit, prefer the open depth-plaza sell pad.
	if id == "sell" and world and zoneId and p then
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		local zDef = C.zoneById and C.zoneById(zoneId)
		local origin = zDef and C.zoneOrigin and C.zoneOrigin(zDef)
		local inPit = false
		if root and origin then
			local flat = (Vector3.new(root.Position.X, origin.Y, root.Position.Z) - origin).Magnitude
			local half = ((C.GRID or 21) * (C.BLOCK or 5)) * 0.5 + 40
			inPit = flat <= half and root.Position.Y < (origin.Y - 8)
		end
		local pits = world:FindFirstChild("Pits")
		if pits and inPit then
			local best, bestDist
			for _, folder in ipairs(pits:GetChildren()) do
				if folder.Name:match("^DepthPlaza_" .. zoneId .. "_") then
					local sell = folder:FindFirstChild("sell_depth")
					if sell and sell:IsA("BasePart") then
						local dist = root and (root.Position - sell.Position).Magnitude or 0
						if not best or dist < bestDist then
							best, bestDist = sell, dist
						end
					end
				end
			end
			if best then
				p._sellDesk = best:GetAttribute("SellDesk") or "deeprock"
				tp(plr, best.CFrame * CFrame.new(0, best.Size.Y * 0.5 + 3, 0))
				snap(plr)
				return
			end
		end
	end

	-- Prefer the sell/shop pad on the zone you are currently in.
	if world and zoneId then
		local biome = world:FindFirstChild("Biome_" .. tostring(zoneId))
		local outpost = biome and biome:FindFirstChild("Outpost_" .. tostring(zoneId))
		shop = outpost and outpost:FindFirstChild("Shop_" .. id)
		local padFolder = shop and shop:FindFirstChild("Pad_" .. id)
		ring = padFolder and padFolder:FindFirstChild("Ring")
	end

	-- Lobby depot / forge fallback (no zone outpost, or still in hub).
	if not ring then
		local lobby = world and world:FindFirstChild("Lobby")
		shop = lobby and lobby:FindFirstChild("Shop_" .. id)
		local padFolder = shop and shop:FindFirstChild("Pad_" .. id)
		ring = padFolder and padFolder:FindFirstChild("Ring")
	end
	if not ring then
		net:FireClient(plr, "toast", "Cannot find that counter")
		return
	end
	-- Land on the pad facing the counter.
	-- Shop_* is a Folder, and Folders have no GetPivot. Face the counter, which
	-- is a real part and is what you are walking up to.
	local facing = shop:FindFirstChild("Counter") or shop:FindFirstChild("Back")
	local look = facing and facing.Position or (ring.Position + Vector3.new(0, 0, 1))
	tp(plr, CFrame.lookAt(ring.Position + Vector3.new(0, 4, 0), Vector3.new(look.X, ring.Position.Y + 4, look.Z)))
	snap(plr)
end

-- The Charter is the gem sink that does not reset. Backpacks and pet slots both
-- cap out inside an hour, which left gems with nowhere to go.
--[[
	VERB HANDLERS LIVE IN A TABLE, NOT IN LOCALS.

	Luau allows 200 local registers per function, and this script's top level
	counts as one function. It hit 201 and stopped compiling entirely --
	"Out of local registers when trying to allocate skillBuySlot" -- which takes
	the whole server down: no mining, no saving, nothing loads.

	Every function below that is written `function Verbs.x` is called from
	exactly one place, the net dispatcher at the bottom, and from nowhere else.
	Moving them here freed 22 registers. Anything new that is only ever called
	by the dispatcher belongs in this table rather than in a fresh top-level
	local; the top level is full.
]]
local Verbs = {}

--[[
	THE FREE FIRST PICKAXE.

	Walking up to the Blacksmith IS the pickup -- no coin check, no menu to
	find, because this fires before a new player has been taught what a shop
	even is. Idempotent: gotFirstPick gates it, so a second walk past the
	counter is just a shop opening.
]]
function Verbs.grantFirstPick(plr, p)
	if not p or p.gotFirstPick ~= false then
		return false
	end
	p.tools = p.tools or {}
	p.tools.pickaxe = math.max(1, tonumber(p.tools.pickaxe) or 0)
	p.toolTier = p.toolTier or {}
	p.toolTier.pickaxe = 1
	p.toolFamily = "pickaxe"
	p.toolEquipped = true
	p.gotFirstPick = true
	local row = Tools.TOOLS.pickaxe[1]
	givePickaxe(plr)
	markDirty(plr)
	net:FireClient(plr, "toast", ((row and row.name) or "Pickaxe") .. " -- FREE. Go break something.")
	introAdvance(plr, p, 27)
	snap(plr)
	return true
end

-- Must stay BELOW `local Verbs = {}` above. This was first written next to
-- sellAll, ~1900 lines earlier, where `Verbs` is still a nil global: it threw
-- on the first pass and took the entire server script down with it.

--[[
	Selling at a pad, however you reached it.

	The prompt and the walk-on both land here so they can never drift apart,
	and so the desk gating is written once. Standing on the pad is the real
	interaction -- you run back with a full bag and it cashes -- the prompt is
	the fallback for anyone who stops just short of the trigger.
]]
Verbs.sellPadAt = {}
function Verbs.sellAtPad(plr, parent, zoneId)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local want = parent and parent:GetAttribute("SellDesk") or "surface"
	local seamAttr = tonumber(parent and parent:GetAttribute("Seam"))
	if seamAttr and seamAttr > 0 then
		local okSeam, why, need = Dig.Auth.canAccessSeam(p, zoneId or p.zoneId, seamAttr)
		if not okSeam then
			if why == "need_depth" then
				net:FireClient(plr, "toast", "Reach depth " .. tostring(need or seamAttr) .. " to sell here.")
			elseif Dig.Depth.rebirthToast and need then
				local z = C.zoneById(zoneId or p.zoneId) or C.ZONES[1]
				local zi = C.zoneIndex and C.zoneIndex(z.id) or 1
				net:FireClient(plr, "toast", Dig.Depth.rebirthToast(need, zi, seamAttr))
			else
				net:FireClient(plr, "toast", "This sell desk is locked.")
			end
			return
		end
	end
	p._sellDesk = select(1, Dig.Auth.clampDesk(p, zoneId or p.zoneId, want))
	sellAll(plr)
end

-- Walk-on selling. The pad IS the button; nobody should have to find a
-- keyboard key to hand over a bag of dirt. Debounced per player so brushing
-- the trigger does not fire a dozen times, and silent on an empty bag so it
-- never nags you for walking past.
function Verbs.bindSellPad(part)
	if not part:IsA("BasePart") or part:GetAttribute("Machine") ~= "sell" then
		return
	end
	Verbs.sellPadBound = Verbs.sellPadBound or setmetatable({}, { __mode = "k" })
	if Verbs.sellPadBound[part] then
		return
	end
	Verbs.sellPadBound[part] = true
	part.Touched:Connect(function(hit)
		local plr = hit and hit.Parent and Svc.Players:GetPlayerFromCharacter(hit.Parent)
		if not plr then
			return
		end
		local p = profiles[plr.UserId]
		if not p or (tonumber(p.load) or 0) <= 0 then
			return
		end
		local now = os.clock()
		if (Verbs.sellPadAt[plr.UserId] or 0) > now - 1.5 then
			return
		end
		Verbs.sellPadAt[plr.UserId] = now
		pcall(Verbs.sellAtPad, plr, part, part:GetAttribute("ZoneId"))
	end)
end

--[[
	BUY A SEAM. The coin sink the economy is short of.

	Rebirth is nine one-time purchases and then that sink is gone forever; seams
	repeat in every zone, never run out, and scale at exactly the rate coin income
	does -- because the price IS income, measured in minutes.

	Nothing here stores a coin figure. seamPrice derives it from the band's own
	average income every time it is asked, so the ladder self-corrects the moment
	the block rate or the coin curve moves, and cannot go stale.
]]
function Verbs.buySeam(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local Depth = Dig.Depth
	local seam = payload
	if type(payload) == "table" then
		seam = payload.seam or payload.layer
	end
	seam = math.floor(tonumber(seam) or 0)
	local zi = math.max(1, math.floor(tonumber(C.zoneIndex and C.zoneIndex(p.zoneId)) or 1))
	local price = Depth.seamPrice and Depth.seamPrice(seam, zi)
	if not price then
		net:FireClient(plr, "toast", "No seam at that depth")
		return
	end
	if Depth.ownsSeam(p, seam, zi) then
		net:FireClient(plr, "toast", "That seam is already open")
		return
	end
	-- Seams open in order. Free does not mean skippable: the bands are the
	-- progression, and opening 5000 before 500 would drop a player into rock
	-- their tool cannot scratch.
	for _, s in ipairs(Depth.SEAMS) do
		if s >= seam then
			break
		end
		if not Depth.ownsSeam(p, s, zi) then
			net:FireClient(plr, "toast", "Open layer " .. tostring(s) .. " first")
			return
		end
	end
	-- Free since 2026-10-05 (owner: "buy seams shouldnt cost anything").
	-- Breaking power already gates depth; charging coins for it as well was a
	-- second gate on the same axis. The price is still read above so a seam
	-- that does not exist is still refused, and the order check still stands.
	if price > 0 and (p.coins or 0) < price then
		net:FireClient(plr, "toast", string.format("Layer %d costs %s coins", seam, tostring(price)))
		return
	end
	if price > 0 then
		p.coins -= price
	end
	Depth.grantSeam(p, seam, zi)
	net:FireClient(plr, "toast", string.format("Layer %d open -- dig on", seam))
	markDirty(plr)
	snap(plr)
end

function Verbs.buyCharter(plr, id)
	local p = profiles[plr.UserId]
	local row = C.charterById(tostring(id or ""))
	if not row then
		net:FireClient(plr, "toast", "No such charter")
		return
	end
	p.charter = p.charter or {}
	local level = p.charter[row.id] or 0
	if level >= row.max then
		net:FireClient(plr, "toast", row.name .. " is fully signed")
		return
	end
	local cost = C.charterCost(row, level)
	if (p.gems or 0) < cost then
		net:FireClient(plr, "toast", string.format("%s needs %s gems", row.name, tostring(cost)))
		return
	end
	p.gems -= cost
	p.charter[row.id] = level + 1
	net:FireClient(plr, "toast", string.format("%s  ->  level %d", row.name, level + 1))
	snap(plr)
end

local function equipCharm(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local id = payload
	if type(payload) == "table" then
		id = payload.id or payload.charmId or payload.charm
	end
	id = tostring(id or "")
	if id == "" or id == "nil" then
		p.equippedCharm = nil
		net:FireClient(plr, "toast", "Charm unequipped")
		markDirty(plr)
		snap(plr)
		return
	end
	p.charms = p.charms or {}
	if not p.charms[id] or not Charms.byId(id) then
		net:FireClient(plr, "toast", "You don't own that charm")
		return
	end
	p.equippedCharm = id
	local def = Charms.byId(id)
	net:FireClient(plr, "toast", "Equipped " .. def.name)
	markDirty(plr)
	snap(plr)
	walk(plr)
end

--[[
	MERGE THREE CHARMS INTO ONE A TIER DEEPER.

	The rule and the cost live in MineCharms.mergeTarget / MERGE_COST so the
	client's button and this cannot disagree about what a merge produces -- and
	the refusal sentence comes from there too, so "why not" reads the same in
	both places.

	ALL OR NOTHING, and the spend happens after the target resolves: an earlier
	shape of this debited first and granted second, which on an unmergeable
	charm would have eaten three copies for nothing.

	The equipped charm is handled rather than ignored. Merging away the last
	copy of what you are wearing would leave `p.equippedCharm` pointing at a
	charm you no longer own, which the load path then silently clears -- so the
	merge moves you onto the charm you just made instead. That is also just
	what you wanted.
]]
--[[
	LOAD AND STAMP THE LAUNCH FLAG.

	Owner, 2026-10-07: the timer keeps ticking but the season must not START
	until they say so. MineLaunch holds the rule; this is the persistence and the
	switch.

	Stored server-wide, NOT per profile: a season that had begun for one player
	and not another would be incoherent, and it has to survive every server
	restart or the season silently rewinds to zero on the next one.

	Read once at boot and cached on the module. The read is best-effort -- if the
	datastore is down, the game stays UNLAUNCHED, which is the safe direction: a
	failed read must never start the season by accident.
]]
function Verbs._loadLaunch()
	local okRead, saved = pcall(function()
		return store:GetAsync("launch_v1")
	end)
	if okRead and type(saved) == "table" and tonumber(saved.at) and tonumber(saved.at) > 0 then
		Dig.Launch.launchedAt = math.floor(saved.at)
		print(("[Mine] season LAUNCHED at %d (%d days in)"):format(
			Dig.Launch.launchedAt, math.floor(Dig.Launch.elapsed() / 86400)))
	else
		Dig.Launch.launchedAt = 0
		print("[Mine] season NOT launched yet -- clock pinned to season start")
	end
end

--[[
	Throw the switch. Admin only, and deliberately not undoable from here.

	There is no "unlaunch": once players have spent a season's worth of time in
	it, rewinding would re-lock what they earned. If it is ever thrown by
	mistake, the fix is a deliberate datastore edit, not a verb anyone can call.
]]
function Verbs.launchSeason(plr)
	local Allow = require(script.Parent:WaitForChild("Admin"):WaitForChild("AdminAllowlist"))
	if not (Allow.isAdmin and Allow.isAdmin(plr.UserId)) then
		return
	end
	if Dig.Launch.isLaunched() then
		net:FireClient(plr, "toast", ("Season already launched (%d days in)"):format(
			math.floor(Dig.Launch.elapsed() / 86400)))
		return
	end
	local at = Dig.Launch.launch(os.time())
	if not at then
		net:FireClient(plr, "toast", "Could not launch -- bad server clock")
		return
	end
	-- Persist BEFORE announcing: a launch that was announced and not saved would
	-- rewind on the next server restart, which is worse than a failed launch.
	local okSave = pcall(function()
		store:SetAsync("launch_v1", { at = at, by = plr.UserId })
	end)
	if not okSave then
		Dig.Launch.launchedAt = 0
		net:FireClient(plr, "toast", "Launch FAILED to save -- still not launched")
		warn("[Mine] launchSeason could not persist; season left unlaunched")
		return
	end
	print(("[Mine] SEASON LAUNCHED by %s (%d) at %d"):format(plr.Name, plr.UserId, at))
	net:FireClient(plr, "toast", "Season launched. The clock is running.")
end

--[[
	BUY A CASE FROM A WANDERING TRADER.

	Four things are checked before a token is spent, and each one is an exploit if
	it is missing:

	  IS A TRADER THERE. The prompt lives in the world, but a client can fire this
	  verb without ever walking to one. canTrade re-derives the roster from the
	  rotation, so naming an outpost is not the same as standing at it -- without
	  this, a surface player buys the deep stock by sending a different seam.

	  IS THAT CASE IN ITS STOCK. The trader's shelf is a function of (rotation,
	  zone, seam); a caseId that is not on it is refused even though the case
	  exists. Otherwise the depth gate in MineTrader.stockFor is decoration.

	  CAN THE PLAYER BE THERE AT ALL. canAccessSeam, so a trader at 3,000 is not a
	  way to shop past a seam you have not opened.

	  THE PRICE IS THE SHELF'S. Taken from the stock row, not from the payload and
	  not recomputed here, so what the panel quoted is what is charged.

	The reward is rolled server-side with a fresh Random. The client is told what
	it got, never what it would get.
]]
function Verbs.buyTraderCase(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(payload) ~= "table" then
		return
	end
	local zoneId = tostring(payload.zoneId or "")
	local seam = math.floor(tonumber(payload.seam) or 0)
	local caseId = tostring(payload.caseId or "")
	local okHere, why = Dig.TraderNPC.canTrade(p, zoneId, seam, Dig.Auth)
	if not okHere then
		net:FireClient(plr, "toast",
			why == "need_seam" and "You have not opened that seam" or "No trader there right now")
		return
	end
	local offer = Dig.TraderNPC.offer(zoneId, seam)
	local row
	for _, r in ipairs(offer.stock or {}) do
		if r.caseId == caseId then
			row = r
			break
		end
	end
	if not row then
		net:FireClient(plr, "toast", "That trader is not carrying that")
		return
	end
	local price = math.max(1, math.floor(tonumber(row.tokens) or 0))
	if (tonumber(p.temperTokens) or 0) < price then
		net:FireClient(plr, "toast", ("Need %d tokens"):format(price))
		return
	end
	local reward = Dig.Trader.rollCase(row.caseId, Random.new())
	if not reward then
		net:FireClient(plr, "toast", "That case is empty")
		return
	end
	-- Debit only once the reward resolved, so a case that cannot pay never costs.
	p.temperTokens = (tonumber(p.temperTokens) or 0) - price
	local got = nil
	if reward.kind == "charm" then
		p.charms = p.charms or {}
		p.charms[reward.charmId] = (tonumber(p.charms[reward.charmId]) or 0) + 1
		got = reward.name
	elseif reward.kind == "hat" then
		local rng = Random.new()
		local catalog = Gear.catalogFor and Gear.catalogFor("hat", reward.rarity, nil, rng)
		local setId = (catalog and catalog.setId)
			or (Gear.SETS and Gear.SETS[rng:NextInteger(1, #Gear.SETS)].id)
		local piece = Gear.makePiece and Gear.makePiece(instanceHex16(), setId, "hat", reward.rarity, catalog)
		if piece then
			p.gear = p.gear or {}
			table.insert(p.gear, piece)
			got = (piece.name or "Hat") .. " (" .. tostring(reward.rarity) .. ")"
		end
	elseif reward.kind == "tool" then
		local oreDef = C.ORES[math.clamp(reward.tier, 1, #C.ORES)]
		local OreToolsM = require(shared:WaitForChild("MineOreTools"))
		local familyId = ({ "pickaxe", "drill", "explosive" })[Random.new():NextInteger(1, 3)]
		local def = oreDef and OreToolsM.frameForTier and OreToolsM.frameForTier(familyId, oreDef.tier)
		if def and oreDef then
			p.oreTools = p.oreTools or {}
			table.insert(p.oreTools, {
				uid = instanceHex16(),
				typeId = def.id,
				familyId = familyId,
				tier = oreDef.tier,
				-- A bought tool starts at 1, not at your inherited best: the case
				-- is the tool, not a free run up the upgrade ladder.
				level = 1,
				base = 1,
			})
			got = (oreDef.name or "Tool") .. " " .. familyId
		end
	end
	if not got then
		-- Nothing could be built: refund rather than charge for nothing.
		p.temperTokens = (tonumber(p.temperTokens) or 0) + price
		net:FireClient(plr, "toast", "The trader had nothing to give")
		return
	end
	net:FireClient(plr, "toast", ("%s — %s for %d tokens"):format(row.name, got, price))
	net:FireClient(plr, "foundTool", {
		kind = reward.kind,
		name = got,
		title = "TRADER CASE",
		rarityId = reward.rarity and (Charms.RARITY_LABEL and Charms.RARITY_LABEL[reward.rarity]) or "Legendary",
		blurb = row.blurb or "",
	})
	markDirty(plr)
	snap(plr)
end

--[[
	BUY A GRADED CHARM WITH TEMPER TOKENS.

	Owner, 2026-10-07: charms "can be found in chests (0.5%) or bought with
	tokens". This is the second half; the chest roll lives in openChestBlock.

	The price comes from MineCharms.charmTokenPrice rather than from the payload,
	which is the whole point of having it there: a client that asks to buy an SSS
	for 15 tokens is quoted 2500 by the same table the shop panel reads.

	Only `source == "charm"` rows are buyable. Zone grants, ore charms and the
	gem pack are not on sale here, and checking the price is not enough on its
	own -- charmTokenPrice keys off `rarity`, so any future row that gains a
	rarity would quietly become purchasable. The source check is the gate.

	Debits before granting, and re-reads the balance inside the loop, so a 10x
	buy cannot overdraw on its last iteration.
]]
function Verbs.buyCharm(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local id = tostring((type(payload) == "table" and payload.charmId) or "")
	local def = Charms.byId(id)
	if not def or def.source ~= "charm" then
		net:FireClient(plr, "toast", "That charm is not for sale")
		return
	end
	local price = Charms.charmTokenPrice(def)
	if not price or price <= 0 then
		net:FireClient(plr, "toast", "That charm has no price")
		return
	end
	local want = math.clamp(math.floor(tonumber(type(payload) == "table" and payload.count) or 1), 1, 10)
	local have = tonumber(p.temperTokens) or 0
	if have < price then
		net:FireClient(plr, "toast", ("Need %d token%s"):format(price, price == 1 and "" or "s"))
		return
	end
	p.charms = p.charms or {}
	local bought, spent = 0, 0
	for _ = 1, want do
		if (tonumber(p.temperTokens) or 0) < price then
			break
		end
		p.temperTokens = (tonumber(p.temperTokens) or 0) - price
		spent += price
		-- A tally, like every other charm grant; a legacy `true` reads as one.
		p.charms[def.id] = (tonumber(p.charms[def.id]) or 0) + 1
		bought += 1
	end
	if bought <= 0 then
		return
	end
	-- Wear it if nothing is on, so a first purchase is a boost rather than a
	-- menu to go and find. Same rule as the chest and zone grants.
	if not (type(p.equippedCharm) == "string" and p.equippedCharm ~= "") then
		p.equippedCharm = def.id
	end
	net:FireClient(plr, "toast", ("Bought %s%s for %d tokens"):format(
		def.name, bought > 1 and (" x" .. bought) or "", spent))
	markDirty(plr)
	snap(plr)
end

-- On Verbs rather than a local: this script sits at 197 of Luau's 200
-- top-level locals and a verb does not need to spend one of the last three.
function Verbs.mergeCharm(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local id = payload
	if type(payload) == "table" then
		id = payload.id or payload.charmId or payload.charm
	end
	id = tostring(id or "")
	p.charms = p.charms or {}

	-- One copy, not three. The gems are the price now; see MineCharms.
	local cost = math.max(1, math.floor(tonumber(Charms.MERGE_COST) or 1))
	local have = math.floor(tonumber(p.charms[id]) or 0)
	-- A legacy charm saved as `true` counts as one copy, the same as everywhere
	-- else that reads this tally.
	if p.charms[id] == true then
		have = 1
	end
	if have < cost then
		net:FireClient(plr, "toast", string.format(
			"Need %d of that charm to merge (you have %d)", cost, have))
		return
	end

	local targetId, targetDef, why = Charms.mergeTarget(id)
	if not targetId then
		net:FireClient(plr, "toast", why or "That charm cannot be merged")
		return
	end

	--[[
		THE GEMS. Owner, 2026-10-04: "rather than merging it should cost gems."

		Priced off the TARGET's tier, not the source's, so the step you are
		buying is what you pay for. Charged AFTER mergeTarget resolves -- a
		charm that cannot merge must not take the gems first.
	]]
	local gemCost = Charms.mergeGemCost and Charms.mergeGemCost(targetDef.tier) or 0
	local gems = math.floor(tonumber(p.gems) or 0)
	if gemCost > 0 and gems < gemCost then
		net:FireClient(plr, "toast", string.format(
			"Needs %s gems to merge", Verbs._benchNum(gemCost)))
		return
	end
	p.gems = gems - gemCost

	p.charms[id] = have - cost
	if p.charms[id] <= 0 then
		p.charms[id] = nil
	end
	local had = p.charms[targetId]
	if had == true then
		had = 1
	end
	p.charms[targetId] = math.floor(tonumber(had) or 0) + 1
	-- Mark it seen, the same as a drop would, or the Forge's recipe list and
	-- anything else reading oresSeen would not know the ore behind it.
	if targetDef.oreId then
		p.oresSeen = p.oresSeen or {}
		p.oresSeen[tostring(targetDef.oreId)] = true
	end

	if p.equippedCharm == id and not p.charms[id] then
		p.equippedCharm = targetId
	end

	bumpStat(plr, p, "merges")
	net:FireClient(plr, "toast", string.format("%d x %s  ->  %s",
		cost, tostring(Charms.byId(id) and Charms.byId(id).name or id),
		tostring(targetDef.name or targetId)))
	markDirty(plr)
	snap(plr)
	walk(plr)
end

local function equipVfx(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local kind, id
	if type(payload) == "table" then
		kind = payload.kind or payload[1]
		id = payload.id or payload[2]
	else
		return
	end
	kind = tostring(kind or "")
	id = tostring(id or "")
	local def = Vfx.def(id)
	if not def or def.kind ~= kind then
		net:FireClient(plr, "toast", "Unknown VFX")
		return
	end
	p.vfx = p.vfx or {}
	if not p.vfx[id] then
		net:FireClient(plr, "toast", "You don't own that VFX")
		return
	end
	p.equippedVfx = Vfx.normalize(p.equippedVfx)
	p.equippedVfx[kind] = id
	if kind == "tag" then
		applyVipNameTag(plr, p.vipPass == true)
	end
	net:FireClient(plr, "toast", "Equipped " .. def.name)
	markDirty(plr)
	snap(plr)
end

local function buyVfx(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local id = payload
	if type(payload) == "table" then
		id = payload.id or payload.vfxId
	end
	id = tostring(id or "")
	local def = Vfx.def(id)
	if not def then
		net:FireClient(plr, "toast", "Unknown VFX")
		return
	end
	p.vfx = p.vfx or {}
	if p.vfx[id] then
		net:FireClient(plr, "toast", "Already owned")
		return
	end
	local cost = tonumber(def.priceCredits) or 0
	if cost <= 0 then
		p.vfx[id] = true
		markDirty(plr)
		snap(plr)
		return
	end
	local credits = tonumber(p.credits) or 0
	if credits < cost then
		net:FireClient(plr, "toast", string.format("Need %d credits (you have %d)", cost, math.floor(credits)))
		return
	end
	p.credits = credits - cost
	p.vfx[id] = true
	net:FireClient(plr, "toast", "Bought " .. def.name)
	markDirty(plr)
	snap(plr)
end

local function buyCharmsPack(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local cost = Charms.PACK_PRICE_GEMS or 2500
	local gems = tonumber(p.gems) or 0
	if gems < cost then
		net:FireClient(plr, "toast", string.format("Charms Pack costs %d gems (you have %d)", cost, math.floor(gems)))
		return
	end
	p.charms = p.charms or {}
	local rolled = Charms.rollPack(p.charms, Random.new())
	if not rolled then
		net:FireClient(plr, "toast", "You already own every Charms Pack charm")
		return
	end
	p.gems = gems - cost
	p.charms[rolled.id] = (tonumber(p.charms[rolled.id]) or 0) + 1
	net:FireClient(plr, "toast", "Charms Pack: " .. rolled.name .. " — equip in Inventory → Equipment")
	-- The pack opens like a pack (MinePackReveal, forced): that is the purchase fx.
	net:FireClient(plr, "foundTool", {
		kind = "charm",
		charmId = rolled.id,
		name = rolled.name,
		title = "CHARMS PACK",
		rarityId = "Legendary",
		blurb = (rolled.blurb or "") .. "  ·  equip it in Inventory → Equipment",
	})
	markDirty(plr)
	save(plr)
	snap(plr)
	walk(plr)
end

local function buyLuckyCharm(plr)
	net:FireClient(plr, "toast", "Pot of Gold is in the limited deals")
end

--[[
	Credits face == Robux face. Bulk credit packs (bonus %) make the same number
	cheaper in real Robux — that is the pass/limited deal, not an undercut.
]]
local function buyProductWithCredits(plr, key)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	key = tostring(key or "")
	local Offers = require(shared:WaitForChild("MineRotatingOffers"))
	local deal = Offers.byId(key)
	if deal and deal.kind == "deal" then
		if not Offers.isLive(deal) then
			net:FireClient(plr, "toast", deal.neverReturns and "That deal is gone. It is not coming back." or "That offer is not up right now.")
			return
		end
		local why = Offers.deny(p, deal)
		if why then
			net:FireClient(plr, "toast", why)
			return
		end
		local cost = tonumber(deal.credits) or 0
		if cost <= 0 then
			net:FireClient(plr, "toast", "Product has no credit price")
			return
		end
		if C.limitedSaleOpen and not C.limitedSaleOpen() then
			net:FireClient(plr, "toast", "That limited is not on sale yet")
			return
		end
		if (p.credits or 0) < cost then
			net:FireClient(plr, "toast", string.format("Need %d credits (you have %d)", cost, math.floor(p.credits or 0)))
			return
		end
		p.credits -= cost
		if not Offers.grant(p, deal) then
			p.credits += cost
			net:FireClient(plr, "toast", "Could not grant that deal")
			return
		end
		net:FireClient(plr, "toast", deal.toast or (deal.title .. " claimed"))
		if deal.charm then
			walk(plr)
		end
		markDirty(plr)
		save(plr)
		snap(plr)
		return
	end
	if key == "lucky_charm" or key == "lucky_block_pet" then
		net:FireClient(plr, "toast", "That offer moved. Check the limited deals.")
		return
	end
	local prod = C.product and C.product(key)
	if not prod then
		net:FireClient(plr, "toast", "Unknown product")
		return
	end
	if key ~= "patron_rig" and C.limitedSaleOpen and not C.limitedSaleOpen() then
		net:FireClient(plr, "toast", "That limited is not on sale yet")
		return
	end
	local cost = tonumber(prod.creditsPrice) or tonumber(prod.robuxPrice) or 0
	if cost <= 0 then
		net:FireClient(plr, "toast", "Product has no credit price")
		return
	end
	if key == "lucky_charm" then
		p.charms = p.charms or {}
		if p.charms.lucky_charm then
			net:FireClient(plr, "toast", "You already own Lucky Charm")
			return
		end
	elseif key == "lucky_block_pet" then
		p.ownedPets = p.ownedPets or {}
		if p.ownedPets.lucky_block then
			net:FireClient(plr, "toast", "You already own Lucky Block pet")
			return
		end
	elseif key == "patron_rig" then
		local target = nil
		for i, bp in ipairs(C.BACKPACKS or {}) do
			if bp.robux then target = i break end
		end
		if not target then
			net:FireClient(plr, "toast", "Founders Rig not configured")
			return
		end
		if p.foundersBag or (p.backpackTier or 1) >= target then
			net:FireClient(plr, "toast", "You already have Founders Rig")
			return
		end
	elseif key == "starter_bundle" then
		if p.starterBought then
			net:FireClient(plr, "toast", "Starter Crate already owned")
			return
		end
	elseif key == "weekend_haul" then
		-- Repeatable crate.
	elseif key == "pet_slot" then
		-- Retired. Three seats for everyone; nothing to sell.
		net:FireClient(plr, "toast", "Three pet seats is the limit -- there is no fourth to buy")
		return
	elseif key == "coin_double" then
		if p.coinDouble then
			net:FireClient(plr, "toast", "2x Coins already active")
			return
		end
	elseif key == "auto_mine" then
		if p.autoMineLicense then
			net:FireClient(plr, "toast", "Auto-Mine already licensed")
			return
		end
	else
		net:FireClient(plr, "toast", "Cannot buy that with credits")
		return
	end
	--[[
		Three of any one dev product per player, ever (MineConfig.CREDIT_BUY_LIMIT).

		Checked before the credit balance so the refusal reads as "you have had
		your three" rather than "you are broke", and counted only once the
		purchase is actually going through -- a player who could not afford it
		has not spent one of their three.
	]]
	p.creditBuys = p.creditBuys or {}
	local capLeft = math.max(0, math.floor(tonumber(C.CREDIT_BUY_LIMIT) or 3))
	local boughtBefore = math.max(0, math.floor(tonumber(p.creditBuys[key]) or 0))
	if capLeft > 0 and boughtBefore >= capLeft then
		net:FireClient(plr, "toast", string.format("%s: you have bought the most allowed (%d)",
			tostring(prod.name or key), capLeft))
		return
	end
	if (p.credits or 0) < cost then
		net:FireClient(plr, "toast", string.format("Need %d credits (you have %d)", cost, math.floor(p.credits or 0)))
		return
	end
	p.credits -= cost
	p.creditBuys[key] = boughtBefore + 1
	if key == "lucky_charm" then
		p.charms.lucky_charm = true
		net:FireClient(plr, "toast", "Lucky Charm owned — equip in Inventory → Equipment")
		walk(plr)
	elseif key == "lucky_block_pet" then
		p.ownedPets.lucky_block = true
		net:FireClient(plr, "toast", "Lucky Block pet owned")
	elseif key == "patron_rig" then
		local target = nil
		for i, bp in ipairs(C.BACKPACKS or {}) do
			if bp.robux then target = i break end
		end
		p.backpackTier = target
		p.foundersBag = true
		p.equippedBag = "founders"
		giveBackpackModel(plr)
		net:FireClient(plr, "toast", "Founders Rig unlocked")
	elseif key == "starter_bundle" then
		local prod = C.product("starter_bundle") or {}
		local wantBag = math.max(1, math.floor(tonumber(prod.bagRung) or 2))
		if (p.backpackTier or 1) < wantBag then
			p.backpackTier = wantBag
			giveBackpackModel(plr)
		end
		p.coins = (p.coins or 0) + (tonumber(prod.coins) or 8000)
		if (tonumber(prod.commonPet) or 1) > 0 then
			local setId = "dragons_dawn"
			local pool = Cards.indicesOfRarity and Cards.indicesOfRarity(setId, "Common") or {}
			if #pool > 0 then
				local index = pool[Random.new():NextInteger(1, #pool)]
				local def = Cards.getCard and Cards.getCard(setId, index)
				if def then
					table.insert(p.cards, mint(def, plr.UserId, true))
				end
			end
		end
		p.starterBought = true
		net:FireClient(plr, "toast", "Starter Crate unlocked!")
	elseif key == "weekend_haul" then
		local prod = C.product("weekend_haul") or {}
		Verbs.grantPacks(plr, p, prod.packs)
		for _, row in ipairs(prod.blocks or {}) do
			LuckyBlocks.grant(p, row.id, "F", row.qty or 1)
		end
		if prod.potionId then
			pcall(function()
				require(shared:WaitForChild("MinePotions")).grant(p, prod.potionId, prod.potionQty or 1)
			end)
		end
		net:FireClient(plr, "toast", "Weekend Haul claimed")
	elseif key == "pet_slot" then
		-- Retired. Three seats for everyone, so there is nothing to unlock. The
		-- buy path refuses before this, which is why nothing is refunded here.
		net:FireClient(plr, "toast", "Pet seats are no longer sold -- everyone has three")
	elseif key == "coin_double" then
		p.coinDouble = true
		net:FireClient(plr, "toast", "2x Coins active")
	elseif key == "auto_mine" then
		p.autoMineLicense = true
		net:FireClient(plr, "toast", "Auto-Mine License active")
	end
	markDirty(plr)
	save(plr)
	snap(plr)
end

local function buyBattlePassCredits(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	p.pass = p.pass or Scrolls.emptyPass()
	if p.pass.owned then
		net:FireClient(plr, "toast", "Battle Pass already owned")
		return
	end
	local bp = Scrolls.BATTLE_PASS
	local cost = tonumber(bp and bp.credits) or tonumber(bp and bp.robux) or 399
	if (p.credits or 0) < cost then
		net:FireClient(plr, "toast", string.format("Need %d credits (you have %d)", cost, math.floor(p.credits or 0)))
		return
	end
	p.credits -= cost
	p.pass.owned = true
	p.pass.boughtAt = os.time()
	net:FireClient(plr, "toast", "Battle Pass unlocked — claim tiers in Inventory > Pass")
	markDirty(plr)
	save(plr)
	snap(plr)
end

local function buyZone(plr, zoneId)
	local p = profiles[plr.UserId]
	if not p then
		net:FireClient(plr, "toast", "Profile not loaded — try again")
		return
	end
	-- Accept a bare id string or a small table from Events / older clients.
	if type(zoneId) == "table" then
		zoneId = zoneId.id or zoneId.zoneId or zoneId.zone
	end
	local wantId = tostring(zoneId or "")
	local zone = nil
	local idx = nil
	for i, z in ipairs(C.ZONES) do
		if z.id == wantId then
			zone, idx = z, i
			break
		end
	end
	if not zone then
		net:FireClient(plr, "toast", "Unknown zone: " .. wantId)
		return
	end
	if zone.limited then
		if not (C.limitedActive and C.limitedActive()) then
			net:FireClient(plr, "toast", zone.name .. " event has ended")
			return
		end
		if p.bigbangOwned then
			net:FireClient(plr, "toast", "Already unlocked")
			return
		end
		p.bigbangOwned = true
		p.wormholeBag = true
		p.eventTools = p.eventTools or {}
		p.eventTools.eh_shallow_pick = true
		p.eventToolId = p.eventToolId or "eh_shallow_pick"
		net:FireClient(plr, "toast", "Unlocked " .. zone.name .. " — Wormhole Bag is yours")
		markDirty(plr)
		snap(plr)
		return
	end
	-- Clamp: a stored 0 must not skip meadow (Lua treats 0 as truthy, so `or 1` fails).
	local have = math.max(1, tonumber(p.maxUnlockedZone) or 1)
	if idx <= have then
		net:FireClient(plr, "toast", string.format("Already unlocked (own zone %d)", have))
		return
	end
	if idx ~= have + 1 then
		local prev = C.ZONES[have + 1]
		net:FireClient(plr, "toast", string.format(
			"Unlock %s first (you own up to zone %d)",
			(prev and prev.name) or "the previous zone", have))
		return
	end
	-- Use >= via a less-than reject (not exact equality on prestige).
	local prest = tonumber(p.prestige) or 0
	local needR = tonumber(zone.minRebirth) or 0
	if prest < needR then
		net:FireClient(plr, "toast", string.format("Need Rebirth %d+ (you are R%d)", needR, prest))
		return
	end
	local cost = math.floor(tonumber(zone.buyCost) or 0)
	local gems = tonumber(p.gems) or 0
	-- Tutorial zone step: if the starter gems were spent on the way (a rune
	-- fuse, a gear roll), top up the difference -- once, and only here.
	if gems < cost and idx == 2 and (tonumber(p.intro) or 1) == 12 then
		p.introGrants = p.introGrants or {}
		if not p.introGrants["12buy"] then
			p.introGrants["12buy"] = true
			p.gems = cost
			gems = cost
		end
	end
	if gems < cost then
		net:FireClient(plr, "toast", string.format("Need %s gems (you have %s)", tostring(cost), tostring(math.floor(gems))))
		return
	end
	p.gems = gems - cost
	p.maxUnlockedZone = idx
	MineBadges.onZoneUnlocked(plr, idx)
	introAdvance(plr, p, 12)
	-- Age every prior permanent zone one rank step; inject new S chests.
	do
		local ZoneChests = require(shared:WaitForChild("MineZoneChests"))
		ZoneChests.onPermanentZoneUnlocked(wantId)
	end
	net:FireClient(plr, "toast", string.format("Unlocked %s (-%s gems)", zone.name, tostring(cost)))
	markDirty(plr)
	save(plr)
	snap(plr)
end

local function buy(plr, kind)
	local p = profiles[plr.UserId]
	-- No surface gate: the player now spawns in the mine and camp is 200
	-- studs away. Item M puts the Toolsmith in the lobby, which gates this
	-- by geography instead of by a rule the player cannot satisfy.
	if kind == "pickaxe" then
		buyTool(plr, "pickaxe")
		return
	elseif kind == "backpack" or (type(kind) == "table" and kind.what == "backpack") then
		-- Any rung you can afford, in any order, and buying ahead grants
		-- everything under it. This was hardcoded to backpackTier + 1, so on a
		-- thirty rung ladder you could not buy the twentieth bag without first
		-- buying the nineteenth -- the tool ladders stopped working that way a
		-- while ago and bags were missed.
		local want = (type(kind) == "table" and tonumber(kind.tier)) or (p.backpackTier + 1)
		want = math.clamp(math.floor(want), 1, #C.BACKPACKS)
		if want <= (p.backpackTier or 1) then
			net:FireClient(plr, "toast", "You already have that bag")
			return
		end
		local row = C.BACKPACKS[want]
		if not row then return end
		if row.fossil then
			--[[
				These rungs were crafted on the fossil track, which is gone. They
				CANNOT be dropped from the roster: a bag id is "bag_<index into
				MineBags.LIST>", so removing 60 rows would silently hand every
				player a different bag. They stay as unreachable index padding,
				off every shelf and every count, and this refusal stops a client
				naming one and buying it for coins. See §0.12.
			]]
			net:FireClient(plr, "toast", string.format("%s is not for sale", tostring(row.name or "That bag")))
			return
		end
		if row.robux then
			local prod = C.product and C.product("patron_rig")
			local pid = (prod and tonumber(prod.productId)) or tonumber(row.productId) or 0
			if pid > 0 then
				net:FireClient(plr, "promptProduct", pid)
			else
				net:FireClient(plr, "toast", "Founders Rig product not configured yet")
			end
			return
		end
		if row.limited == "bigbang" and not p.bigbangOwned then
			net:FireClient(plr, "toast", "Claim Event Horizon to unlock the Wormhole Bag")
			return
		end
		local needZ = math.floor(tonumber(row.minZone) or 1)
		if needZ > math.max(1, tonumber(p.maxUnlockedZone) or 1) then
			local z = C.ZONES[needZ]
			net:FireClient(plr, "toast", string.format("%s unlocks with %s", row.name, z and z.name or ("zone " .. needZ)))
			return
		end
		--[[
			BAGS COST GEMS.
		
			Coins are payment for work -- one per point of block HP -- so pricing
			the bag in coins meant the thing that lets you carry more coins was
			itself bought with coins, and the sink fought its own source.
		
			MineBags.gemPrice is 100 * 1.08^rung. The coin figure stays on the row
			(sell value, shop ordering and the dex all read it); this is only what
			the buy verb charges. The Founders Rig is Robux and returned above, so
			it never reaches here.
		
			Required locally: the `Bags` near the top of this file is scoped inside
			a pcall, and the file is on the Luau 200 register ceiling, so it cannot
			take a new top-level local.
		]]
		local okBags, BagsMod = pcall(require, shared:WaitForChild("MineBags"))
		local bagGems = (okBags and BagsMod and BagsMod.gemPrice)
			and BagsMod.gemPrice(want) or nil
		if not bagGems then
			net:FireClient(plr, "toast", "Bag prices are unavailable right now")
			return
		end
		if (p.gems or 0) < bagGems then
			net:FireClient(plr, "toast", string.format("%s costs %s gems",
				tostring(row.name or "That bag"), tostring(bagGems)))
			return
		end
		p.gems -= bagGems
		p.backpackTier = want
		giveBackpackModel(plr)
	elseif kind == "petSlot" then
		--[[
			There is no seat to buy. Three is everybody's number now, so this
			refuses rather than charging for a clamp that will not move.

			Kept rather than deleted because an old client still has the button;
			the refusal is what an old build should hear.
		]]
		net:FireClient(plr, "toast", "Three pet seats is the limit -- there is no fourth to buy")
		return
	elseif kind == "itemSlots" then
		--[[
			One rung of the ITEM bag -- the shelf the Inventory screen is a view
			of. Nothing to do with the backpack, which carries dirt.

			Capacity is always derived from the rung count, never stored, so a
			profile cannot drift out of step with the formula.
		]]
		local cost = C.itemSlotPrice(p)
		if (p.gems or 0) < cost then
			net:FireClient(plr, "toast", string.format("+%d item slots costs %s gems",
				C.ITEM_SLOTS_STEP, tostring(cost)))
			return
		end
		p.gems -= cost
		p.itemSlotUpgrades = C.itemSlotUpgrades(p) + 1
		net:FireClient(plr, "toast", string.format("Item bag: %d slots", C.itemSlotCap(p)))
	elseif kind == "crate" then
		if p.gems < C.CRATE_PRICE then net:FireClient(plr, "toast", "Not enough gems") return end
		p.gems -= C.CRATE_PRICE
		local zone = C.zoneById(p.zoneId)
		table.insert(p.packs, { setId = zone.sets[Random.new():NextInteger(1, #zone.sets)] })
		net:FireClient(plr, "toast", "Crate packed!")
	end
	snap(plr)
end

local function tryPrestige(plr)
	local p = profiles[plr.UserId]
	-- Rebirth is bought, not walked to. The old gate made you touch the bottom
	-- of the deepest zone first, which is a lap of the map rather than a
	-- decision -- and it made gems irrelevant to the one choice that matters.
	local nextR = (p.prestige or 0) + 1
	local need = Skills.rebirthCost(nextR)
	-- Coins only. Gems are the currency you bank across rebirths -- charging
	-- them here taxed the one thing that was supposed to survive the reset.
	if (p.coins or 0) < need then
		net:FireClient(plr, "toast", string.format("Rebirth %d needs %s coins",
			nextR, tostring(need)))
		return
	end
	local minBank = Skills.minRebirthCoins(nextR)
	if (p.coins or 0) < minBank then
		net:FireClient(plr, "toast", string.format(
			"Early rebirth — minimum bank is %s (you have %s). Continuing…",
			tostring(minBank), tostring(math.floor(p.coins or 0))))
	end
	p.coins -= need
	local fresh = blank()
	fresh.cards, fresh.equipped, fresh.dust, fresh.packs = p.cards, p.equipped, p.dust, p.packs
	fresh.relics, fresh.charter = p.relics or {}, p.charter or {}
	-- Flagships are items you found, not progress you earned; they stay.
	fresh.chestTools, fresh.chestTool = p.chestTools or {}, p.chestTool
	fresh.found = p.found or {}
	fresh.petSlots = p.petSlots
	fresh.prestige = (p.prestige or 0) + 1
	-- Zones are bought with gems; rebirth does not gift the next island.
	fresh.maxUnlockedZone = p.maxUnlockedZone or 1
	fresh.bigbangOwned = p.bigbangOwned and true or false
	fresh.coreSamples = p.coreSamples or {}
	fresh.coreRiftOpened = p.coreRiftOpened or {}
	-- Skills survive a rebirth -- they ARE the rebirth reward.
	fresh.skillEarned = (p.skillEarned or 0) + Skills.tokensFor(fresh.prestige)
	-- Bought with tokens, so a rebirth does not take them away.
	fresh.skillBought = p.skillBought or 0
	fresh.skillPresets = p.skillPresets
	fresh.skillSlot = p.skillSlot
	fresh.boughtSecond = p.boughtSecond
	-- Sold points stay sold. Tokens carry over, and every rebirth adds its own:
	-- enough to buy back all the skill points that rebirth grants.
	fresh.skillBurned = p.skillBurned or 0
	fresh.temperTokens = (p.temperTokens or 0) + Skills.rebirthTokens(fresh.prestige)
	--[[
		FORGED ORE TOOLS SURVIVE A REBIRTH. The whole rack, and what is in hand.

		They were not carried, so rebirth destroyed every tool a player had
		forged and levelled -- and a forged tool is THE tool now: they are built
		from ore and levelled with ore plus stardust, and nothing is found in a
		wall any more. Wiping them meant rebirth deleted the entire tool
		investment while the ore pouch beside it survived, which is incoherent
		as well as harsh.

		The COIN-LADDER tools (pickaxeTier and the shop rungs) still reset, and
		that is deliberate and unchanged: those are the cheap early rungs rebirth
		is meant to make you re-buy quickly, and their socketed runes stay on the
		family so nothing permanent is lost. Forged tools are the opposite -- paid
		for in a currency that itself survives.
	]]
	fresh.oreTools = p.oreTools or {}
	fresh.oreToolEquipped = p.oreToolEquipped
	-- Coin-ladder tools reset; socketed runes stay on the family through rebirth.
	fresh.runes = p.runes
	fresh.gear = p.gear
	fresh.equippedGear = p.equippedGear
	fresh.petSockets = p.petSockets
	fresh.charms = p.charms or {}
	fresh.equippedCharm = p.equippedCharm
	fresh.persistBags = p.persistBags or {}
	fresh.backpackBonus = p.backpackBonus or 0
	--[[
		THE POUCH CROSSES THE REBIRTH. All of it: the rung bought with gems, the
		ore inside, the locks, and the discovered-ore set.

		This is the one store that does, and it is the reason the pouch exists.
		A rebirth resets the mine and the levels; a run spent deep for ore must
		not be erased by the button that makes the next run faster, or the
		correct play becomes "never rebirth while holding anything".
	]]
	fresh.orePouchTier = p.orePouchTier or 1
	fresh.ores = p.ores or {}
	fresh.oreLocks = p.oreLocks or {}
	fresh.oresSeen = p.oresSeen or {}

	-- A few gems for every rebirth (MineSkillData.rebirthGemReward).
	local rebirthGems = Skills.rebirthGemReward and Skills.rebirthGemReward(fresh.prestige, fresh.maxUnlockedZone) or 0
	fresh.gems = (p.gems or 0) + rebirthGems
	fresh.credits = p.credits or 0
	fresh.scrolls = p.scrolls or Scrolls.emptyBag()
	fresh.toolSockets = p.toolSockets or { pickaxe = nil, drill = nil, explosive = nil }
	-- Temperaments ride on the family too, so the coin ladder resetting does not
	-- take a roll you paid tokens for.
	fresh.toolTempers = p.toolTempers or {}
	fresh.tempers = p.tempers or {}
	-- Dailies / contracts / pass are day-bound progress, not a reset table.
	fresh.dailyQuests = p.dailyQuests
	fresh.contracts = p.contracts
	fresh.pass = p.pass
	fresh.daily = p.daily
	fresh.stats = p.stats or { blocks = 0, sells = 0, packs = 0, merges = 0, chests = 0, rebirth = 0 }
	fresh.quest = p.quest
	fresh.questBase = p.questBase
	-- Everything that is not the coin ladder rides along. This list is why the
	-- tutorial restarted at step 1 after every rebirth, and why codes, the
	-- Discord bonus and milestones could be claimed again.
	for _, k in ipairs(Verbs.KEEP_ON_REBIRTH) do
		if p[k] ~= nil then
			fresh[k] = p[k]
		end
	end
	Verbs.rebaseVolatileQuests(p, fresh)
	profiles[plr.UserId] = fresh
	if math.floor(tonumber(fresh.intro) or 0) == 18 then
		fresh.temperTokens = (fresh.temperTokens or 0) + 100
		net:FireClient(plr, "toast", "Rebirth quest: +100 temperament tokens")
		introAdvance(plr, fresh, 18)
	elseif math.floor(tonumber(fresh.intro) or 0) == 37 and (fresh.prestige or 0) >= 5 then
		fresh.gems = (fresh.gems or 0) + 50
		introAdvance(plr, fresh, 37)
	end
	bumpStat(plr, fresh, "rebirth")
	--[[
		Save on the spot.

		A rebirth is the single moment in the game a player most cannot afford to
		lose: it spends every coin they have and hands back skill points. Waiting
		for the 45-second autosave meant a disconnect in that window charged them
		the coins and gave them nothing -- which is exactly what "rebirth doesn't
		save" looks like from the outside.
	]]
	save(plr)
	snap(plr)
	-- Up, not back to the deck. Rebirth is the one moment the game asks you
	-- to stop and re-plan, and it read like a respawn.
	tp(plr, cloudCf())
	givePickaxe(plr)
	giveBackpackModel(plr)
	net:FireClient(plr, "toast", string.format("Rebirth %d! +%d skill points, +%d tokens, +%d gems. Tool runes stay socketed through rebirth.",
		fresh.prestige, Skills.tokensFor(fresh.prestige), Skills.rebirthTokens(fresh.prestige), rebirthGems))
	if fresh.prestige == 1 then
		local Temper = require(shared.MineTemper)
		local n = tonumber(Temper.CASE_BUNDLE_COUNT) or 3
		local price = tonumber(Temper.CASE_BUNDLE_TOKENS) or 50
		net:FireClient(plr, "toast", string.format("Temper tip: %d cases for %d tokens at the Enchanter (vs %d singles)", n, price, n * (tonumber(Temper.CASE_PRICE_TOKENS) or 20)))
		net:FireClient(plr, "temperCaseBundleOffer", { n = n, price = price })
	end
	--[[
		Put the skill tree in front of them.

		Rebirth's entire reward is skill points, and the game used to hand them
		over silently and leave the player standing in the clouds with no idea
		anything had been granted. The one moment the game asks you to stop and
		re-plan should open the screen you re-plan on.
	]]
	net:FireClient(plr, "openPanel", "skills")
end

function Verbs.debugGrantRune(plr, payload)
	if not Svc.Run:IsStudio() then return end
	local p = profiles[plr.UserId]
	if not p then return end
	p.runes = p.runes or {}
	p.scrolls = p.scrolls or Scrolls.emptyBag()
	p.gear = p.gear or {}
	p.equippedGear = p.equippedGear or {}

	local n = math.clamp(tonumber(payload and payload.count) or 20, 1, 50)
	local rng = Random.new()
	for _ = 1, n do
		-- T10 blast: 0.60% doubled nine times.
		table.insert(p.runes, {
			id = instanceHex16(),
			kind = "explosive",
			stat = "blastRadius",
			tier = 10,
			pct = Runes.pctForTier("blastRadius", 10),
			level = 10,
		})
	end
	-- Tier/level 99 "damage" runes = pickaxe mineSpeed (tool power).
	local nDmg = math.clamp(tonumber(payload and payload.damageCount) or 20, 1, 50)
	for _ = 1, nDmg do
		table.insert(p.runes, {
			id = instanceHex16(),
			kind = "pickaxe",
			stat = "mineSpeed",
			tier = 10,
			pct = Runes.pctForTier("mineSpeed", 10),
			level = 99,
		})
	end
	p.scrolls.white = (p.scrolls.white or 0) + 1

	-- Full Exotic Inferno (blast) set, equipped.
	for _, slot in ipairs(Gear.SLOTS) do
		local piece = Gear.makePiece(instanceHex16(), "inferno", slot, "SSS",
			Gear.catalogFor and Gear.catalogFor(slot, "SSS", "inferno", Random.new()) or nil)
		if piece then
			piece.stat = "blastRadius"
			table.insert(p.gear, piece)
			p.equippedGear[slot] = piece.id
		end
	end

	givePickaxe(plr)
	net:FireClient(plr, "toast", string.format("Granted %d blast + %d L99 damage runes, Sinkhole, Exotic Inferno", n, nDmg))
	snap(plr)
	walk(plr)
end

function Verbs.debugGrantBlastSet(plr)
	if not Svc.Run:IsStudio() then return end
	local p = profiles[plr.UserId]
	if not p then return end
	p.gear = p.gear or {}
	p.equippedGear = p.equippedGear or {}
	for _, slot in ipairs(Gear.SLOTS) do
		local piece = Gear.makePiece(instanceHex16(), "inferno", slot, "SSS",
			Gear.catalogFor and Gear.catalogFor(slot, "SSS", "inferno", Random.new()) or nil)
		if piece then
			piece.stat = "blastRadius"
			table.insert(p.gear, piece)
			p.equippedGear[slot] = piece.id
		end
	end
	net:FireClient(plr, "toast", "Granted full Exotic Inferno (blast) set — equipped")
	snap(plr)
	walk(plr)
end

function Verbs.debugGrantL99Blast(plr, payload)
	if not Svc.Run:IsStudio() then return end
	local p = profiles[plr.UserId]
	if not p then return end
	p.runes = p.runes or {}
	local n = math.clamp(tonumber(payload and payload.count) or 5, 1, 30)
	local rng = Random.new()
	for _ = 1, n do
		table.insert(p.runes, {
			id = instanceHex16(),
			kind = "explosive",
			stat = "blastRadius",
			tier = 10,
			pct = Runes.pctForTier("blastRadius", 10),
			level = 99,
		})
	end
	net:FireClient(plr, "toast", string.format("Granted %d× L99 +300%% blast runes (gear-socketable)", n))
	snap(plr)
end

--[[
	Buy rolls in bulk.

	`payload.count` is how many; 100 is the ceiling so one fat-fingered click
	cannot drain an account. Each roll is charged and resolved on its own, and
	the loop stops the moment gems run short -- you are never charged for a roll
	you did not get. Nothing about the odds changes with volume.
]]
-- Const.ROLL_MAX on Const

local function rollCount(payload)
	local n = tonumber(payload)
	if type(payload) == "table" then
		n = tonumber(payload.count)
	end
	return math.clamp(math.floor(n or 1), 1, Const.ROLL_MAX)
end

function Verbs.rollRuneBanner(plr, payload)
	local p = profiles[plr.UserId]
	local want = rollCount(payload)
	local price = Runes.rollPriceFor(p.maxUnlockedZone)
	if (p.gems or 0) < price then
		net:FireClient(plr, "toast", "Need " .. price .. " gems")
		return
	end
	local done = 0
	local def = Packs.PACK_BY_ID.rune_pack
	p.packs = p.packs or {}
	for _ = 1, want do
		if (p.gems or 0) < price then break end
		p.gems -= price
		done += 1
		table.insert(p.packs, {
			packId = "rune_pack",
			packName = (def and def.name) or "Rune Pouch",
			kind = "rune",
		})
	end
	if done == 1 then
		net:FireClient(plr, "toast", (def and def.name or "Rune Pouch") .. "!")
	elseif done > 1 then
		net:FireClient(plr, "toast", string.format("%d× %s  (-%s gems)",
			done, (def and def.name) or "Rune Pouch", tostring(done * price)))
	end
	if done < want then
		net:FireClient(plr, "toast", string.format("Ran out of gems after %d of %d", done, want))
	end
	if done > 0 then
		introAdvance(plr, p, 8)
		-- The pouch flies into the bag on screen (MineClient flyToBag).
		net:FireClient(plr, "purchaseFx", { kind = "pack", packId = "rune_pack", count = done,
			name = (def and def.name) or "Rune Pouch" })
	end
	snap(plr)
	walk(plr)
end

function Verbs.rollGearBanner(plr, payload)
	local p = profiles[plr.UserId]
	local want = rollCount(payload)
	-- Hats are bought with REBIRTH TOKENS now, not gems (TODO 6.2). Flat price;
	-- see MineGear.ROLL_TOKEN_COST for why it is not zone-scaled.
	local price = tonumber(Gear.ROLL_TOKEN_COST) or 5
	-- The first gear roll a player ever makes is free (the tutorial's gear
	-- step). It is the FIRST draw only: charging per iteration is what keeps
	-- a 100x click from handing out a hundred free crates.
	local freeOne = (not p.freeGearUsed) and #(p.gear or {}) == 0
	if not freeOne and (tonumber(p.temperTokens) or 0) < price then
		net:FireClient(plr, "toast", "Need " .. price .. " tokens")
		return
	end
	local def = Packs.PACK_BY_ID.gear_pack
	p.packs = p.packs or {}
	local done, spent = 0, 0
	for i = 1, want do
		local cost = (i == 1 and freeOne) and 0 or price
		if (tonumber(p.temperTokens) or 0) < cost then break end
		p.temperTokens = (tonumber(p.temperTokens) or 0) - cost
		spent += cost
		if i == 1 and freeOne then
			p.freeGearUsed = true
		end
		done += 1
		table.insert(p.packs, {
			packId = "gear_pack",
			packName = (def and def.name) or "Gear Crate",
			kind = "gear",
		})
	end
	if done == 1 then
		net:FireClient(plr, "toast", (def and def.name or "Gear Crate") .. "!")
	elseif done > 1 then
		net:FireClient(plr, "toast", string.format("%d× %s  (-%s tokens)",
			done, (def and def.name) or "Gear Crate", tostring(spent)))
	end
	if done < want then
		net:FireClient(plr, "toast", string.format("Ran out of tokens after %d of %d", done, want))
	end
	if done > 0 then
		net:FireClient(plr, "purchaseFx", { kind = "pack", packId = "gear_pack", count = done,
			name = (def and def.name) or "Gear Crate" })
	end
	snap(plr)
	walk(plr)
end

function Verbs.mergeHats(plr, payload)
	local p = profiles[plr.UserId]
	if not p then return end
	local aId, bId = payload and payload.a, payload and payload.b
	local a, b = gearById(p, aId), gearById(p, bId)
	if not a or not b or aId == bId then
		net:FireClient(plr, "toast", "Pick two different hats")
		return
	end
	-- Unequip first — a worn hat cannot be consumed.
	local function strip(id)
		for slot, gid in pairs(p.equippedGear or {}) do
			if gid == id then p.equippedGear[slot] = nil end
		end
	end
	strip(aId)
	strip(bId)
	local merged, err = Gear.mergeHats(a, b, instanceHex16())
	if not merged then
		net:FireClient(plr, "toast", err or "Cannot merge")
		return
	end
	-- Remove both inputs, insert result.
	local kept = {}
	for _, g in ipairs(p.gear or {}) do
		if g.id ~= aId and g.id ~= bId then
			table.insert(kept, g)
		end
	end
	table.insert(kept, merged)
	p.gear = kept
	net:FireClient(plr, "toast", "Hats merged!")
	markDirty(plr)
	snap(plr)
end

--[[
	Fuse two matching pieces into one of the next grade, capped at FUSE_CAP.

	MineGear.canUpgrade owns the rules, and the panel calls the very same
	function to decide which pairs to offer, so the screen and this verb cannot
	disagree about what is legal. It is re-checked here regardless: the client
	names two ids and nothing else, because a client that names its own outcome
	is not a client.

	`gear in use` deliberately counts pet hats as well as worn pieces. A hat
	sitting on a pet is not lying around spare, and consuming it out from under
	the pet is not something anybody asked for.
]]
function Verbs.upgradeGear(plr, payload)
	local p = profiles[plr.UserId]
	if not p then return end
	local aId, bId = payload and payload.a, payload and payload.b
	local a, b = gearById(p, aId), gearById(p, bId)
	if not a or not b then
		net:FireClient(plr, "toast", "Pick two pieces")
		return
	end
	local used = {}
	for _, id in pairs(p.equippedGear or {}) do
		if id then used[id] = true end
	end
	local ok, why = Gear.canUpgrade(a, b, used)
	if not ok then
		net:FireClient(plr, "toast", why or "Cannot upgrade")
		return
	end
	local was = a.rarity
	local made = Gear.upgradedFrom(a, instanceHex16())
	if not made then
		net:FireClient(plr, "toast", "Cannot upgrade")
		return
	end
	local kept = {}
	for _, g in ipairs(p.gear or {}) do
		if g.id ~= aId and g.id ~= bId then
			table.insert(kept, g)
		end
	end
	table.insert(kept, made)
	p.gear = kept
	net:FireClient(plr, "toast", string.format("%s  %s -> %s",
		tostring(made.name or "Gear"), tostring(was), tostring(made.rarity)))
	net:FireClient(plr, "gearUpgraded", { id = made.id, from = was, to = made.rarity })
	markDirty(plr)
	snap(plr)
end

function Verbs.fuseRunes(plr, payload)
	local p = profiles[plr.UserId]
	local aId, bId = payload and payload.a, payload and payload.b
	local a, b = runeById(p, aId), runeById(p, bId)
	if not a or not b or aId == bId then net:FireClient(plr, "toast", "Pick two different runes") return end
	if runeBusy(p, aId) or runeBusy(p, bId) then net:FireClient(plr, "toast", "Unequip both runes before fusing") return end
	local preview, err = Runes.fusePreview(a, b)
	if not preview then net:FireClient(plr, "toast", err or "Cannot fuse") return end
	if (p.gems or 0) < preview.cost then net:FireClient(plr, "toast", "Need " .. preview.cost .. " gems") return end
	local protected = (a.whiteArmed == true) or (b.whiteArmed == true)
	p.gems -= preview.cost
	--[[
		One flat independent coin flip, Runes.FUSE_SUCCESS, every attempt.

		There is no pity ledger, no per-level fail counter and no way to force a
		win. The previous version kept p.fusePity keyed on levelA+levelB and
		handed out a guaranteed success after five failures; that is exactly
		what must not exist here. Do not add it back in any form.
	]]
	local chance = Runes.FUSE_SUCCESS
	local hit = Random.new():NextNumber() < chance
	-- Consume white arming either way; mark whiteUsed so future fuses are 5x.
	local function consumeWhite(r)
		if r.whiteArmed then
			r.whiteArmed = nil
			r.whiteUsed = true
		end
	end
	if not hit then
		if protected then
			consumeWhite(a)
			consumeWhite(b)
			net:FireClient(plr, "toast", string.format("Fuse failed (%.0f%%). White Scroll saved both runes.", chance * 100))
		else
			removeRune(p, aId)
			removeRune(p, bId)
			net:FireClient(plr, "toast", string.format("Fuse failed (%.0f%%). Both runes destroyed.", chance * 100))
		end
		snap(plr)
		return
	end
	consumeWhite(a)
	consumeWhite(b)
	local whiteUsed = a.whiteUsed or b.whiteUsed or false
	removeRune(p, aId)
	removeRune(p, bId)
	local out = {
		id = instanceHex16(), kind = preview.kind, stat = preview.stat, pct = preview.pct,
		tier = preview.tier,
		level = preview.level, secondaryStat = preview.secondaryStat, secondaryPct = preview.secondaryPct,
		whiteUsed = whiteUsed,
	}
	table.insert(p.runes, out)
	net:FireClient(plr, "toast", "Fused! " .. Runes.describe(out))
	snap(plr)
	walk(plr)
end

function Verbs.socketToolRune(plr, payload)
	local p = profiles[plr.UserId]
	local runeId = payload and payload.runeId
	local family = tostring(payload and payload.family or p.toolFamily or "pickaxe")
	local chestId = payload and payload.chestId
	local shopToolId = payload and payload.shopToolId
	local rune = runeById(p, runeId)
	if not rune then net:FireClient(plr, "toast", "Unknown rune") return end
	if runeBusy(p, runeId) then net:FireClient(plr, "toast", "That rune is already socketed") return end
	local function bindDestroyingPrevious(prevId, assign)
		if prevId then
			if (p.gems or 0) < Runes.RESOCKET_PRICE then
				net:FireClient(plr, "toast", "Destroying the old rune costs " .. Runes.RESOCKET_PRICE .. " gems")
				return false
			end
			p.gems -= Runes.RESOCKET_PRICE
			removeRune(p, prevId)
		end
		assign()
		return true
	end
	if chestId then
		local ct
		for _, row in ipairs(p.chestTools or {}) do if row.id == chestId then ct = row break end end
		if not ct then net:FireClient(plr, "toast", "Unknown chest tool") return end
		if not Runes.canSocketOnTool(rune, ct.family or family) then net:FireClient(plr, "toast", "Wrong rune kind") return end
		if not bindDestroyingPrevious(ct.runeId, function() ct.runeId = runeId end) then return end
	elseif shopToolId then
		-- Every coin-shop tool has its own socket (the client always sent
		-- shopToolId; nothing here read it, so the rune fell into the family
		-- socket or bounced with "Buy that tool first").
		shopToolId = tostring(shopToolId)
		if not (p.ownedShopTools and p.ownedShopTools[shopToolId]) then net:FireClient(plr, "toast", "Buy that tool first") return end
		p.shopToolRunes = p.shopToolRunes or {}
		if not bindDestroyingPrevious(p.shopToolRunes[shopToolId], function() p.shopToolRunes[shopToolId] = runeId end) then return end
	else
		if not Runes.canSocketOnTool(rune, family) then net:FireClient(plr, "toast", "Wrong rune kind for that tool") return end
		if (p.tools[family] or 0) <= 0 then net:FireClient(plr, "toast", "Buy that tool first") return end
		local slot = tostring(payload and payload.slot or "main")
		local sock = familySocket(p, family)
		if slot == "omni" and not sock.omniUnlocked then
			net:FireClient(plr, "toast", "Unlock omni socket with an Omniscroll first")
			return
		end
		local prevId = (slot == "omni") and sock.omni or sock.main
		if not bindDestroyingPrevious(prevId, function()
			if slot == "omni" then sock.omni = runeId else sock.main = runeId end
		end) then return end
	end
	net:FireClient(plr, "toast", "Socketed " .. Runes.describe(rune) .. " (locked until destroyed)")
	introAdvance(plr, p, 9)
	snap(plr)
	walk(plr)
end

local function destroyToolRune(plr, payload)
	local p = profiles[plr.UserId]
	local family = tostring(payload and payload.family or "")
	local chestId = payload and payload.chestId
	local shopToolId = payload and payload.shopToolId and tostring(payload.shopToolId)
	if (p.gems or 0) < Runes.RESOCKET_PRICE then
		net:FireClient(plr, "toast", "Destroying a socketed rune costs " .. Runes.RESOCKET_PRICE .. " gems")
		return
	end
	if shopToolId then
		local rid = p.shopToolRunes and p.shopToolRunes[shopToolId]
		if rid then
			p.gems -= Runes.RESOCKET_PRICE
			removeRune(p, rid)
			p.shopToolRunes[shopToolId] = nil
			net:FireClient(plr, "toast", "Rune destroyed")
			snap(plr)
			walk(plr)
			return
		end
	elseif chestId then
		for _, ct in ipairs(p.chestTools or {}) do
			if ct.id == chestId and ct.runeId then
				p.gems -= Runes.RESOCKET_PRICE
				removeRune(p, ct.runeId)
				ct.runeId = nil
				net:FireClient(plr, "toast", "Rune destroyed")
				snap(plr)
				walk(plr)
				return
		end
		end
	elseif family ~= "" then
		local slot = tostring(payload and payload.slot or "main")
		local sock = familySocket(p, family)
		local runeId = (slot == "omni") and sock.omni or sock.main
		if runeId then
			p.gems -= Runes.RESOCKET_PRICE
			removeRune(p, runeId)
			if slot == "omni" then sock.omni = nil else sock.main = nil end
			net:FireClient(plr, "toast", "Rune destroyed")
			snap(plr)
			walk(plr)
			return
		end
	end
	net:FireClient(plr, "toast", "No socketed rune to destroy")
end

function Verbs.socketPetRune(plr, payload)
	local p = profiles[plr.UserId]
	local rune = runeById(p, payload and payload.runeId)
	local cardId = payload and payload.cardId
	if not rune or not Runes.canSocketOnPet(rune) then net:FireClient(plr, "toast", "Only pet runes go on pets") return end
	if not cardById(p, cardId) then net:FireClient(plr, "toast", "Unknown pet") return end
	if runeBusy(p, rune.id) then net:FireClient(plr, "toast", "Rune already socketed") return end
	if p.petSockets[cardId] then
		if (p.gems or 0) < Runes.RESOCKET_PRICE then net:FireClient(plr, "toast", "Resocket costs " .. Runes.RESOCKET_PRICE .. " gems") return end
		p.gems -= Runes.RESOCKET_PRICE
	end
	p.petSockets[cardId] = rune.id
	introAdvance(plr, p, 9)
	introAdvance(plr, p, 26)
	snap(plr)
	walk(plr)
end

function Verbs.unequipGearPiece(plr, payload)
	local p = profiles[plr.UserId]
	local slot = payload and payload.slot
	local gearId = payload and payload.gearId
	if type(slot) ~= "string" and type(gearId) ~= "string" then
		net:FireClient(plr, "toast", "Pick a slot")
		return
	end
	p.equippedGear = p.equippedGear or {}
	if type(gearId) == "string" then
		for _, s in ipairs(Gear.HAT_SLOTS or { "hat" }) do
			if p.equippedGear[s] == gearId then p.equippedGear[s] = nil end
		end
		if p.equippedGear.face == gearId then p.equippedGear.face = nil end
	elseif slot == "face" or table.find(Gear.HAT_SLOTS or { "hat" }, slot) then
		p.equippedGear[slot] = nil
	elseif not p.equippedGear[slot] then
		return
	else
		p.equippedGear[slot] = nil
	end
	Dig.upgradeCache[plr.UserId] = nil
	markDirty(plr)
	snap(plr)
	walk(plr)
	applyPlayerCosmetics(plr)
	net:FireClient(plr, "toast", (Gear.SLOT_LABEL[slot] or slot or "Gear") .. " off")
end

--[[
	ONE OWNED PIECE, ONE SEAT.

	A hat used to be able to sit on your head OR on a pet, so "my pet is wearing
	my hat" had to be stopped from being true twice and there was a
	clearGearFromPets to do it. Pets wear nothing now; the only way to double up
	is the same id in two of your own three seats, which old saves and old Equip
	Best runs both managed to produce.

	Seats keep FIRST claim in Gear.HAT_SLOTS order, so the primary hat is the one
	that survives a collision and the loser empties rather than silently sharing.
]]
local function sanitizeHatUniqueness(p)
	if type(p) ~= "table" then
		return
	end
	p.equippedGear = p.equippedGear or {}
	local eq = p.equippedGear
	local seen = {}
	for _, slot in ipairs(Gear.HAT_SLOTS or { "hat" }) do
		local id = eq[slot]
		if type(id) ~= "string" or id == "" or seen[id] then
			eq[slot] = nil
		else
			seen[id] = true
		end
	end
end

function Verbs.equipGearPiece(plr, payload)
	local p = profiles[plr.UserId]
	local piece = gearById(p, payload and payload.gearId)
	if not piece then net:FireClient(plr, "toast", "Unknown gear") return end
	Dig.upgradeCache[plr.UserId] = nil
	p.equippedGear = p.equippedGear or {}
	local slot = Gear.migrateSlot(piece.slot)
	if slot == "face" then
		p.equippedGear.face = piece.id
		introAdvance(plr, p, 25)
	else
		--[[
			Three hat seats. The same CATALOG hat in two seats is fine as long as
			they are two owned pieces with different ids; one id can never fill
			two seats.

			An explicit `slot` in the payload is honoured when it names a real
			seat, so the UI can put a hat where the player tapped. Without one it
			takes the first free seat, and replaces the primary when all three
			are full -- the primary being the one a player watching the first
			seat would expect to change.
		]]
		local eq = p.equippedGear
		local slots = Gear.HAT_SLOTS or { "hat" }
		local want = tostring((payload and payload.slot) or "")
		local onAlready, firstFree = false, nil
		for _, s in ipairs(slots) do
			if eq[s] == piece.id then
				onAlready = true
			elseif firstFree == nil and eq[s] == nil then
				firstFree = s
			end
		end
		local target = nil
		for _, s in ipairs(slots) do
			if s == want then
				target = s
				break
			end
		end
		if target then
			eq[target] = piece.id
		elseif onAlready then
			-- already on
		else
			eq[firstFree or slots[1]] = piece.id
		end
	end
	sanitizeHatUniqueness(p)
	net:FireClient(plr, "toast", "Equipped " .. Gear.describe(piece))
	introAdvance(plr, p, 10)
	snap(plr)
	walk(plr)
	applyPlayerCosmetics(plr)
end

function Verbs.socketGearRune(plr, payload)
	local p = profiles[plr.UserId]
	local piece = gearById(p, payload and payload.gearId)
	local rune = runeById(p, payload and payload.runeId)
	local index = tonumber(payload and payload.index) or 1
	if not piece or not rune then net:FireClient(plr, "toast", "Pick gear and rune") return end
	if not Runes.canSocketOnGear(rune) then net:FireClient(plr, "toast", "That rune cannot socket on gear") return end
	if runeBusy(p, rune.id) then net:FireClient(plr, "toast", "Rune already socketed") return end
	piece.sockets = piece.sockets or {}
	if index < 1 or index > (piece.slotCount or 0) then net:FireClient(plr, "toast", "No such socket") return end
	if piece.sockets[index] then net:FireClient(plr, "toast", "Socket filled forever - cannot remove") return end
	piece.sockets[index] = rune.id
	net:FireClient(plr, "toast", "Locked into gear (permanent)")
	introAdvance(plr, p, 9)
	snap(plr)
	walk(plr)
end

local function grantScrolls(p, id, qty)
	p.scrolls = p.scrolls or Scrolls.emptyBag()
	p.scrolls[id] = (p.scrolls[id] or 0) + qty
end

--[[
	Pouches and crates. A pouch is a blind pull from every set; a crate is aimed
	at one set and costs a lot more, which is how you finish the set you are
	three-quarters through. Both pay gems, so there is a non-Robux path to
	scrolls -- white protects a fuse, and fusing is the long grind.
]]
local function openRuneBox(plr, spec, setId)
	local p = profiles[plr.UserId]
	if not spec then
		net:FireClient(plr, "toast", "Unknown box")
		return
	end
	if (p.gems or 0) < spec.gems then
		net:FireClient(plr, "toast", "Need " .. spec.gems .. " gems")
		return
	end
	p.gems -= spec.gems
	local result = Runes.openBox(spec, setId, instanceHex16, Random.new())
	for _, r in ipairs(result.runes or {}) do
		table.insert(p.runes, r)
	end
	p.scrolls = p.scrolls or Scrolls.emptyBag()
	local extras = {}
	for id, n in pairs(result.scrolls or {}) do
		if n > 0 then
			p.scrolls[id] = (p.scrolls[id] or 0) + n
			table.insert(extras, n .. "x " .. id)
		end
	end
	table.sort(extras)
	local count = #(result.runes or {})
	local line = spec.name .. ": " .. count .. (count == 1 and " rune" or " runes")
	if #extras > 0 then
		line = line .. " + " .. table.concat(extras, ", ")
	end
	net:FireClient(plr, "toast", line)
	net:FireClient(plr, "boxOpened", { spec = spec.id, runes = result.runes, scrolls = result.scrolls })
	snap(plr)
	walk(plr)
end

function Verbs.buyPouch(plr, payload)
	openRuneBox(plr, Runes.pouch(payload and payload.tier), nil)
end

function Verbs.buyCrate(plr, payload)
	local setId = payload and payload.setId
	if not Runes.set(setId) then
		net:FireClient(plr, "toast", "Pick a set to aim the crate at")
		return
	end
	openRuneBox(plr, Runes.crate(payload and payload.tier), setId)
end

function Verbs.buyScroll(plr, payload)
	local p = profiles[plr.UserId]
	local id = payload and payload.id
	local item = Scrolls.itemById(id)
	if not item then
		net:FireClient(plr, "toast", "Unknown scroll")
		return
	end
	local cost, grant = item.price, 1
	if payload and payload.bundle then
		if not item.bundleQty then
			net:FireClient(plr, "toast", "No bundle for that item")
			return
		end
		cost = item.bundlePrice or (item.price * item.bundleQty)
		grant = item.bundleQty
	end
	cost = C.vipPrice(cost, hasVipPass(plr))

	--[[
		A TYPED QUANTITY. Owner: "a custom amoujt of packs to buy (the player
		can write the number themselves [default 1])".

		Multiplies whatever one unit costs -- so it stacks on a bundle too, and
		the VIP discount is applied before the multiply rather than after, or
		buying ten would round the discount away ten times.

		Short on credits pays out what you CAN afford rather than refusing,
		which is the same contract openMany documents for "open 10" off a stack
		of six. Refusing a 50-pack request because you can afford 49 is the
		behaviour that makes people stop using the box.
	]]
	local qty = math.clamp(math.floor(tonumber(payload and payload.qty) or 1),
		1, Const.BUY_QTY_MAX)
	local unit, unitGrant = cost, grant
	local have = tonumber(p.credits) or 0
	if unit > 0 then
		qty = math.min(qty, math.floor(have / unit))
	end
	if qty < 1 then
		net:FireClient(plr, "toast", "Need " .. unit .. " credits")
		return
	end
	cost, grant = unit * qty, unitGrant * qty

	if (p.credits or 0) < cost then
		net:FireClient(plr, "toast", "Need " .. cost .. " credits")
		return
	end
	p.credits -= cost
	if id == "runesmith" and item.grants then
		for k, v in pairs(item.grants) do
			grantScrolls(p, k, v)
		end
	else
		grantScrolls(p, id, grant)
	end
	net:FireClient(plr, "toast", "Bought " .. item.name .. (grant > 1 and (" x" .. grant) or ""))
	-- Say so when the box asked for more than the wallet could cover, or a
	-- short fill looks like the number was ignored.
	do
		local asked = math.clamp(math.floor(tonumber(payload and payload.qty) or 1),
			1, Const.BUY_QTY_MAX)
		if asked > qty then
			net:FireClient(plr, "toast", string.format(
				"Only %d of %d - that is what %d credits covered", qty, asked, have))
		end
	end
	snap(plr)
end

--[[
	CHECKOUT.

	One request for a whole cart, and the server prices all of it from its own
	tables. The client sends what it wants -- kind, id, whether it is the ten-pack
	-- and never sends a price, because a client that names its own price is a
	client that will eventually name zero.

	Credits are the only way to pay here. Robux buys credits on the Currencies
	tab and nothing else, which keeps every random item (packs) one step removed
	from real money: you cannot buy a pack with Robux, only with a currency you
	already hold. See "Item I -- odds disclosure" in TODO.md for why that
	distinction is load-bearing.

	The 10% is applied to the SUBTOTAL, once, not per line -- discounting each
	line and summing rounds differently and players do check.
]]
--[[
	FOUNDERS PACK (was Warehouse Pass).
	1000 credits / R$999. Logic in MineFounders.
]]
local function isVip(p)
	return require(shared.MineFounders).isMember(p)
end

local function joinVip(plr)
	local Founders = require(shared.MineFounders)
	local p = profiles[plr.UserId]
	if not p then return end
	if Founders.isMember(p) then
		net:FireClient(plr, "toast", "You already own Founders Pack")
		return
	end
	do
		local ok, owns = pcall(function()
			return Svc.Marketplace:UserOwnsGamePassAsync(plr.UserId, Founders.gamePassId(C))
		end)
		if ok and owns then
			local seatsRef = { left = vipSeatsLeft }
			if Founders.grant(p, plr, "gamepass", {
				seatsRef = seatsRef,
				grantScrolls = grantScrolls,
				toast = function(plr2, msg) net:FireClient(plr2, "toast", msg) end,
			}) then
				vipSeatsLeft = seatsRef.left or vipSeatsLeft
				markDirty(plr)
				snap(plr)
			end
			return
		end
	end
	if vipSeatsLeft <= 0 then
		net:FireClient(plr, "toast", "No seats left on this server")
		return
	end
	local price = C.vipPrice(Founders.creditsPrice(C, Packs), hasVipPass(plr))
	if (p.credits or 0) < price then
		net:FireClient(plr, "toast", "Need " .. price .. " credits for Founders Pack")
		return
	end
	p.credits -= price
	do
		local seatsRef = { left = vipSeatsLeft }
		Founders.grant(p, plr, "credits", {
			seatsRef = seatsRef,
			grantScrolls = grantScrolls,
			toast = function(plr2, msg) net:FireClient(plr2, "toast", msg) end,
		})
		vipSeatsLeft = seatsRef.left or vipSeatsLeft
	end
	markDirty(plr)
	snap(plr)
end

-- CART_MAX_* on Const

local function cartPrice(line)
	local kind, id = line.kind, tostring(line.id)
	-- Shop sells packs (and scrolls) only — never individual cards.
	if kind == "card" or kind == "cards" or kind == "pet" then
		return nil
	end
	if kind == "pack" then
		local unit = Packs.priceOf(id)
		if not unit then
			return nil
		end
		if line.bundle then
			return Packs.bundlePrice(id), Packs.BUNDLE_QTY
		end
		return unit, 1
	elseif kind == "scroll" then
		local item = Scrolls.itemById(id)
		if not item then
			return nil
		end
		if line.bundle then
			if not item.bundleQty then
				return nil
			end
			return item.bundlePrice or (item.price * item.bundleQty), item.bundleQty
		end
		return item.price, 1
	elseif kind == "lucky_block" then
		local LuckyBlocks = require(shared.MineLuckyBlocks)
		if not LuckyBlocks.def(id) then
			return nil
		end
		-- Bundle of 10 base lucky blocks.
		if line.bundle then
			local b = LuckyBlocks.BUNDLE_10
			if b and b.id == id then
				return b.credits, b.qty or 10
			end
			return nil
		end
		local unit = LuckyBlocks.shopPrice and LuckyBlocks.shopPrice(id)
		if not unit then
			return nil
		end
		return unit, 1
	elseif kind == "box" then
		local packs = line.packs
		if type(packs) ~= "table" or #packs < 1 or #packs > 10 then
			return nil
		end
		local sum = 0
		for _, pid in ipairs(packs) do
			local u = Packs.priceOf(tostring(pid))
			if not u then
				return nil
			end
			sum += u
		end
		return math.floor(sum * 0.88 + 0.5), 1
	end
	return nil
end

--[[
	THE STARDUST SHOP (MinePackConfig.dustRotation).

	A new shelf every six hours, the same on every server. Two limits per
	listing: a personal one (10-30, counted in the player's profile under
	p.dustShop, reset when the rotation changes) and a global one (0-10000,
	counted in a DataStore keyed by the rotation, so every server shares it).
	The global count is claimed with UpdateAsync BEFORE anything is paid or
	granted, so two servers cannot both sell the last pack.
]]
local DUST_SHOP = {
	key = nil,
	offers = {},
	sold = {}, -- [packId] = global sold, as last read (display only)
	fetchedAt = -math.huge,
}

local function utcDayKey()
	return Packs.dustRotationKey(os.time())
end

local function ensureDustShop()
	local key = utcDayKey()
	if DUST_SHOP.key ~= key then
		DUST_SHOP.key = key
		DUST_SHOP.offers = Packs.dustRotation(key)
		DUST_SHOP.sold = {}
		DUST_SHOP.fetchedAt = -math.huge
	end
	-- Refresh the worldwide counts at most once a minute, off the hot path.
	if os.clock() - DUST_SHOP.fetchedAt > 60 then
		DUST_SHOP.fetchedAt = os.clock()
		task.spawn(function()
			pcall(function()
				local ds = Svc.DSS:GetDataStore(C.storeName("DustShopGlobal_v1"))
				local saved = ds:GetAsync(key)
				if DUST_SHOP.key == key and type(saved) == "table" and type(saved.sold) == "table" then
					for id, n in pairs(saved.sold) do
						DUST_SHOP.sold[id] = math.max(DUST_SHOP.sold[id] or 0, tonumber(n) or 0)
					end
				end
			end)
		end)
	end
	return DUST_SHOP
end

function Packs.dustShopPayload(p)
	local shop = ensureDustShop()
	local mine = (type(p) == "table" and type(p.dustShop) == "table" and p.dustShop.key == shop.key)
		and p.dustShop.bought or {}
	local out = { key = shop.key, endsAt = Packs.dustRotationEnds(os.time()), offers = {} }
	for _, row in ipairs(shop.offers or {}) do
		table.insert(out.offers, {
			id = row.id,
			kind = row.kind or "pack",
			name = row.name,
			stars = row.stars,
			price = row.price,
			youMax = row.personalMax,
			youLeft = math.max(0, row.personalMax - (tonumber(mine[row.id]) or 0)),
			globalMax = row.globalMax,
			globalLeft = math.max(0, row.globalMax - (tonumber(shop.sold[row.id]) or 0)),
		})
	end
	return out
end

-- Claim `qty` of the worldwide stock. Returns true, or false and why.
local function takeDustStock(packId, qty)
	local shop = ensureDustShop()
	local row
	for _, r in ipairs(shop.offers or {}) do
		if r.id == packId then
			row = r
			break
		end
	end
	if not row then
		return false, "That pack isn't on the stardust shelf right now"
	end
	local key, granted = shop.key, false
	local ok = pcall(function()
		Svc.DSS:GetDataStore(C.storeName("DustShopGlobal_v1")):UpdateAsync(key, function(old)
			old = (type(old) == "table") and old or { sold = {} }
			old.sold = (type(old.sold) == "table") and old.sold or {}
			local cur = tonumber(old.sold[packId]) or 0
			if cur + qty > row.globalMax then
				granted = false
				shop.sold[packId] = cur
				return nil
			end
			old.sold[packId] = cur + qty
			shop.sold[packId] = cur + qty
			granted = true
			return old
		end)
	end)
	if not ok then
		return false, "The shop is busy -- try again in a moment"
	end
	if not granted then
		return false, "Sold out worldwide this rotation"
	end
	return true
end

local function buyCart(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(payload) ~= "table" or type(payload.lines) ~= "table" then
		return
	end

	-- 1. Price it. Nothing is granted until the whole cart is known to be valid
	--    and affordable, so a cart cannot half-complete.
	local subtotal, priced = 0, {}
	for i, line in ipairs(payload.lines) do
		if i > Const.CART_MAX_LINES then
			break
		end
		if type(line) == "table" then
			local qty = math.clamp(math.floor(tonumber(line.qty) or 1), 1, Const.CART_MAX_QTY)
			local unit, grant = cartPrice(line)
			if unit then
				subtotal += unit * qty
				table.insert(priced, {
					kind = line.kind, id = tostring(line.id),
					qty = qty, grant = grant * qty,
					packs = (line.kind == "box" and type(line.packs) == "table") and line.packs or nil,
				})
			end
		end
	end
	if #priced == 0 then
		net:FireClient(plr, "cartResult", { ok = false, reason = "Nothing in the cart" })
		return
	end

	local pay = Packs.creditPrice(subtotal, isVip(p))
	pay = C.vipPrice(pay, hasVipPass(plr))
	if (p.credits or 0) < pay then
		net:FireClient(plr, "cartResult", {
			ok = false,
			reason = "Need " .. pay .. " credits",
			subtotal = subtotal, pay = pay, held = p.credits or 0,
		})
		return
	end

	-- 2. Charge once, then grant.
	p.credits -= pay
	pcall(function()
		game:GetService("AnalyticsService"):LogEconomyEvent(plr, Enum.AnalyticsEconomyFlowType.Sink,
			"Credits", pay, p.credits, Enum.AnalyticsEconomyTransactionType.Shop.Name, "cart")
	end)
	--[[
		Built here rather than using the file's SET_IDS list, which is declared
		several hundred lines BELOW this function. Naming it here would read as
		a nil global -- no error at load, and then `#SET_IDS` throws on the
		first checkout anyone ever attempts.
	]]
	local setIds = {}
	for id in pairs(Cards.SETS or {}) do
		table.insert(setIds, id)
	end
	table.sort(setIds)
	local granted = {}
	for _, line in ipairs(priced) do
		if line.kind == "pack" then
			local def = Packs.PACK_BY_ID[line.id]
			p.packs = p.packs or {}
			for _ = 1, line.grant do
				-- A random set each time, so a bundle spreads across the
				-- collection instead of stacking ten of one set nobody needs.
				table.insert(p.packs, {
					packId = line.id,
					packName = (def and def.name) or line.id,
					setId = (#setIds > 0) and setIds[Random.new():NextInteger(1, #setIds)] or "dragons_dawn",
				})
			end
			table.insert(granted, { kind = "pack", id = line.id,
				name = (def and def.name) or line.id, qty = line.grant })
		elseif line.kind == "scroll" then
			local item = Scrolls.itemById(line.id)
			if line.id == "runesmith" and item and item.grants then
				for _ = 1, line.qty do
					for k, v in pairs(item.grants) do
						grantScrolls(p, k, v)
					end
				end
			else
				grantScrolls(p, line.id, line.grant)
			end
			table.insert(granted, { kind = "scroll", id = line.id,
				name = (item and item.name) or line.id, qty = line.grant })
		elseif line.kind == "lucky_block" then
			local LuckyBlocks = require(shared.MineLuckyBlocks)
			local def = LuckyBlocks.def(line.id)
			if def and LuckyBlocks.grant then
				LuckyBlocks.grant(p, line.id, "F", line.grant)
				table.insert(granted, {
					kind = "lucky_block",
					id = line.id,
					name = def.name or line.id,
					qty = line.grant,
				})
			end
		elseif line.kind == "box" then
			local setIds = {}
			for sid in pairs(Cards.SETS or {}) do
				table.insert(setIds, sid)
			end
			table.sort(setIds)
			p.packs = p.packs or {}
			local n = 0
			for _, pid in ipairs(line.packs or {}) do
				pid = tostring(pid)
				local def = Packs.PACK_BY_ID[pid]
				if def and Packs.priceOf(pid) then
					table.insert(p.packs, {
						packId = pid,
						packName = def.name or pid,
						setId = (#setIds > 0) and setIds[Random.new():NextInteger(1, #setIds)] or "dragons_dawn",
					})
					n += 1
				end
			end
			table.insert(granted, { kind = "box", id = "custom", name = "Custom Box", qty = n })
		end
	end

	net:FireClient(plr, "cartResult", {
		ok = true,
		subtotal = subtotal,
		pay = pay,
		saved = subtotal - pay,
		credits = p.credits,
		items = granted,
	})
	markDirty(plr)
	snap(plr)
end

--[[
	Battle Pass signature tools (Lunar / Eclipse / Lunar Eclipse).
	Stored like chest forever-tools so temper + equip paths stay shared.
]]
local function grantPassSignatureTool(p, toolId, plr)
	local def = Tools.passTool(toolId) or Tools.chestTool(toolId)
	if not def then
		return false
	end
	reconcileChestTools(p)
	for _, row in ipairs(p.chestTools or {}) do
		local rid = (type(row) == "table") and row.id or row
		if rid == toolId then
			return false
		end
	end
	local rng = Random.new()
	local layer = 0
	for _, d in pairs(p.deepest or {}) do
		layer = math.max(layer, tonumber(d) or 0)
	end
	if layer < 1 then
		layer = 1
	end
	local shiny, shadow, nightmare = Tools.rollFinish(rng, layer)
	-- The pass tool brings its temperament SLOTS; filling them costs tokens
	-- like anything else.
	table.insert(p.chestTools, {
		id = def.id,
		name = def.name,
		family = def.family,
		shadow = shadow or nil,
		nightmare = nightmare or nil,
		temperRolls = 0,
		temperSlots = def.temperSlots or 1,
		shiny = shiny or nil,
	})
	if plr then
		local label = ((nightmare and "Nightmare ") or (shadow and "Shadow ") or (shiny and "Shiny ") or "") .. def.name
		net:FireClient(plr, "foundTool", {
			name = label,
			shiny = shiny and true or false,
			shadow = shadow and true or false,
			nightmare = nightmare and true or false,
			kind = "tool",
			baseName = def.modelName or def.name,
			family = def.family,
			power = def.power,
			blurb = def.blurb or "You found some crazy shit",
		})
	end
	return true
end

local function openLuckyBlock(plr, entry)
	local p = profiles[plr.UserId]
	if not p or type(entry) ~= "table" then
		return
	end
	local LuckyBlocks = require(shared.MineLuckyBlocks)
	local Grades = require(shared.MineToolGrades)
	local blockId = entry.blockId or entry.packId
	if not LuckyBlocks.def(blockId) then
		net:FireClient(plr, "toast", "Unknown lucky block")
		return
	end
	local rng = Random.new()
	local finalGrade, info = Grades.rollClash(entry.startGrade or "F", rng, LuckyBlocks.UPGRADE_P)
	local loot = LuckyBlocks.rollLoot(blockId, finalGrade, rng)
	-- Grant loot
	if loot.packId then
		local def
		for _, row in ipairs(Packs.PACKS or {}) do
			if row.id == loot.packId then def = row break end
		end
		-- Also resolve zone packs if present
		pcall(function()
			local ZonePacks = require(shared.MineZonePacks)
			def = def or ZonePacks.get(loot.packId)
		end)
		p.packs = p.packs or {}
		local packQty = math.max(1, math.floor(tonumber(loot.packQty) or 1))
		for _ = 1, packQty do
			table.insert(p.packs, {
				packId = loot.packId,
				packName = (def and def.name) or loot.packId,
				setId = "dragons_dawn",
			})
		end
	end
	if loot.gems then p.gems = (p.gems or 0) + loot.gems end
	if loot.dust then p.dust = (p.dust or 0) + loot.dust end
	if loot.temperTokens then p.temperTokens = (p.temperTokens or 0) + loot.temperTokens end
	if type(loot.scrolls) == "table" then
		for id, qty in pairs(loot.scrolls) do grantScrolls(p, id, qty) end
	end
	if loot.potionId then
		pcall(function()
			local Potions = require(shared:WaitForChild("MinePotions"))
			if Potions.grant(p, loot.potionId, loot.potionQty or 1) then
				local def = Potions.def(loot.potionId)
				net:FireClient(plr, "toast", "Potion: " .. ((def and def.name) or loot.potionId))
			end
		end)
	end
	if loot.toolId and loot.toolFamily then
		p.tools = p.tools or {}
		local cur = p.tools[loot.toolFamily] or 0
		local ToolsMod = Tools
		local shop = ToolsMod.tool(loot.toolFamily, loot.toolId)
		if shop and shop.tier and shop.tier > cur then
			p.tools[loot.toolFamily] = shop.tier
		end
	end
	--[[
		A PET OUT OF A LUCKY BLOCK.

		Minted through the same path the group wheel used, so a pet won here is
		indistinguishable from one won anywhere else -- same serial, same roster
		lookup, same card shape. rollLoot only ever sets petTier at Legendary or
		better (MineLuckyBlocks), so there is no floor to enforce here.
	]]
	if loot.petTier and mint then
		pcall(function()
			local Wheel = require(shared:WaitForChild("MineGroupWheel"))
			local petName = Wheel.rollPetOfTier and Wheel.rollPetOfTier(loot.petTier, rng)
			if not petName then
				return
			end
			local roster = PetRoster and PetRoster.BY_NAME and PetRoster.BY_NAME[petName]
			local c = mint({
				setId = "lucky_block",
				index = 1,
				cardKey = "lucky_block:" .. petName,
				name = petName,
				rarityId = (roster and roster.tier) or loot.petTier,
				typeId = "Crystal",
				animal = roster and roster.animal or nil,
				roleName = "Lucky Block",
				kind = "Unit",
				setName = "Lucky Block",
			}, plr.UserId, true)
			p.cards = p.cards or {}
			table.insert(p.cards, c)
			-- so the reveal card can name it rather than saying "Legendary Pet"
			loot.petName = petName
		end)
	end
	markDirty(plr)
	snap(plr)
	net:FireClient(plr, "luckyBlockOpened", {
		blockId = blockId,
		startGrade = entry.startGrade or "F",
		uid = entry.uid,
		key = LuckyBlocks.stackKey(entry),
		bought = entry.bought,
		info = info,
		loot = loot,
		lootText = LuckyBlocks.describeLoot(loot),
	})
	-- No toast: what was inside is the end of the tap-through reveal on the
	-- client, and a toast would give it away before the first tap.
end

--[[
	Lucky blocks from their own screen. The inventory groups them by stack key
	(block, grade, luck, levels bought), so the client names a stack and this
	finds one of exactly that kind. `uid` names ONE block and is believed over
	everything else -- it is the only handle that survives the bag shifting,
	which matters most for grade-ups, where the gems are spent on a particular
	block rather than on a stack. The index is only a hint, checked against the
	key.
]]
function Verbs.luckyFind(p, index, key, uid)
	local LuckyBlocks = require(shared.MineLuckyBlocks)
	local function isBlock(e)
		return type(e) == "table" and (e.kind == "lucky_block" or (e.blockId ~= nil and LuckyBlocks.def(e.blockId) ~= nil))
	end
	local list = p.packs or {}
	if type(uid) == "string" then
		for j, e in ipairs(list) do
			if isBlock(e) and e.uid == uid then
				return j, e
			end
		end
	end
	local i = tonumber(index)
	local hit = i and list[i]
	if isBlock(hit) and LuckyBlocks.stackKey(hit) == key then
		return i, hit
	end
	for j, e in ipairs(list) do
		if isBlock(e) and LuckyBlocks.stackKey(e) == key then
			return j, e
		end
	end
end

-- Open `count` of one stack, back to back. The client plays each roll.
function Verbs.openLucky(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(payload) ~= "table" or type(payload.key) ~= "string" then
		return
	end
	local want = math.clamp(math.floor(tonumber(payload.count) or 1), 1, Const.OPEN_RUN_MAX)
	local hint, lead, opened = payload.index, payload.uid, 0
	while opened < want do
		local i, entry = Verbs.luckyFind(p, hint, payload.key, lead)
		if not i then
			break
		end
		table.remove(p.packs, i)
		openLuckyBlock(plr, entry)
		opened += 1
		hint, lead = nil, nil
	end
	if opened == 0 then
		net:FireClient(plr, "luckyGone", { key = payload.key })
	end
end

--[[
	Paying gems to raise one lucky block a grade before it is opened. The first
	level bought on a block costs MineLuckyBlocks.GRADE_UP_BASE whatever grade
	it starts at, and each level after that on the same block costs
	GRADE_UP_GROWTH times the last. The price is decided here; the client only
	shows it.
]]
function Verbs.luckyGradeUp(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(payload) ~= "table" or type(payload.key) ~= "string" then
		return
	end
	local LuckyBlocks = require(shared.MineLuckyBlocks)
	local function refuse(reason)
		net:FireClient(plr, "luckyGraded", { ok = false, key = payload.key, reason = reason })
	end
	local i, entry = Verbs.luckyFind(p, payload.index, payload.key, payload.uid)
	if not i then
		return refuse("That block is gone")
	end
	local nextGrade = LuckyBlocks.nextGrade(entry.startGrade or "F")
	if not nextGrade then
		return refuse("It is already the top grade")
	end
	local price = LuckyBlocks.gradeUpPrice(entry)
	if (p.gems or 0) < price then
		return refuse("You need " .. price .. " gems")
	end
	p.gems -= price
	entry.startGrade = nextGrade
	entry.bought = (tonumber(entry.bought) or 0) + 1
	markDirty(plr)
	snap(plr)
	net:FireClient(plr, "luckyGraded", {
		ok = true,
		index = i,
		uid = entry.uid,
		key = LuckyBlocks.stackKey(entry),
		oldKey = payload.key,
		grade = nextGrade,
		bought = entry.bought,
		price = price,
		gems = p.gems,
	})
end

--[[
	SELLING A TOOL.

	Four places a tool can come from and they do not sell the same way, so the
	client says which drawer it is reaching into rather than this guessing from
	an id that several drawers could answer to.

	  ladder   a coin-shop rung          -> coins, top rung only
	  shop     a depth-desk rung         -> coins
	  forever  chest / pass / event      -> stardust + temper tokens

	Two refusals worth keeping: a tool with a rune in it goes back with
	"unsocket it first" rather than quietly eating the rune, and the last rung
	of a family cannot go, because a player with no pickaxe at all has no way
	back into the game.

	The client holds a button for three seconds before this is called. That is a
	guard against a misclick, not a permission -- everything is re-checked here.
]]
function Verbs.sellTool(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(payload) ~= "table" then
		return
	end
	local function refuse(why)
		net:FireClient(plr, "toast", why)
	end
	local function payDust(dust, tokens, name)
		local mode = tostring(payload.pay or payload.currency or "")
		if mode == "dust" then
			tokens = 0
		elseif mode == "tokens" then
			dust = 0
		elseif mode ~= "both" and (dust > 0 and tokens > 0) then
			-- Forever tools: player must pick stardust OR tokens (full value either way).
			return refuse("Pick stardust or tokens")
		end
		if dust > 0 then
			p.dust = (p.dust or 0) + C.vipPayout(dust, hasVipPass(plr))
		end
		if tokens > 0 then
			p.temperTokens = (p.temperTokens or 0) + tokens
		end
		local bits = {}
		if dust > 0 then table.insert(bits, tostring(dust) .. " stardust") end
		if tokens > 0 then
			table.insert(bits, tokens .. " temper token" .. (tokens == 1 and "" or "s"))
		end
		net:FireClient(plr, "toast", "Salvaged " .. tostring(name) .. " for " .. table.concat(bits, " + "))
	end

	local source = tostring(payload.source or "")

	if source == "ladder" then
		local family = tostring(payload.family or "pickaxe")
		local list = Tools.TOOLS[family]
		if not list then
			return refuse("No such tool family")
		end
		equippedTool(p)
		local owned = tonumber(p.tools[family]) or 0
		if owned <= 1 then
			return refuse("That is the last " .. family .. " you own")
		end
		local def = list[owned]
		local coins = Tools.ladderSellValue(def)
		if coins <= 0 then
			return refuse("That one is not worth anything")
		end
		p.tools[family] = owned - 1
		p.toolTier = p.toolTier or {}
		if (tonumber(p.toolTier[family]) or owned) > p.tools[family] then
			p.toolTier[family] = p.tools[family]
		end
		p.coins = (p.coins or 0) + coins
		net:FireClient(plr, "toast", "Sold " .. tostring(def.name) .. " for " .. tostring(coins) .. " coins")
		givePickaxe(plr)
		markDirty(plr)
		return snap(plr)
	end

	if source == "shop" then
		local id = tostring(payload.id or "")
		p.ownedShopTools = p.ownedShopTools or {}
		if not p.ownedShopTools[id] then
			return refuse("You do not own that")
		end
		local okL, Ladders = pcall(function()
			return require(shared:WaitForChild("MineShopLadders"))
		end)
		local row = okL and Ladders and Ladders.byId(id)
		if not row then
			return refuse("You do not own that")
		end
		local coins = Tools.ladderSellValue(row)
		p.ownedShopTools[id] = nil
		if p.shopToolId == id then
			p.shopToolId = nil
		end
		p.coins = (p.coins or 0) + coins
		net:FireClient(plr, "toast", "Sold " .. tostring(row.name) .. " for " .. tostring(coins) .. " coins")
		givePickaxe(plr)
		markDirty(plr)
		return snap(plr)
	end

	if source == "forever" then
		local id = tostring(payload.id or "")
		reconcileChestTools(p)
		local at, row
		for i, r in ipairs(p.chestTools or {}) do
			if r.id == id then
				at, row = i, r
				break
			end
		end
		if not row then
			return refuse("You do not own that")
		end
		if row.runeId then
			return refuse("Unsocket its rune first")
		end
		local def = Tools.chestTool(id)
		local dust, tokens = Tools.foreverSellValue(def, row)
		table.remove(p.chestTools, at)
		if p.chestTool == id then
			p.chestTool = nil
		end
		payDust(dust, tokens, (def and def.name) or id)
		givePickaxe(plr)
		markDirty(plr)
		return snap(plr)
	end


	refuse("Nothing to sell")
end

function Verbs.fusePassTools(plr)
	local p = profiles[plr.UserId]
	if not p then return end
	reconcileChestTools(p)
	local hasLunar, hasEclipse, lunarRow, eclipseRow = false, false, nil, nil
	for _, row in ipairs(p.chestTools or {}) do
		local rid = (type(row) == "table") and row.id or row
		if rid == "lunar_pick" then hasLunar, lunarRow = true, row end
		if rid == "bp_eclipse" then hasEclipse, eclipseRow = true, row end
	end
	if not (hasLunar and hasEclipse) then
		net:FireClient(plr, "toast", "Need Lunar Pickaxe and Eclipse to fuse")
		return
	end
	-- Consume parents
	local kept = {}
	for _, row in ipairs(p.chestTools or {}) do
		local rid = (type(row) == "table") and row.id or row
		if rid ~= "lunar_pick" and rid ~= "bp_eclipse" then
			table.insert(kept, row)
		end
	end
	p.chestTools = kept
	if p.chestTool == "lunar_pick" or p.chestTool == "bp_eclipse" then
		p.chestTool = nil
	end
	grantPassSignatureTool(p, "lunar_eclipse", plr)
	p.chestTool = "lunar_eclipse"
	markDirty(plr)
	net:FireClient(plr, "toast", "Fused Lunar Eclipse — 100% Omni Blast")
	snap(plr)
	walk(plr)
end

--[[
	Claim one tier of one track.

	Everything is re-derived from the profile: the tier comes from stored XP,
	not from anything the client says, and the reward comes from the same
	PASS_TRACK row the UI read. The client only names which row and which
	track it wants, so the worst a forged payload can do is ask for a tier it
	has not reached, or one it already took.
]]
function Verbs.claimPass(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	p.pass = Scrolls.reconcilePass(p.pass or Scrolls.emptyPass())
	local pass = p.pass
	local tier = math.floor(tonumber(payload and payload.tier) or 0)
	local premium = (payload and payload.track) == "premium"
	local row = (tier >= 1 and tier <= Scrolls.PASS_TIERS) and Scrolls.PASS_TRACK[tier] or nil
	if not row then
		net:FireClient(plr, "toast", "No such pass tier")
		return
	end
	if Scrolls.passTier(pass.xp or 0) < tier then
		net:FireClient(plr, "toast", "Reach tier " .. tier .. " first")
		return
	end
	if premium and not pass.owned then
		net:FireClient(plr, "toast", "That reward is on the paid track")
		return
	end
	local ledger = premium and pass.prem or pass.free
	local trackName = premium and "premium" or "free"
	if ledger[tier] or ledger[tostring(tier)] then
		net:FireClient(plr, "claimPassResult", { tier = tier, track = trackName, ok = true, already = true })
		net:FireClient(plr, "toast", "Already claimed")
		snap(plr)
		return
	end
	local reward = premium and row.premium or row.free
	if type(reward) ~= "table" then
		net:FireClient(plr, "toast", "Nothing on that track")
		return
	end

	local lockKey = (premium and "premium_" or "free_") .. tostring(tier)
	claimPassLocks[plr.UserId] = claimPassLocks[plr.UserId] or {}
	if claimPassLocks[plr.UserId][lockKey] then
		net:FireClient(plr, "claimPassResult", { tier = tier, track = trackName, ok = true, already = true })
		net:FireClient(plr, "toast", "Already claiming")
		return
	end
	claimPassLocks[plr.UserId][lockKey] = true

	local function countLucky(packs, blockId)
		local n = 0
		for _, e in ipairs(packs or {}) do
			if type(e) == "table" and e.kind == "lucky_block" and e.blockId == blockId then
				n += 1
			end
		end
		return n
	end

	local function applyRewardTo(profile, livePlr)
		if reward.credits then
			profile.credits = (profile.credits or 0) + reward.credits
		end
		if reward.gems then
			profile.gems = (profile.gems or 0) + reward.gems
		end
		if reward.dust then
			profile.dust = (profile.dust or 0) + reward.dust
		end
		if type(reward.scrolls) == "table" then
			for id, qty in pairs(reward.scrolls) do
				grantScrolls(profile, id, qty)
			end
		end
		if type(reward.luckyBlocks) == "table" then
			local okLB, LuckyBlocks = pcall(function()
				return require(shared.MineLuckyBlocks)
			end)
			if okLB and LuckyBlocks and LuckyBlocks.grant then
				for _, b in ipairs(reward.luckyBlocks) do
					if b and b.id then
						LuckyBlocks.grant(profile, b.id, b.startGrade or "F", b.qty or 1)
					end
				end
			end
		end
		if reward.toolId then
			grantPassSignatureTool(profile, reward.toolId, livePlr)
		end
	end

	local function markLedger(passTbl)
		local led = premium and passTbl.prem or passTbl.free
		led = led or {}
		if premium then passTbl.prem = led else passTbl.free = led end
		led[tier] = true
		led[tostring(tier)] = nil
	end

	local hasLucky = type(reward.luckyBlocks) == "table" and #reward.luckyBlocks > 0
	local okClaim = true
	local denyReason = nil
	-- Paint live claimed NOW so a snapshot in flight cannot resurrect CLAIM.
	markLedger(pass)

	if hasLucky and not p._ephemeral then
		-- Snapshot counts before the datastore write.
		local before = {}
		local wantQty = {}
		for _, b in ipairs(reward.luckyBlocks) do
			if b and b.id then
				before[b.id] = countLucky(p.packs, b.id)
				wantQty[b.id] = (wantQty[b.id] or 0) + math.max(1, math.floor(tonumber(b.qty) or 1))
			end
		end

		local committedPass, committedPacks
		local outcome = "pending" -- granted | denied_* 
		local dsOk, dsErr = pcall(function()
			store:UpdateAsync("u_" .. plr.UserId, function(old)
				if type(old) ~= "table" then
					old = {}
				end
				old.pass = Scrolls.reconcilePass(old.pass or Scrolls.emptyPass())
				-- Live session may be ahead of the last save; take the higher bar.
				old.pass.xp = math.max(tonumber(old.pass.xp) or 0, tonumber(pass.xp) or 0)
				if pass.owned then
					old.pass.owned = true
				end
				local storeLedger = premium and (old.pass.prem or {}) or (old.pass.free or {})
				if premium then old.pass.prem = storeLedger else old.pass.free = storeLedger end
				old.passClaims = old.passClaims or {}
				local claimToken = lockKey
				if storeLedger[tier] or storeLedger[tostring(tier)] or old.passClaims[claimToken] then
					if outcome ~= "granted" then
						outcome = "denied_claimed"
						denyReason = "Already claimed"
					end
					committedPass = old.pass
					committedPacks = old.packs
					return old
				end
				if Scrolls.passTier(old.pass.xp or 0) < tier then
					outcome = "denied_tier"
					denyReason = "Reach tier " .. tier .. " first"
					return old
				end
				if premium and not old.pass.owned then
					outcome = "denied_premium"
					denyReason = "That reward is on the paid track"
					return old
				end
				-- Same callback: mark CLAIMED and grant the block(s).
				old.passClaims[claimToken] = true
				markLedger(old.pass)
				old.packs = old.packs or {}
				applyRewardTo(old, plr)
				committedPass = old.pass
				committedPacks = old.packs
				outcome = "granted"
				denyReason = nil
				return old
			end)
		end)
		if not dsOk then
			okClaim = false
			local led = premium and pass.prem or pass.free
			if led then led[tier] = nil led[tostring(tier)] = nil end
			warn("[Mine] claimPass UpdateAsync failed: ", dsErr)
			net:FireClient(plr, "toast", "Claim failed, try again")
		elseif outcome ~= "granted" then
			okClaim = false
			if outcome == "denied_claimed" then
				markLedger(pass)
			else
				local led = premium and pass.prem or pass.free
				if led then led[tier] = nil led[tostring(tier)] = nil end
			end
			net:FireClient(plr, "toast", denyReason or "Already claimed")
		else
			-- Live session takes the committed pass + packs authority for these blocks.
			if committedPass then
				p.pass = committedPass
			end
			-- Apply non-pack currency/tools onto live if the store copy was stale.
			-- Packs: rebuild lucky-block counts from the committed snapshot.
			if type(committedPacks) == "table" then
				-- Verify counts vs previous snapshot; trim extras; flag zeros.
				for blockId, prev in pairs(before) do
					local after = countLucky(committedPacks, blockId)
					local want = prev + (wantQty[blockId] or 1)
					if after <= prev then
						warn(string.format(
							"[Mine] claimPass lucky block MISSING user=%d tier=%d track=%s block=%s before=%d after=%d (should have granted)",
							plr.UserId, tier, premium and "premium" or "free", tostring(blockId), prev, after))
					elseif after > want then
						-- Remove all but previous+qty.
						local keep = want
						local seen = 0
						local trimmed = {}
						for _, e in ipairs(committedPacks) do
							if type(e) == "table" and e.kind == "lucky_block" and e.blockId == blockId then
								seen += 1
								if seen <= keep then
									table.insert(trimmed, e)
								end
							else
								table.insert(trimmed, e)
							end
						end
						committedPacks = trimmed
						warn(string.format(
							"[Mine] claimPass lucky block TRIMMED user=%d block=%s after=%d keep=%d",
							plr.UserId, tostring(blockId), after, keep))
						-- Write the trim back so the store matches.
						pcall(function()
							store:UpdateAsync("u_" .. plr.UserId, function(old)
								if type(old) ~= "table" then return old end
								old.packs = committedPacks
								return old
							end)
						end)
					end
				end
				-- Merge: keep live non-lucky packs, replace lucky counts for claimed ids from committed.
				local livePacks = {}
				for _, e in ipairs(p.packs or {}) do
					if not (type(e) == "table" and e.kind == "lucky_block" and before[e.blockId] ~= nil) then
						table.insert(livePacks, e)
					end
				end
				for _, e in ipairs(committedPacks) do
					if type(e) == "table" and e.kind == "lucky_block" and before[e.blockId] ~= nil then
						table.insert(livePacks, e)
					end
				end
				p.packs = livePacks
			end
			-- Currency / scrolls / tools from this claim onto live (ledger already on p.pass).
			if reward.credits then p.credits = (p.credits or 0) + reward.credits end
			if reward.gems then p.gems = (p.gems or 0) + reward.gems end
			if reward.dust then p.dust = (p.dust or 0) + reward.dust end
			if type(reward.scrolls) == "table" then
				for id, qty in pairs(reward.scrolls) do
					grantScrolls(p, id, qty)
				end
			end
			if reward.toolId then
				grantPassSignatureTool(p, reward.toolId, plr)
			end
		end
	else
		-- No lucky blocks: mark + grant in memory (still under the in-flight lock).
		markLedger(pass)
		applyRewardTo(p, plr)
	end

	claimPassLocks[plr.UserId][lockKey] = nil
	if not okClaim then
		net:FireClient(plr, "claimPassResult", {
			tier = tier, track = trackName, ok = (denyReason == "Already claimed"), already = true,
			reason = denyReason,
		})
		return
	end
	markDirty(plr)
	--[[
		Persist the claim NOW, not on the 45-second autosave.

		markDirty only queues a client snapshot -- it does not save. So a claim
		whose reward has no lucky block (the `else` branch above, which grants in
		memory) survived only until the next autosave. Relog inside that window
		and the ledger was gone while the reward had already been handed over:
		the tier reads unclaimed again and pays a second time.

		This is the same bug the daily reward already hit and fixed the same way
		-- see the save(plr) on the daily path and its comment about the popup
		returning every login as Day 1.

		Claims with lucky blocks were already safe: that path commits the ledger
		inside the UpdateAsync callback. This makes both paths durable rather
		than leaving the cheaper one to chance.
	]]
	save(plr)
	net:FireClient(plr, "claimPassResult", { tier = tier, track = trackName, ok = true })
	net:FireClient(plr, "toast", "Claimed: " .. Scrolls.describeReward(reward))
	snap(plr)
end

--[[
	Claim today's reward.

	Everything is decided here from the stored day index -- the client sends no
	payload at all, so there is nothing to forge. Claiming twice in a day is a
	no-op, and the streak advances only when the last claim was literally
	yesterday.
]]
local SET_IDS = {}
local grantReward -- forward; defined once SET_IDS is filled
for id in pairs(Cards.SETS or {}) do
	table.insert(SET_IDS, id)
end
table.sort(SET_IDS)

--[[
	Pay out one reward table: { coins, gems, credits, pack, packQty }.

	`gemsOverride` exists because the daily scales its gems by zone and the
	quest ladder does not -- the caller resolves the number, this hands it over.
]]
grantReward = function(plr, p, reward, gemsOverride)
	if type(reward) ~= "table" then
		return
	end
	if reward.coins then
		p.coins = (p.coins or 0) + reward.coins
	end
	if reward.dust then
		p.dust = (p.dust or 0) + reward.dust
	end
	if reward.potion then
		pcall(function()
			require(shared:WaitForChild("MinePotions")).grant(p, reward.potion, reward.potionQty or 1)
		end)
	end
	if type(reward.luckyBlocks) == "table" then
		for _, lb in ipairs(reward.luckyBlocks) do
			if lb and lb.id then
				pcall(LuckyBlocks.grant, p, lb.id, lb.startGrade or "F", lb.qty or 1)
			end
		end
	end
	-- A tool unlock pays its gems either way; the tool itself only when it
	-- is not already owned and nothing better on that shelf is.
	local unlocked = nil
	if reward.tool then
		unlocked = Verbs.grantShopTool(plr, p, reward.tool)
	end
	local gems = gemsOverride or reward.gems
	if gems and gems > 0 then
		p.gems = (p.gems or 0) + gems
	end
	if reward.credits then
		p.credits = (p.credits or 0) + reward.credits
	end
	if reward.pack and #SET_IDS > 0 then
		local rng = Random.new()
		local def
		for _, row in ipairs(Packs.PACKS or {}) do
			if row.id == reward.pack then
				def = row
				break
			end
		end
		p.packs = p.packs or {}
		for _ = 1, (reward.packQty or 1) do
			-- A random set each time, so a run of rewards spreads across the
			-- collection instead of stacking one set nobody needs.
			table.insert(p.packs, {
				packId = reward.pack,
				packName = (def and def.name) or reward.pack,
				setId = SET_IDS[rng:NextInteger(1, #SET_IDS)],
			})
		end
	end
	return unlocked
end

--[[
	Claim the next rung of the quest ladder.

	The client sends no payload: the server holds the index, measures the goal
	itself with questValue, and refuses if it is not met. Claiming advances the
	index by exactly one, so the ladder can never be skipped.
]]
function Verbs.claimQuest(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local index = math.max(1, math.floor(tonumber(p.quest) or 1))
	local q = Quests.at(index)
	if not q then
		net:FireClient(plr, "toast", "Every quest is done - nice.")
		snap(plr)
		return
	end
	-- The same measure questState shows. picktier is absolute -- a pickaxe
	-- bought before "Buy a better pickaxe" went live still counts -- so the
	-- tracker can no longer light CLAIM on a rung this then refuses.
	local have
	if q.stat == "picktier" then
		have = questValue(p, q.stat)
	else
		have = questValue(p, q.stat) - questBase(p, q.stat)
	end
	if have < q.goal then
		net:FireClient(plr, "toast", "Not finished yet: " .. q.text)
		snap(plr)
		return
	end
	local unlocked = grantReward(plr, p, q.reward)
	p.quest = index + 1
	-- The next quest's stat starts counting from here, not from zero.
	questRebase(p)
	introAdvance(plr, p, 7)
	awardPassXp(plr, p, (Scrolls.PASS_XP_AWARD and Scrolls.PASS_XP_AWARD.quest) or 50, "quest")
	markDirty(plr)
	local rewardText = Quests.describe(q.reward)
	if q.reward and q.reward.tool then
		rewardText = rewardText .. (unlocked and "  (it's yours!)"
			or "  (you already had it or better — gems paid anyway)")
	end
	net:FireClient(plr, "toast", "Quest done - " .. rewardText)
	net:FireClient(plr, "questDone", { text = q.text, reward = rewardText })
	snap(plr)
end

--[[
	Claim one of the day's three.

	The only thing the client names is which of the three slots; everything else
	-- whether it is finished, what it pays, whether it was already taken -- is
	re-read from the stored row. Claiming does not advance anything: these
	repeat, and the whole list is replaced when the day rolls.
]]
function Verbs.claimDailyQuest(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local index = math.floor(tonumber(payload and payload.index) or 0)
	local dq = ensureDailyQuests(p, plr.UserId)
	local row = dq.list[index]
	if not row then
		net:FireClient(plr, "toast", "No such daily quest")
		snap(plr)
		return
	end
	local def = Quests.dailyById(row.id)
	if not def then
		net:FireClient(plr, "toast", "That quest is no longer in the pool")
		snap(plr)
		return
	end
	if row.claimed then
		net:FireClient(plr, "toast", "Already claimed")
		snap(plr)
		return
	end
	if (tonumber(row.progress) or 0) < def.goal then
		net:FireClient(plr, "toast", "Not finished yet: " .. def.text)
		snap(plr)
		return
	end
	local gems = Quests.dailyGems(def, p.maxUnlockedZone or 1)
	p.gems = (p.gems or 0) + gems
	row.claimed = true
	introAdvance(plr, p, 7)
	awardPassXp(plr, p, (Scrolls.PASS_XP_AWARD and Scrolls.PASS_XP_AWARD.daily) or 75, "daily")
	markDirty(plr)
	net:FireClient(plr, "toast", "Daily quest done - " .. gems .. " Gems")
	snap(plr)
end

function Quests.svClaimMilestone(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local id = payload and payload.id
	local m = Quests.milestoneById(id)
	if not m then
		net:FireClient(plr, "toast", "No such milestone")
		return
	end
	p.milestones = p.milestones or {}
	if p.milestones[m.id] or p.milestones[tostring(m.id)] then
		net:FireClient(plr, "toast", "Already claimed")
		return
	end
	if questValue(p, m.stat) < m.goal then
		net:FireClient(plr, "toast", "Not finished yet: " .. m.text)
		return
	end
	grantReward(plr, p, m.reward)
	p.milestones[m.id] = true
	awardPassXp(plr, p, (Scrolls.PASS_XP_AWARD and Scrolls.PASS_XP_AWARD.milestone) or 60, "milestone")
	markDirty(plr)
	net:FireClient(plr, "toast", "Milestone - " .. Quests.describe(m.reward))
	snap(plr)
end

function Quests.svClaimContract(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local index = math.floor(tonumber(payload and payload.index) or 0)
	local cq = Quests.svEnsureContracts(p, plr.UserId)
	local row = cq.list[index]
	if not row then
		net:FireClient(plr, "toast", "No such contract")
		snap(plr)
		return
	end
	local def = Quests.contractById(row.id)
	if not def then
		net:FireClient(plr, "toast", "That contract left the board")
		snap(plr)
		return
	end
	if row.claimed then
		net:FireClient(plr, "toast", "Already claimed")
		snap(plr)
		return
	end
	if Quests.svContractProgress(p, row) < def.goal then
		net:FireClient(plr, "toast", "Not finished yet: " .. def.text)
		snap(plr)
		return
	end
	local gems = Quests.contractGems(def, p.maxUnlockedZone or 1)
	p.gems = (p.gems or 0) + gems
	row.claimed = true
	introAdvance(plr, p, 14)
	awardPassXp(plr, p, (Scrolls.PASS_XP_AWARD and Scrolls.PASS_XP_AWARD.contract) or 100, "contract")
	markDirty(plr)
	net:FireClient(plr, "toast", "Contract done - " .. gems .. " Gems")
	snap(plr)
end

function Verbs.claimDaily(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	p.daily = p.daily or { streak = 0, last = 0 }
	local today = utcDayIndex()
	local last = tonumber(p.daily.last) or 0
	if last == today then
		net:FireClient(plr, "toast", "Already claimed today - come back tomorrow")
		snap(plr)
		return
	end
	local streak = (last == today - 1) and ((tonumber(p.daily.streak) or 0) + 1) or 1
	local reward = Scrolls.dailyReward(streak)
	if type(reward) ~= "table" then
		return
	end
	local zone = p.maxUnlockedZone or 1
	grantReward(plr, p, reward, Scrolls.dailyGems(reward, zone, streak))
	p.daily.streak = streak
	p.daily.last = today
	introAdvance(plr, p, 19)
	-- Persist immediately: Studio Stop/Play often kills the session before the
	-- 45s autosave, which made the daily popup return every login as Day 1.
	save(plr)
	local dailyMsg = "Day " .. Scrolls.dailyDay(streak) .. ": " .. Scrolls.describeDaily(reward, zone, streak)
	net:FireClient(plr, "toast", dailyMsg)
	if reward.pack then
		local def = Packs.PACK_BY_ID[reward.pack]
		net:FireClient(plr, "purchaseFx", { kind = "pack", packId = reward.pack, count = reward.packQty or 1,
			name = (def and def.name) or reward.pack })
	end
	-- Day 4 of the login cycle: offer Like + Favorite for a surprise 2★+ pack.
	if Scrolls.dailyDay(streak) == 4 and tonumber(p.daily.surpriseAt) ~= today then
		net:FireClient(plr, "dailySurpriseOffer", {
			day = 4,
			blurb = "Like & Favorite the game for a surprise pack (2★+)",
		})
	end
	snap(plr)
end

local function surprisePackPool()
	local pool = {}
	for id, def in pairs(Packs.PACK_BY_ID or {}) do
		local stars = tonumber(Packs.packStars and Packs.packStars(id)) or tonumber(def and def.stars) or 0
		local kind = def and def.kind
		if stars >= 2 and (kind == nil or kind == "cards") then
			pool[#pool + 1] = id
		end
	end
	table.sort(pool)
	return pool
end

function Verbs.claimDailySurprise(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	p.daily = p.daily or { streak = 0, last = 0 }
	local today = utcDayIndex()
	if tonumber(p.daily.last) ~= today then
		net:FireClient(plr, "toast", "Claim today's daily first")
		return
	end
	if Scrolls.dailyDay(p.daily.streak) ~= 4 then
		net:FireClient(plr, "toast", "Surprise pack is a Day 4 bonus")
		return
	end
	if tonumber(p.daily.surpriseAt) == today then
		net:FireClient(plr, "toast", "Surprise already claimed")
		return
	end
	local pool = surprisePackPool()
	if #pool == 0 then
		net:FireClient(plr, "toast", "No surprise packs configured")
		return
	end
	local packId = pool[Random.new():NextInteger(1, #pool)]
	Verbs.grantPacks(plr, p, { { id = packId, qty = 1 } })
	p.daily.surpriseAt = today
	markDirty(plr)
	save(plr)
	local def = Packs.PACK_BY_ID[packId]
	local name = (def and def.name) or packId
	net:FireClient(plr, "toast", "Surprise! " .. name)
	net:FireClient(plr, "purchaseFx", { kind = "pack", packId = packId, count = 1, name = name })
	net:FireClient(plr, "dailySurpriseResult", { ok = true, packId = packId, name = name })
	snap(plr)
end

Verbs.DISCORD_LINK_GEMS = 5000
Verbs.discordLinkCooldown = {}

function Verbs.discordLink(plr, payload)
	if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
		return
	end
	local now = os.clock()
	if (discordLinkCooldown[plr.UserId] or 0) > now then
		net:FireClient(plr, "toast", "Slow down")
		return
	end
	discordLinkCooldown[plr.UserId] = now + 2

	local code = payload
	if type(payload) == "table" then
		code = payload.code or payload[1]
	end
	local ok, msg, discordId = DiscordLink.redeem(plr, code)
	local p = profiles[plr.UserId]
	if ok and p then
		if discordId then
			p.discordLinked = true
			p.discordId = tostring(discordId)
			if not p.discordBonusClaimed then
				p.discordBonusClaimed = true
				p.gems = (p.gems or 0) + Verbs.DISCORD_LINK_GEMS
				msg = tostring(msg or "Linked") .. " (+" .. tostring(Verbs.DISCORD_LINK_GEMS) .. " gems)"
			end
			save(plr)
		end
		markDirty(plr)
		snap(plr)
		net:FireClient(plr, "discordLinked", { ok = true, discordId = p.discordId })
	end
	net:FireClient(plr, "toast", tostring(msg or (ok and "Linked" or "Failed")))
end

function Verbs.armWhiteScroll(plr, payload)
	local p = profiles[plr.UserId]
	local rune = runeById(p, payload and payload.runeId)
	if not rune then
		net:FireClient(plr, "toast", "Unknown rune")
		return
	end
	if runeBusy(p, rune.id) then
		net:FireClient(plr, "toast", "Unequip rune before arming")
		return
	end
	p.scrolls = p.scrolls or Scrolls.emptyBag()
	if (p.scrolls.white or 0) < 1 then
		net:FireClient(plr, "toast", "Need a White Scroll")
		return
	end
	p.scrolls.white -= 1
	rune.whiteArmed = true
	net:FireClient(plr, "toast", "White Scroll armed on " .. Runes.describe(rune))
	snap(plr)
end

function Verbs.blackUnequipToolRune(plr, payload)
	local p = profiles[plr.UserId]
	local family = tostring(payload and payload.family or p.toolFamily or "pickaxe")
	local slot = tostring(payload and payload.slot or "main")
	p.scrolls = p.scrolls or Scrolls.emptyBag()
	if (p.scrolls.black or 0) < 1 then
		net:FireClient(plr, "toast", "Need a Black Scroll")
		return
	end
	local sock = familySocket(p, family)
	local runeId = (slot == "omni") and sock.omni or sock.main
	if not runeId then
		net:FireClient(plr, "toast", "No rune in that socket")
		return
	end
	local rune = runeById(p, runeId)
	p.scrolls.black -= 1
	if slot == "omni" then sock.omni = nil else sock.main = nil end
	if rune then
		-- No "100% next fuse" any more: every fuse is a flat 50% for everyone.
		net:FireClient(plr, "toast", "Black Scroll: " .. Runes.describe(rune) .. " returned to your runes")
	else
		net:FireClient(plr, "toast", "Socket cleared")
	end
	snap(plr)
end

function Verbs.applyOmniscroll(plr, payload)
	local p = profiles[plr.UserId]
	local family = tostring(payload and payload.family or p.toolFamily or "pickaxe")
	p.scrolls = p.scrolls or Scrolls.emptyBag()
	if (p.scrolls.omni or 0) < 1 then
		net:FireClient(plr, "toast", "Need an Omniscroll")
		return
	end
	local sock = familySocket(p, family)
	if sock.omniUnlocked then
		net:FireClient(plr, "toast", "That family already has omni unlocked")
		return
	end
	p.scrolls.omni -= 1
	sock.omniUnlocked = true
	net:FireClient(plr, "toast", "Omniscroll unlocked second socket on " .. family)
	snap(plr)
end

function Verbs.buyCreditPack(plr, payload)
	local packId = payload and (payload.packId or payload.id)
	local pack = Scrolls.packById(packId)
	if not pack then
		net:FireClient(plr, "toast", "Unknown credit pack")
		return
	end
	local pid = tonumber(pack.productId) or 0
	if pid > 0 and not Svc.Run:IsStudio() then
		net:FireClient(plr, "toast", "Buy credits with Robux from the shop prompt")
		return
	end
	local p = profiles[plr.UserId]
	p.credits = (p.credits or 0) + (pack.credits or 0)
	net:FireClient(plr, "toast", "+" .. pack.credits .. " credits")
	snap(plr)
end

function Verbs.scrubLobbyMineBlocks()
	-- Leftover dirt from an earlier generate. Only MineBlock / MineVoxel parts.
	local n = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name == "MineBlock" or Svc.Collection:HasTag(d, "MineVoxel")) then
			if C.blockOverlapsLobby and C.blockOverlapsLobby(d.Position, math.max(d.Size.X, d.Size.Y, d.Size.Z) * 0.5) then
				d:Destroy()
				n += 1
			end
		end
	end
	if n > 0 then
		print("[Mine] scrubbed", n, "mine blocks from lobby")
	end
	return n
end

WorldBuilder.build()
--[[
	NOTHING IN THE WORLD CASTS A SHADOW.

	Owner, 2026-10-06, microprofiler open on a 5070 Ti: GPU averages ~50 ms while
	moving and spikes to 80, against a 33 ms target. Measured live straight
	after: workspace holds 14,559 parts and 10,408 of them cast shadows, 9,610 of
	those inside MineWorld.

	Shadow maps are re-rendered as the camera moves, which is exactly the
	"when I move" shape of the spike, and the cost is per shadow-casting part.
	Underground there is no sun to cast them from, so for the great majority of
	them it bought nothing at all.

	Swept here rather than at each creation site because MineWorld is built by
	WorldBuilder, the plaza builders, the barrier builder and the voxel
	generator, and a rule spread over five files is a rule that will be missed by
	the sixth. New blocks set CastShadow = false as they spawn (see spawnVoxel);
	this catches everything that already exists.

	If a specific prop ever needs its shadow back, set CastShadow on it after
	this runs -- this is a floor, not a lock.
]]
--[[
	NO SHADOWS. AT ALL.

	Owner, 2026-10-06: "remove shadows peroid.. not point they dont do anything
	helpful". With the microprofiler open on a 5070 Ti the GPU was averaging
	~50 ms while moving and spiking to 80, against a 33 ms target.

	Measured live: 14,559 parts in the workspace, 10,408 of them casting
	shadows. Shadow maps re-render as the camera moves, which is exactly the
	"when I move" shape of the spike -- and the game is almost entirely
	underground, where there is no sun to cast them from. The cost bought
	nothing.

	GlobalShadows off is the whole thing in one property. The route I tried
	first -- clearing CastShadow per part -- took it from 10,408 to 5,149 and
	left 4,465 still casting, because the edge barriers and the depth plazas
	build after that point and the plazas build lazily as players reach them. A
	sweep can only catch what already exists, and a DescendantAdded watcher to
	catch the rest is a connection firing for every part in a voxel mine to do
	what one property does for free.

	spawnVoxel still sets CastShadow = false on blocks. That is now redundant
	while this line stands, and deliberately kept: if anyone ever turns
	GlobalShadows back on, the mine itself should not be what drags it down.
]]
pcall(function()
	game:GetService("Lighting").GlobalShadows = false
end)

--[[
	DEV SCAFFOLDING DOES NOT SHIP.

	Measured in a live session: twelve folders of editor scaffolding sit in the
	workspace holding 2,492 parts between them -- pet and ore showcases, tool
	model racks, icon pose references, a mass-review grid. They are built in the
	place file for authoring art and nothing in the game reads them, but every
	player loads, replicates and renders them.

	Removed on the server at startup, so it costs nothing in the place file and
	cannot be forgotten when a new showcase is added: the list is matched by
	name and by the leading-underscore convention this project already uses for
	scratch folders.

	This touches the RUNNING session only. The place file is untouched, so the
	folders are still there next time it is opened in Studio for authoring.
]]
-- IIFE, not a do-block: a do-block's locals share the MAIN CHUNK's 200
-- registers and this script has five left, so three names here stopped the
-- whole server compiling. tools/verify/compile.js caught it. A function body
-- gets its own budget.
;(function()
	--[[
		NAMED EXPLICITLY, and LaneBodies is deliberately NOT here.

		It was, on my guess that it was scaffolding. `LaneTips` sits beside it in
		the workspace and the pair reads as real geometry, not a showcase -- so
		the guess comes out. Everything in this list is a rack of art with a name
		that says so; anything ambiguous stays in the world.
	]]
	local SHOWCASE = {
		PetShowcase = true, OreShowcase = true, ToolModels_HQ = true,
		ToolKit_Showcase = true, IconPoseExamples = true,
		["Gem-N-Eye Preview"] = true,
	}
	local removed, parts = 0, 0
	for _, d in ipairs(workspace:GetChildren()) do
		-- `_Name` is this project's scratch convention; the rest are named above.
		if SHOWCASE[d.Name] or string.sub(d.Name, 1, 1) == "_" then
			for _, k in ipairs(d:GetDescendants()) do
				if k:IsA("BasePart") then
					parts += 1
				end
			end
			removed += 1
			d:Destroy()
		end
	end
	if removed > 0 then
		print(("[Mine] stripped %d dev showcase folders (%d parts) from the live world")
			:format(removed, parts))
	end
end)()
pcall(function()
	require(script.Parent:WaitForChild("MineEdgeBarriers")).buildAll()
end)
pcall(function()
	require(script.Parent:WaitForChild("MinePlayerCollision")).start()
end)
pcall(function()
	local world = workspace:FindFirstChild("MineWorld")
	local lobby = world and world:FindFirstChild("Lobby")
	-- Unparked 2026-09-23: the Group Wheel is back in the lobby. Its Pad is a
	-- real visible, collidable platform now, so the Spin prompt has something
	-- under it that players can see and stand on.
	-- Group wheel removed. Uncomment to bring it back:
	-- GroupWheelService.build(lobby)
end)
-- Before anything season-timed runs: the offers and the pass read
-- Launch.seasonNow(), and a load after they first ask would have them answer
-- from an unlaunched clock and then silently disagree with themselves.
pcall(Verbs._loadLaunch)
LeaderboardService.start(net)
pcall(function()
	Dig.Plazas.start()
end)
--[[
	The wandering traders, after the plazas: MineTraderNPC.spots() reads the
	DepthPlaza folders that Plazas.start just built, so starting first would find
	nowhere to stand and place nobody until the next rotation.

	The prompt only OPENS the shop. Buying goes through Verbs.buyTraderCase, which
	re-checks that a trader is really there -- a prompt a client can see is not
	authority to spend.
]]
pcall(function()
	Dig.TraderNPC.start(function(plr, placement)
		local p = profiles[plr.UserId]
		if not p then
			return
		end
		net:FireClient(plr, "traderShop", Dig.TraderNPC.offer(placement.zoneId, placement.seam))
	end)
end)
ensureZone(C.ZONES[1], C.LAYER_WINDOW or 8)
Verbs.scrubLobbyMineBlocks()
;(function()
	for _, zone in ipairs(C.ZONES) do
		syncPitWalls(zone)
	end
end)()

-- Stale lobbies built before EventClock existed still need the billboard.
-- IIFE so its locals do not burn main-chunk registers (Luau 200 cap).
;(function()
	local world = workspace:FindFirstChild("MineWorld")
	local lobby = world and world:FindFirstChild("Lobby")
	local door = lobby and lobby:FindFirstChild("Portal_bigbang")
	if door and not door:FindFirstChild("EventClock") then
		local plaque = door:FindFirstChild("Plaque")
		local cf = plaque and plaque.CFrame or (door:FindFirstChild("Keystone") and door.Keystone.CFrame)
		if cf then
			local clockHost = Instance.new("Part")
			clockHost.Name = "EventClock"
			clockHost.Anchored = true
			clockHost.CanCollide = false
			clockHost.CanQuery = false
			clockHost.CanTouch = false
			clockHost.Transparency = 1
			clockHost.Size = Vector3.new(14, 0.4, 0.4)
			clockHost.CFrame = cf * CFrame.new(0, 4, 0)
			clockHost.Parent = door
			clockHost:SetAttribute("EventClock", true)
			local bb = Instance.new("BillboardGui")
			bb.Name = "EventCountdown"
			bb.Size = UDim2.fromOffset(280, 72)
			bb.AlwaysOnTop = true
			bb.MaxDistance = 220
			bb.Parent = clockHost
			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.BackgroundTransparency = 1
			title.Size = UDim2.new(1, 0, 0, 22)
			title.Font = Enum.Font.GothamBlack
			title.TextSize = 16
			title.TextColor3 = Color3.fromRGB(180, 210, 255)
			title.Text = "EVENT ENDS IN"
			title.Parent = bb
			local timer = Instance.new("TextLabel")
			timer.Name = "Timer"
			timer.BackgroundTransparency = 1
			timer.Position = UDim2.fromOffset(0, 24)
			timer.Size = UDim2.new(1, 0, 0, 42)
			timer.Font = Enum.Font.GothamBlack
			timer.TextSize = 28
			timer.TextColor3 = Color3.fromRGB(255, 230, 140)
			timer.Text = "--:--:--"
			timer.Parent = bb
		end
	end
end)()

function Verbs.playersInShaft(zone)
	local origin = pitOrigin(zone)
	local half = (C.GRID * C.BLOCK) * 0.5 + 2
	local surfaceY = origin.Y + 2
	local out = {}
	for _, plr in ipairs(Svc.Players:GetPlayers()) do
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local pos = root.Position
			if math.abs(pos.X - origin.X) <= half and math.abs(pos.Z - origin.Z) <= half and pos.Y < surfaceY - 4 then
				table.insert(out, plr)
			end
		end
	end
	return out
end

function Verbs.resetMineZone(zone)
	local folder = workspace:FindFirstChild("MineWorld") and workspace.MineWorld.Pits:FindFirstChild("Vox_" .. zone.id)
	if folder then
		for _, ch in ipairs(folder:GetChildren()) do
			ch:Destroy()
		end
	end
	voxels[zone.id] = {}
	builtTo[zone.id] = 0
	-- A new salt, so the refreshed mine is not the one that was just cleared.
	mineResetState.seed = mineResetState.seed or {}
	mineResetState.seed[zone.id] = Random.new():NextInteger(1, 1073741823)
	-- The ore field reseeds with it, so a refreshed mine really is a new one.
	if C.setVeinSalt then
		C.setVeinSalt(zone.id, mineResetState.seed[zone.id])
	end
	ensureZone(zone, C.LAYER_WINDOW or 8)
	syncPitWalls(zone)
	for _, plr in ipairs(Verbs.playersInShaft(zone)) do
		tp(plr, surfaceCf(zone))
		net:FireClient(plr, "toast", "Mine refreshed")
	end
	local nextAt = os.clock() + (C.MINE_RESET_SEC or 1200)
	mineResetState.at[zone.id] = nextAt
	mineResetState.warned[zone.id] = {}
	for _, plr in ipairs(Svc.Players:GetPlayers()) do
		net:FireClient(plr, "mineReset", {
			zoneId = zone.id,
			nextAt = nextAt,
			resetSec = C.MINE_RESET_SEC or 1200,
			remaining = C.MINE_RESET_SEC or 1200,
		})
	end
end

--[[
	The mine reset, every MINE_RESET_SEC on the server's clock rather than from
	whenever this server happened to start. The HUD countdown, the resets and
	Event Horizon's black hole (MineAmbience plays it off the same clock) all
	land on the same beat. Dirt Meadow is remade, and so is Event Horizon while
	its event runs: the collapse IS its reset.
	No new top-level locals here: this script is at Luau's 200-local ceiling.
]]
mineResetState.at.meadow = os.clock() + ((C.MINE_RESET_SEC or 1200) - workspace:GetServerTimeNow() % (C.MINE_RESET_SEC or 1200))
mineResetState.warned.meadow = {}
task.spawn(function()
	local period = C.MINE_RESET_SEC or 1200
	local lastCycle = math.floor(workspace:GetServerTimeNow() / period)
	while true do
		task.wait(1)
		local now = workspace:GetServerTimeNow()
		local zone = C.zoneById("meadow") or C.ZONES[1]
		local left = period - (now % period)
		mineResetState.at[zone.id] = os.clock() + left
		local warned = mineResetState.warned[zone.id] or {}
		mineResetState.warned[zone.id] = warned
		if left <= 60 and not warned[60] then
			warned[60] = true
			for _, plr in ipairs(Svc.Players:GetPlayers()) do
				net:FireClient(plr, "toast", "Mine resets in 60s")
				net:FireClient(plr, "mineReset", { zoneId = zone.id, remaining = math.max(0, left), resetSec = period, warn = 60 })
			end
		end
		if left <= 10 and not warned[10] then
			warned[10] = true
			for _, plr in ipairs(Svc.Players:GetPlayers()) do
				net:FireClient(plr, "toast", "Mine resets in 10s")
				net:FireClient(plr, "mineReset", { zoneId = zone.id, remaining = math.max(0, left), resetSec = period, warn = 10 })
			end
		end
		local cycle = math.floor(now / period)
		if cycle ~= lastCycle then
			lastCycle = cycle
			Verbs.resetMineZone(zone)
			local eh = C.zoneById("bigbang")
			if eh and (not C.limitedActive or C.limitedActive()) then
				local ok, err = pcall(Verbs.resetMineZone, eh)
				if not ok then
					warn("[Mine] Event Horizon reset failed: " .. tostring(err))
				end
			end
			left = period - (workspace:GetServerTimeNow() % period)
		end
		if math.floor(left) % 5 == 0 then
			for _, plr in ipairs(Svc.Players:GetPlayers()) do
				net:FireClient(plr, "mineReset", {
					zoneId = zone.id,
					remaining = math.max(0, left),
					resetSec = period,
				})
			end
		end
	end
end)

function Verbs.rescueIfBelowShaft(plr)
	local p = profiles[plr.UserId]
	if not p then return end
	local zone = C.zoneById(p.zoneId) or C.ZONES[1]
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local built = builtTo[zone.id] or 0
	if built <= 0 then return end
	local origin = pitOrigin(zone)
	local half = C.GRID * C.BLOCK * 0.5 + 6
	local flat = Vector3.new(root.Position.X - origin.X, 0, root.Position.Z - origin.Z)
	if flat.Magnitude > half then return end
	local bottomY = origin.Y - built * C.BLOCK - C.BLOCK
	if root.Position.Y >= bottomY - 1 then return end
	tp(plr, surfaceCf(zone))
	net:FireClient(plr, "toast", "Back to the surface")
end

task.spawn(function()
	while true do
		task.wait(0.4)
		for _, plr in ipairs(Svc.Players:GetPlayers()) do
			pcall(Verbs.rescueIfBelowShaft, plr)
		end
	end
end)

-- Spawn.
--
-- The lobby CODE exists (lobbyCf, LOBBY_MIN/MAX, scrubLobbyMineBlocks) but the
-- lobby GEOMETRY does not, so lobbyCf() just returns a point next to camp --
-- and camp is 200 studs from the nearest block against a 26 stud reach. That
-- is the second time spawning somewhere with no rock in range has read as
-- "mining is broken".
--
-- So: use the lobby the moment it is actually built, and until then put the
-- player at their zone's stand where there is something to hit. No patch
-- needed later -- it switches over on its own.
function Verbs.lobbyIsBuilt()
	local mw = workspace:FindFirstChild("MineWorld")
	return (workspace:FindFirstChild("Lobby") or (mw and mw:FindFirstChild("Lobby"))) ~= nil
end

function Verbs.spawnAtLobby(plr)
	if Verbs.lobbyIsBuilt() then
		tp(plr, lobbyCf())
		return
	end
	local p = profiles[plr.UserId]
	local zone = C.zoneById((p and p.zoneId) or C.ZONES[1].id) or C.ZONES[1]
	ensureZone(zone, math.max(((p and p.deepest and p.deepest[zone.id]) or 0), p and Dig.Auth.depthPassOf(p, zone.id) or 0) + (C.LAYER_WINDOW or 8))
	local pits = workspace:FindFirstChild("MineWorld")
	pits = pits and pits:FindFirstChild("Pits")
	local stand = pits and pits:FindFirstChild("Stand_" .. zone.id)
	tp(plr, stand and stand.CFrame or lobbyCf())
end

function Verbs.returnSurface(plr)
	local p = profiles[plr.UserId]
	local zone = C.zoneById((p and p.zoneId) or C.ZONES[1].id) or C.ZONES[1]
	ensureZone(zone, math.max(((p and p.deepest and p.deepest[zone.id]) or 0), p and Dig.Auth.depthPassOf(p, zone.id) or 0) + (C.LAYER_WINDOW or 8))
	tp(plr, surfaceCf(zone))
	snap(plr)
end

-- Packs straight into the bag, each from a random set (like the cart).
--[[
	WHERE EACH BOOST COMES FROM, for the Boosts tab: every stat with the pets,
	runes, skills, gear and the rest that make it up, so "Blast +12%" can say
	which pet it came from. Mirrors boosts(p) source by source, each applied
	to an empty table on its own. On `Dig` because snap() sits above Verbs.
]]
--[[
	UPGRADES WAITING IN THE BAG.

	Gear you rolled and never put on, or a pet stronger than one you wear, is
	power you own and are not using -- and nothing said so. The HUD does now
	(a badge on Inventory and an EQUIP BEST button), and one tap puts it on.

	"Better" stays conservative on sockets (never swap a socketed piece), but
	compares universal-weighted powerScore so a same-grade luck hat beats a
	same-grade echo hat. Empty seats always fill. Pets rank by card power.

	Cached a couple of seconds per player on Dig -- never on the profile, which
	save() writes whole -- because snap runs ten times a second while digging.
]]
Dig.upgradeCache = {}
--[[
	THE ORE POUCH, server side. One way in, one way out.

	Every path that hands a player ore goes through Dig.addOre, so the pouch cap
	is enforced in one place instead of at each of the five call sites that grant
	ore today -- a cap checked in five places is a cap missed in one.

	It lives on Dig rather than as a top-level local because MineServer sits at
	196 of Luau's 200 top-level locals, and a helper is not worth one of the four
	that are left.
]]
function Dig.pouch()
	return require(shared:WaitForChild("MineOrePouch"))
end

function Dig.pouchTier(p)
	local Pouch = Dig.pouch()
	return math.clamp(math.floor(tonumber(p and p.orePouchTier) or 1), 1, Pouch.MAX_TIER)
end

--[[
	Put ore in the pouch, up to what it holds. Returns how much actually went in
	and how much was turned away.

	OVERFLOW IS REFUSED, NOT DROPPED SILENTLY. A full pouch that quietly eats ore
	is indistinguishable from a bug, and the one thing a player cannot do about a
	problem they cannot see is fix it. The caller tells them.
]]
function Dig.addOre(p, oreId, amount)
	if type(p) ~= "table" or type(oreId) ~= "string" or oreId == "" then
		return 0, 0
	end
	local want = math.max(0, math.floor(tonumber(amount) or 0))
	if want == 0 then
		return 0, 0
	end
	local Pouch = Dig.pouch()
	p.ores = p.ores or {}
	--[[
		DISCOVERY DOES NOT DEPEND ON HAVING ROOM. The ore is marked seen whether
		or not the pouch could take it: the player broke the block and saw what
		came out, and `oresSeen` drives the Forge's recipe list. Gating it on
		capacity would mean a full pouch quietly stops you discovering ore, and
		the recipe you needed stays invisible for a reason nothing tells you.

		Seen is grow-only and records the ORE, not the amount, so selling a pouch
		empty cannot un-discover anything either.
	]]
	p.oresSeen = p.oresSeen or {}
	p.oresSeen[tostring(oreId)] = true
	local room = Pouch.room(p.ores, Dig.pouchTier(p))
	local got = math.min(want, room)
	if got > 0 then
		p.ores[oreId] = (tonumber(p.ores[oreId]) or 0) + got
	end
	return got, want - got
end

--[[
	Tell the player their pouch is full, at most once every few seconds.

	Without the throttle this fires on every ore block broken, which at depth is
	several a second -- a toast stream that buries everything else on screen,
	about a condition one trip to sell fixes.
]]
function Dig.pouchFullToast(plr, p)
	if not (plr and p) then
		return
	end
	local now = os.clock()
	p._pouchFullAt = tonumber(p._pouchFullAt) or 0
	if now - p._pouchFullAt < 6 then
		return
	end
	p._pouchFullAt = now
	net:FireClient(plr, "toast", "Ore pouch is FULL -- sell some, or upgrade it with gems")
end

Dig.GEAR_GRADE = { F = 1, D = 2, C = 3, B = 4, A = 5, S = 6, SS = 7, SSS = 8 }
function Dig.gearScore(g)
	-- Prefer MineGear.powerScore (universal-weighted). Fall back to grade+pct.
	if Gear.powerScore then
		return Gear.powerScore(g)
	end
	return (Dig.GEAR_GRADE[tostring(g and g.rarity or "")] or 0) * 1000
		+ (tonumber(g and g.pct) or 0) * 100 + (tonumber(g and g.slotCount) or 0)
end
function Dig.planUpgrades(p)
	local plan = { gear = {}, gearCount = 0, pets = nil, petCount = 0 }
	local worn = p.equippedGear or {}
	local byId, hats, faces = {}, {}, {}
	for _, g in ipairs(p.gear or {}) do
		if type(g) == "table" and g.id then
			byId[g.id] = g
			if Gear.isFacePiece and Gear.isFacePiece(g) or Gear.migrateSlot(g.slot) == "face" then
				table.insert(faces, g)
			elseif (Gear.isHatPiece and Gear.isHatPiece(g)) or Gear.migrateSlot(g.slot) == "hat" then
				-- Prefer real catalog hats; fall back to migrated for old saves.
				if (not Gear.isHatPiece) or Gear.isHatPiece(g) then
					table.insert(hats, g)
				end
			end
		end
	end
	local function byScore(x, y)
		return Dig.gearScore(x) > Dig.gearScore(y)
	end
	table.sort(hats, byScore)
	table.sort(faces, byScore)
	-- Claimed during this plan only. Higher-priority seats may take a hat off a
	-- lower seat; sanitizeHatUniqueness clears duplicates after equip.
	local used = {}
	local function hasSocket(on)
		for _, r in pairs((on and on.sockets) or {}) do
			if r then
				return true
			end
		end
		return false
	end
	-- Better by effective boost value (universal-weighted powerScore), not grade alone.
	local function beats(cand, on)
		if not on then
			return true
		end
		if cand == on or cand.id == on.id then
			return false
		end
		-- A socket is permanent: swapping a piece with a rune in it strands the
		-- rune, so "better" never means that on its own.
		if hasSocket(on) then
			return false
		end
		return Dig.gearScore(cand) > Dig.gearScore(on) + 1e-6
	end
	--[[
		Seats are your three hat seats, in order. Greedy: assign the highest
		remaining hat that beats what is on that seat.

		This used to walk the pets as seats too, strongest-first, with your one
		hat at the front as the highest-priority seat because it applied to the
		whole team. Pets wear nothing now, so the list is just yours -- and all
		THREE seats are in it, where before only `hat` was and `hat2` was left
		holding whatever it happened to hold.
	]]
	for _, slot in ipairs(Gear.HAT_SLOTS or { "hat" }) do
		local on = byId[worn[slot] or ""]
		-- Higher seat already claimed this hat — treat the seat as empty.
		if on and on.id and used[on.id] then
			on = nil
		end
		local best
		for _, cand in ipairs(hats) do
			if not used[cand.id] and beats(cand, on) then
				if (not best) or Dig.gearScore(cand) > Dig.gearScore(best) then
					best = cand
				end
			end
		end
		if best then
			used[best.id] = true
			plan.gear[slot] = best.id
			plan.gearCount += 1
		elseif on and on.id then
			-- Keep current reserved so a later seat cannot steal it.
			used[on.id] = true
		end
	end
	used[worn.face or ""] = true
	for _, cand in ipairs(faces) do
		if not used[cand.id] and beats(cand, byId[worn.face or ""]) then
			used[cand.id] = true
			plan.gear.face = cand.id
			plan.gearCount += 1
			break
		end
	end

	-- Pets: the strongest seats by power, kept in a short sorted list.
	local n = math.max(1, math.floor(C.effectivePetSlots and C.effectivePetSlots(p) or tonumber(p.petSlots) or 3))
	local top = {}
	for _, c in ipairs(p.cards or {}) do
		if type(c) == "table" and c.id then
			local pw = C.cardPower(c)
			if #top < n or pw > top[#top].pw then
				if #top >= n then
					table.remove(top)
				end
				table.insert(top, { id = c.id, pw = pw })
				table.sort(top, function(a, b)
					return a.pw > b.pw
				end)
			end
		end
	end
	local on, wornPowers = {}, {}
	for _, id in ipairs(p.equipped or {}) do
		on[id] = true
		local c = cardById(p, id)
		if c then
			table.insert(wornPowers, C.cardPower(c))
		end
	end
	table.sort(wornPowers)
	local free = n - #wornPowers
	for _, t in ipairs(top) do
		if not on[t.id] then
			if free > 0 then
				free -= 1
				plan.petCount += 1
			elseif #wornPowers > 0 and t.pw > wornPowers[1] + 1e-6 then
				table.remove(wornPowers, 1)
				plan.petCount += 1
			end
		end
	end
	if plan.petCount > 0 then
		plan.pets = {}
		for _, t in ipairs(top) do
			table.insert(plan.pets, t.id)
		end
	end
	return plan
end
function Dig.upgradesFor(p, userId)
	local hit = userId and Dig.upgradeCache[userId]
	if hit and (os.clock() - hit.at) < 2 then
		return hit.out
	end
	local ok, plan = pcall(Dig.planUpgrades, p)
	local out = ok and { gear = plan.gearCount, pets = plan.petCount } or { gear = 0, pets = 0 }
	if userId then
		Dig.upgradeCache[userId] = { at = os.clock(), out = out }
	end
	return out
end

function Verbs.equipBest(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	sanitizeHatUniqueness(p)
	local plan = Dig.planUpgrades(p)
	local did = {}
	if plan.gearCount > 0 then
		p.equippedGear = p.equippedGear or {}
		for slot, id in pairs(plan.gear) do
			p.equippedGear[slot] = id
		end
		sanitizeHatUniqueness(p)
		table.insert(did, plan.gearCount .. (plan.gearCount == 1 and " piece" or " pieces"))
		introAdvance(plr, p, 10)
	end
	if plan.pets then
		p.equipped = plan.pets
		table.insert(did, plan.petCount .. (plan.petCount == 1 and " pet" or " pets"))
		introAdvance(plr, p, 6)
	end
	Dig.upgradeCache[plr.UserId] = nil
	if #did == 0 then
		net:FireClient(plr, "toast", "You are already wearing your best")
	else
		net:FireClient(plr, "toast", "Equipped your best: " .. table.concat(did, " + "))
	end
	markDirty(plr)
	snap(plr)
	walk(plr)
end

Dig.boostSources = function(p)
	local out = {}
	local ADD = { echo = true, zap = true, blastRadius = true, autoMine = true, blastChance = true, luckyFind = true,
		fossilFind = true, pulverize = true, scrap = true, coolant = true, shortFuse = true, reach = true,
		earthquake = true, ricochet = true }
	local function add(stat, name, amt)
		if type(amt) ~= "number" or math.abs(amt) < 0.0005 then
			return
		end
		out[stat] = out[stat] or {}
		table.insert(out[stat], { n = name, a = math.floor(amt * 1000 + 0.5) / 1000 })
	end
	local function diff(name, b)
		local e = Cards.emptyBoosts()
		for k, v in pairs(b) do
			local e0 = e[k]
			if type(v) == "number" and type(e0) == "number" and v ~= e0 then
				if ADD[k] then
					add(k, name, v - e0)
				elseif k == "swingSec" then
					add("swingRate", name, e0 / math.max(0.01, v) - 1)
				elseif e0 ~= 0 then
					add(k, name, v / e0 - 1)
				end
			end
		end
	end
	pcall(function()
		local n = #(p.equipped or {})
		for _, id in ipairs(p.equipped or {}) do
			local c = cardById(p, id)
			if c then
				local b = Cards.emptyBoosts()
				Cards.applyKit(b, c, C.cardPower(c), n)
				Cards.foldSwingRate(b)
				diff(tostring(c.name or "Pet"), b)
			end
		end
		for stat, v in pairs(Skills.totalStats(skillState(p), Stats) or {}) do
			add(stat, "Skill tree", v)
		end
		for _, held in ipairs(p.relics or {}) do
			local r = C.relicById(held.id)
			if r then
				add(r.stat, "Relic: " .. tostring(r.name or r.id), r.amount)
			end
		end
		for id, level in pairs(p.charter or {}) do
			local row = C.charterById(id)
			if row and level > 0 then
				add(row.stat, "Charter: " .. tostring(row.name or id), row.per * math.min(level, row.max))
			end
		end
		local byRune = {}
		for _, r in ipairs(p.runes or {}) do
			byRune[r.id] = r
		end
		local function rune(label, rid)
			local r = rid and byRune[rid]
			if r then
				local b = Cards.emptyBoosts()
				Runes.applyRune(b, r)
				Cards.foldSwingRate(b)
				diff(label, b)
			end
		end
		local _, fam = equippedTool(p)
		local sock = p.toolSockets and p.toolSockets[fam]
		if type(sock) == "string" then
			rune("Rune on your " .. tostring(fam), sock)
		elseif type(sock) == "table" then
			rune("Rune on your " .. tostring(fam), sock.main)
			rune("Omni rune", sock.omni)
		end
		for _, ct in ipairs(p.chestTools or {}) do
			if ct.runeId and p.chestTool == ct.id then
				rune("Rune on " .. tostring(ct.name or "tool"), ct.runeId)
			end
		end
		if p.shopToolId and not p.chestTool and p.shopToolRunes then
			rune("Rune on your tool", p.shopToolRunes[p.shopToolId])
		end
		for _, cardId in ipairs(p.equipped or {}) do
			local rid = p.petSockets and p.petSockets[cardId]
			local c = rid and cardById(p, cardId)
			if c then
				rune("Rune on " .. tostring(c.name or "pet"), rid)
			end
		end
		--[[
			Hats and the face are multipliers on the pets, not stats of their
			own, so each one is measured the honest way: stack the team with
			that single piece on, and report the difference against the team
			with nothing on.
		]]
		do
			local rows, pieces = Dig.petRows(p, #(p.equipped or {}))
			local eq = p.equippedGear or {}
			local function variant(withHats, withRunes, onlyIndex)
				local v = {}
				for i, r in ipairs(rows) do
					local keep = (onlyIndex == nil) or (i == onlyIndex)
					v[i] = {
						delta = r.delta,
						hat = (withHats and keep) and r.hat or nil,
						rune = (withRunes and keep) and r.rune or nil,
					}
				end
				return v
			end
			local bare = Gear.stackPets(variant(false, false), nil, nil)
			local function emit(name, total)
				local b = Cards.emptyBoosts()
				for stat, amount in pairs(total) do
					local d = amount - (bare[stat] or 0)
					if d ~= 0 then
						if stat == "swingRate" then
							b.swingRate = (b.swingRate or 1) + d
						elseif b[stat] ~= nil then
							b[stat] += d
						end
					end
				end
				Cards.foldSwingRate(b)
				diff(name, b)
			end
			for i, row in ipairs(rows) do
				if row.hat then
					emit((row.hat.name or "Hat") .. " on " .. row.name, Gear.stackPets(variant(true, false, i), nil, nil))
				end
				if row.rune then
					emit("Rune on " .. row.name .. " (spread)", Gear.stackPets(variant(false, true, i), nil, nil))
				end
			end
			--[[
				Gear is ONE flat row now, not "your hat (all pets)" and "your
				face (whole team)". Those two lines described the old stack,
				where a hat was counted once per pet and the face multiplied
				it; leaving them would be a breakdown of arithmetic that no
				longer happens.
			]]
			local myHat = pieces[eq.hat or ""]
			local myFace = pieces[eq.face or ""]
			do
				local flat = Gear.flatBoost(Gear.wornHats(eq, pieces), myFace)
				local gearOnly = Cards.emptyBoosts()
				for stat, amount in pairs(flat) do
					if stat == "swingRate" then
						gearOnly.swingRate = (gearOnly.swingRate or 1) + amount
					elseif gearOnly[stat] ~= nil then
						gearOnly[stat] += amount
					end
				end
				Cards.foldSwingRate(gearOnly)
				diff("Your gear (flat, layer 2)", gearOnly)
			end
			local gb = Cards.emptyBoosts()
			Gear.applyEquipped(gb, { hat = myHat, face = myFace }, byRune)
			diff("Runes in your gear", gb)
		end
		if p.equippedCharm then
			local cb = Cards.emptyBoosts()
			Charms.applyEquipped(cb, p.equippedCharm, p)
			diff("Charm", cb)
		end
		local pb = Cards.emptyBoosts()
		require(shared:WaitForChild("MinePotions")).applyBoosts(pb, p)
		diff("Potion", pb)
		add("luck", "Rebirth rank", (C.prestigeLuck(p.prestige) or 1) - 1)
	end)
	return out
end

--[[
	REBIRTH KEEPS. tryPrestige starts from blank() and copies what survives;
	anything that is not the coin ladder belongs on this list.
]]
Verbs.KEEP_ON_REBIRTH = {
	-- tutorial
	"intro", "introVer", "introGrants", "introStepBlocks", "introStepChests", "mergePromptShown",
	"tutorialRewarded", "introCharmGot", "introGearOpened", "introScrapped", "introTemperRolls",
	-- quest ladder version (quest / questBase ride along above)
	"questVer",
	-- one-time flags and ledgers
	"codes", "receipts", "starterBought", "referredBy", "funnelJoined", "invites",
	"discordLinked", "discordId", "discordBonusClaimed", "milestones", "freeGearUsed",
	"dustShop", "backpackCoinV2",
	-- owned things (some bought with Robux)
	"ownedPets", "potions", "activePotions", "vfx", "equippedVfx", "chestBag", "vipPass", "vip",
	"shopToolRunes", "charms", "equippedCharm", "dealBuys", "creditBuys",
	-- records and settings
	"packsOpened", "playtime", "settings",
	-- save guard: a profile that never loaded must stay unsaveable
	"_ephemeral", "_userId",
}

-- Depth and pickaxe tier reset with rebirth. Keep the progress a quest has
-- already made on them instead of sending it negative.
function Verbs.rebaseVolatileQuests(old, fresh)
	fresh.questBase = fresh.questBase or {}
	for _, stat in ipairs({ "depth", "picktier" }) do
		local base = tonumber(fresh.questBase[stat])
		if base then
			local made = math.max(0, questValue(old, stat) - base)
			fresh.questBase[stat] = questValue(fresh, stat) - made
		end
	end
end

--[[
	A quest's tool unlock. Nothing to hand over when the tool is owned, or a
	better one of the same kind from the same shop is -- grantReward pays the
	quest's gems either way. Otherwise the tool is owned (its forever bonus
	counts) and, if the player holds that kind of tool, it goes in their hands.
]]
function Verbs.grantShopTool(plr, p, id)
	local okL, Ladders = pcall(require, shared:WaitForChild("MineShopLadders"))
	local row = okL and Ladders and Ladders.byId(id)
	if not row then
		return false
	end
	p.ownedShopTools = p.ownedShopTools or {}
	if p.ownedShopTools[row.id] then
		return false
	end
	local rank = (tonumber(row.zoneIndex) or 1) * 100 + (tonumber(row.slot) or 1)
	for oid, on in pairs(p.ownedShopTools) do
		local o = on and Ladders.byId(oid)
		if o and o.family == row.family and o.desk == row.desk
			and ((tonumber(o.zoneIndex) or 1) * 100 + (tonumber(o.slot) or 1)) > rank then
			return false
		end
	end
	p.ownedShopTools[row.id] = true
	if not p.chestTool and (p.toolFamily or "pickaxe") == (row.family or "pickaxe") then
		p.shopToolId = row.id
		p.toolEquipped = true
		pcall(givePickaxe, plr)
	end
	return true
end

--[[
	PLAYTIME GIFTS (MineQuests.PLAYTIME). Time in the server today (UTC)
	counts up every 15 seconds and is saved with the profile, so a rejoin
	carries on. A new day starts the row again.
]]
function Verbs.playtimeOf(p)
	local today = utcDayIndex()
	local pt = p.playtime
	if type(pt) ~= "table" or pt.day ~= today then
		pt = { day = today, secs = 0, got = {} }
		p.playtime = pt
	end
	pt.got = pt.got or {}
	return pt
end

function Verbs.tickPlaytime(plr, dt)
	local p = profiles[plr.UserId]
	if not p or p._ephemeral then
		return
	end
	local pt = Verbs.playtimeOf(p)
	local was = tonumber(pt.secs) or 0
	pt.secs = was + dt
	for i, g in ipairs(Quests.PLAYTIME or {}) do
		local need = g.min * 60
		if was < need and pt.secs >= need and not pt.got[tostring(i)] then
			net:FireClient(plr, "giftReady", { index = i, secs = pt.secs, serverTime = os.time() })
		end
	end
end

function Verbs.claimPlaytime(plr, payload)
	local p = profiles[plr.UserId]
	if not p or p._ephemeral then
		return
	end
	local i = math.floor(tonumber(type(payload) == "table" and payload.index or payload) or 0)
	local g = Quests.PLAYTIME and Quests.PLAYTIME[i]
	if not g then
		return
	end
	local pt = Verbs.playtimeOf(p)
	if pt.got[tostring(i)] then
		net:FireClient(plr, "toast", "Already opened")
		return
	end
	if (tonumber(pt.secs) or 0) < g.min * 60 then
		net:FireClient(plr, "toast", "Not ready yet")
		return
	end
	pt.got[tostring(i)] = true
	local gems = Quests.playtimeGems(g.reward, p.maxUnlockedZone or 1)
	grantReward(plr, p, g.reward, gems > 0 and gems or nil)
	introAdvance(plr, p, 20)
	markDirty(plr)
	net:FireClient(plr, "toast", "Gift: " .. Quests.describe(g.reward, gems > 0 and gems or nil))
	if g.reward.pack then
		local def = Packs.PACK_BY_ID[g.reward.pack]
		net:FireClient(plr, "purchaseFx", { kind = "pack", packId = g.reward.pack, count = g.reward.packQty or 1,
			name = (def and def.name) or g.reward.pack })
	end
	pcall(function()
		game:GetService("AnalyticsService"):LogCustomEvent(plr, "PlaytimeGift" .. i, 1)
	end)
end

task.spawn(function()
	while true do
		task.wait(15)
		for _, plr in ipairs(Svc.Players:GetPlayers()) do
			pcall(Verbs.tickPlaytime, plr, 15)
		end
	end
end)

function Verbs.grantPacks(plr, p, list)
	local setIds = {}
	for id in pairs(Cards.SETS or {}) do
		setIds[#setIds + 1] = id
	end
	table.sort(setIds)
	p.packs = p.packs or {}
	for _, row in ipairs(list or {}) do
		local def = Packs.PACK_BY_ID[row.id]
		for _ = 1, math.max(1, tonumber(row.qty) or 1) do
			table.insert(p.packs, {
				packId = row.id,
				packName = (def and def.name) or row.id,
				setId = (#setIds > 0) and setIds[Random.new():NextInteger(1, #setIds)] or "dragons_dawn",
			})
		end
	end
end

-- Sound switches from the Settings panel; the client applies them itself.
function Verbs.setSetting(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(payload) ~= "table" then
		return
	end
	local key = tostring(payload.key or "")
	p.settings = p.settings or {}
	if key == "sfx" or key == "ambience" or key == "petGlow" or key == "simpleAbbrev" then
		p.settings[key] = payload.value == true
	elseif key == "cardSort" then
		-- Persist inventory/binder card sort across sessions (profile DataStore).
		local SORT_OK = {
			rarity = true, equipped = true, qty = true, boosts = true, recent = true,
			set = true, alpha = true, type = true, power = true, variant = true, role = true,
		}
		local v = tostring(payload.value or "")
		if not SORT_OK[v] then
			return
		end
		p.settings.cardSort = v
	else
		return
	end
	markDirty(plr)
end

--[[
	PROMO CODES. Case and spaces do not matter; each code works once per
	player; `expires` (os.time) is optional. Codes are free, so they are fine
	for everyone, including players whose rules restrict paid random items.
]]
Verbs.CODES = {
	LAUNCH = { packs = { { id = "cobalt_pack", qty = 1 }, { id = "crimson_pack", qty = 1 } }, gems = 500 },
}
Verbs.codeAt = {}

function Verbs.redeemCode(plr, payload)
	local p = profiles[plr.UserId]
	if not p or p._ephemeral then
		net:FireClient(plr, "codeResult", { ok = false, msg = "Codes aren't available right now. Try again in a moment." })
		return
	end
	local now = os.clock()
	if (Verbs.codeAt[plr.UserId] or -99) + 1.5 > now then
		net:FireClient(plr, "codeResult", { ok = false, msg = "One moment, then try again." })
		return
	end
	Verbs.codeAt[plr.UserId] = now
	local raw = type(payload) == "table" and payload.code or payload
	local code = string.upper((tostring(raw or ""):gsub("%s", "")))
	local def = Verbs.CODES[code]
	if not def or (def.expires and os.time() > def.expires) then
		net:FireClient(plr, "codeResult", { ok = false, msg = "That code isn't valid." })
		return
	end
	p.codes = p.codes or {}
	if p.codes[code] then
		net:FireClient(plr, "codeResult", { ok = false, msg = "You've already used that code." })
		return
	end
	p.codes[code] = os.time()
	Verbs.grantPacks(plr, p, def.packs)
	p.gems = (p.gems or 0) + (tonumber(def.gems) or 0)
	markDirty(plr)
	snap(plr)
	for _, row in ipairs(def.packs or {}) do
		local pd = Packs.PACK_BY_ID[row.id]
		net:FireClient(plr, "purchaseFx", { kind = "pack", packId = row.id, count = row.qty or 1, name = (pd and pd.name) or row.id })
	end
	net:FireClient(plr, "codeResult", { ok = true, msg = "Code redeemed! Check your bag." })
	pcall(function()
		game:GetService("AnalyticsService"):LogCustomEvent(plr, "CodeRedeemed", 1)
	end)
end

--[[
	INVITES. A friend who joins through your invite (JoinData
	ReferredByPlayerId) and is brand new gets a welcome pack; you get a pack
	too -- straight away if you are in their server, otherwise the next time
	you join. At most five inviter rewards a day, so alt accounts are not a
	farm.
]]
Verbs.INVITE_REWARD = {
	friend = { { id = "crimson_pack", qty = 1 } },
	inviter = { { id = "cobalt_pack", qty = 1 } },
	perDay = 5,
}

function Verbs.rewardInviter(plr, count)
	local p = profiles[plr.UserId]
	if not p or count <= 0 then
		return
	end
	local day = math.floor(os.time() / 86400)
	p.invites = p.invites or { day = day, n = 0 }
	if p.invites.day ~= day then
		p.invites = { day = day, n = 0 }
	end
	local give = math.min(count, Verbs.INVITE_REWARD.perDay - p.invites.n)
	if give <= 0 then
		return
	end
	p.invites.n += give
	for _ = 1, give do
		Verbs.grantPacks(plr, p, Verbs.INVITE_REWARD.inviter)
	end
	markDirty(plr)
	snap(plr)
	net:FireClient(plr, "toast", give == 1 and "A friend joined from your invite — +1 Cobalt Pack!"
		or string.format("%d friends joined from your invites — +%d Cobalt Packs!", give, give))
end

function Verbs.handleJoin(plr)
	local p = profiles[plr.UserId]
	if not p or p._ephemeral then
		return
	end
	--[[
		A player coming back from the AFK keep-alive hop has not joined
		anything -- they were here a moment ago and, as far as anyone watching
		is concerned, never left. Announcing it spams the chat once every
		refresh interval for every AFK player in the server.
	]]
	local resumed = false
	pcall(function()
		local join = plr:GetJoinData()
		local td = join and join.TeleportData
		resumed = (type(td) == "table") and td.mineAfkResume == true
	end)
	if not resumed then
		net:FireAllClients("sysChat", {
			text = ((plr.DisplayName ~= "" and plr.DisplayName) or plr.Name) .. " joined the mine.",
			color = "#9AD7FF",
		})
	end
	local brandNew = (tonumber(p.intro) or 1) <= 1 and ((p.stats and p.stats.blocks) or 0) == 0
	if brandNew and not p.funnelJoined then
		p.funnelJoined = true
		pcall(function()
			game:GetService("AnalyticsService"):LogOnboardingStepEvent(plr, 1, "Joined")
		end)
	end
	local inviteStore = Svc.DSS:GetDataStore(C.storeName("InviteRewards_v1"))
	-- Joined through a friend's invite?
	local join = plr:GetJoinData()
	local ref = join and tonumber(join.ReferredByPlayerId)
	if brandNew and ref and ref > 0 and ref ~= plr.UserId and not p.referredBy then
		p.referredBy = ref
		Verbs.grantPacks(plr, p, Verbs.INVITE_REWARD.friend)
		markDirty(plr)
		net:FireClient(plr, "toast", "A friend invited you — here's a Crimson Pack to start!")
		pcall(function()
			game:GetService("AnalyticsService"):LogCustomEvent(plr, "JoinedFromInvite", 1)
		end)
		local inviter = Svc.Players:GetPlayerByUserId(ref)
		if inviter and profiles[ref] then
			Verbs.rewardInviter(inviter, 1)
		else
			pcall(function()
				inviteStore:UpdateAsync("u_" .. ref, function(old)
					return math.min(50, (tonumber(old) or 0) + 1)
				end)
			end)
		end
	end
	-- Friends who joined from this player's invites while they were away.
	local owed = 0
	pcall(function()
		inviteStore:UpdateAsync("u_" .. plr.UserId, function(old)
			owed = tonumber(old) or 0
			if owed <= 0 then
				return nil
			end
			return 0
		end)
	end)
	if owed > 0 then
		Verbs.rewardInviter(plr, owed)
	end
end

--[[
	ROBLOX'S PER-PLAYER RULES (PolicyService), looked up on join and kept as
	attributes on the Player so the client can hide what the server refuses:
	  PolicyNoRandom   paid random items restricted where they live: nothing
	                   that rolls may be bought with credits, gems, stardust or
	                   tokens (all of which trace back to Robux here)
	  PolicyNoTrade    may not trade items bought, even indirectly, with Robux
	  PolicyDiscord    may see Discord references and claim the link reward
	Until Roblox answers, a live server assumes the strictest rules; a failed
	lookup is retried with backoff for as long as the player stays.
]]
Verbs.PAID_RANDOM = {
	buyCart = true, buyScroll = true, buyDustPack = true, luckyGradeUp = true,
	rollRune = true, rollGear = true, rollTemper = true, fuseRune = true,
	openTemperCase = true, openTemperCaseBundle = true, scrapTemper = true,
	buyCrate = true, buyCharmsPack = true, buyPouch = true,
}

function Verbs.fetchPolicy(plr)
	local PolicyService = game:GetService("PolicyService")
	if not Svc.Run:IsStudio() then
		plr:SetAttribute("PolicyNoRandom", true)
		plr:SetAttribute("PolicyNoTrade", true)
		plr:SetAttribute("PolicyDiscord", false)
	end
	local backoff = 2
	while plr.Parent do
		local ok, info = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(plr)
		end)
		if ok and type(info) == "table" then
			local discord = false
			for _, ref in ipairs(info.AllowedExternalLinkReferences or {}) do
				if ref == "Discord" then
					discord = true
				end
			end
			plr:SetAttribute("PolicyNoRandom", info.ArePaidRandomItemsRestricted == true)
			plr:SetAttribute("PolicyNoTrade", info.IsPaidItemTradingAllowed == false)
			plr:SetAttribute("PolicyDiscord", discord)
			return
		end
		task.wait(backoff)
		backoff = math.min(60, backoff * 2)
	end
end

-- True when this player's rules forbid the action (and says why).
function Verbs.policyBlocks(plr, action)
	if Verbs.PAID_RANDOM[action] and plr:GetAttribute("PolicyNoRandom") == true then
		net:FireClient(plr, "toast", "That isn't available in your region")
		return true
	end
	if action == "discordLink" and plr:GetAttribute("PolicyDiscord") ~= true then
		return true
	end
	return false
end

function Verbs.hookPlayer(plr)
	task.spawn(Verbs.fetchPolicy, plr)
	local okLoad, errLoad = pcall(load, plr)
	if not okLoad then
		warn("[Mine] load failed", plr.UserId, errLoad)
		-- Ephemeral blank: do NOT SetAsync over a real save if GetAsync blipped.
		profiles[plr.UserId] = blank()
		profiles[plr.UserId].tools = { pickaxe = 1, drill = 0, explosive = 0 }
		profiles[plr.UserId].toolEquipped = true
		profiles[plr.UserId]._ephemeral = true
	end
	pcall(function()
		local p = profiles[plr.UserId]
		if not p or p.discordLinked then
			return
		end
		local row = DiscordLink.getByRoblox(plr.UserId)
		if row then
			p.discordLinked = true
			p.discordId = tostring(row.discordId)
		end
	end)
	task.spawn(function()
		local okJ, errJ = pcall(Verbs.handleJoin, plr)
		if not okJ then
			warn("[Mine] handleJoin", errJ)
		end
	end)
	pcall(function()
		local Grant = require(shared:WaitForChild("MineStudioGrant"))
		if Grant.playtestReset(plr, profiles, blank) then
			save(plr)
		end
	end)
	pcall(function()
		Dig.Auth.watchPlayer(plr, function(player)
			return profiles[player.UserId]
		end, tp, surfaceCf)
	end)
	local function boot()
		task.wait(0.5)
		pcall(Verbs.spawnAtLobby, plr)
		--[[
			FIRST SPAWN GOES TO THE HOLE.
		
			A new player landed in the lobby: seven shop fronts, a depot, a portal
			row, and the mine itself 125 studs away through a gap they have to
			notice. Step 1 of the tutorial says to hold on a rock, and there is no
			rock within reach -- which is why that line had to name the walk.
		
			Only for a profile that has never broken a block. Everyone else keeps
			the lobby, and an AFK resume below still overrides this.
		]]
		local firstSpawnAtPit = profiles[plr.UserId]
		if firstSpawnAtPit
			and (tonumber(firstSpawnAtPit.intro) or 1) <= 1
			and (((firstSpawnAtPit.stats or {}).blocks) or 0) == 0 then
			local z = C.zoneById(firstSpawnAtPit.zoneId) or C.ZONES[1]
			task.delay(0.15, function()
				if plr.Parent then
					pcall(tp, plr, surfaceCf(z))
				end
			end)
		end
		pcall(walk, plr)
		-- Re-apply VIP DisplayName on each character (Humanoid is new each spawn).
		pcall(applyVipNameTag, plr, hasVipPass(plr))
		local okPick, errPick = pcall(givePickaxe, plr)
		if not okPick then warn("[Mine] givePickaxe", errPick) end
		local okBag, errBag = pcall(giveBackpackModel, plr)
		if not okBag then warn("[Mine] giveBackpackModel", errBag) end
		local okSnap, errSnap = pcall(snap, plr)
		if not okSnap then warn("[Mine] snap", errSnap) end
		-- Hats/faces after appearance has settled so Face description sticks.
		task.delay(0.8, function()
			pcall(applyPlayerCosmetics, plr)
		end)
		pcall(introSend, plr, profiles[plr.UserId])
		pcall(maybeMergePrompt, plr, profiles[plr.UserId])
		pcall(function()
			MineBadges.reconcile(plr, profiles[plr.UserId])
		end)
		-- Mark AFK resume; the AFK loop picks them up once it is live.
		local p = profiles[plr.UserId]
		local join = plr:GetJoinData()
		local td = join and join.TeleportData
		if p and type(td) == "table" and td.mineAfkResume then
			p.afk = true
			-- Straight back to the spot they went AFK on (see refreshSession).
			local at = p.afkAt
			if type(at) == "table" and tonumber(at[1]) then
				local back = CFrame.new(
					tonumber(at[1]) or 0, tonumber(at[2]) or 0, tonumber(at[3]) or 0
				) * CFrame.Angles(0, tonumber(at[4]) or 0, 0)
				task.delay(0.35, function()
					if plr.Parent then
						pcall(tp, plr, back)
					end
				end)
			end
		end
	end
	plr.CharacterAdded:Connect(function()
		task.spawn(boot)
		task.defer(function()
			local function lift()
				local prof = profiles[plr.UserId]
				if prof and prof.zoneId == "bigbang" and plr.Parent then
					require(game.ServerScriptService.Mine.MineEventHorizon).setLowGravity(plr, true)
				end
			end
			lift()
			task.delay(0.5, lift)
		end)
	end)
	if plr.Character then
		task.spawn(boot)
	end
end

MineAntiGear.start()
Svc.Players.PlayerAdded:Connect(Verbs.hookPlayer)
-- IIFE: top-level `for _` would exceed Luau's 200 main-chunk register cap.
;(function()
	for _, plr in ipairs(Svc.Players:GetPlayers()) do
		Verbs.hookPlayer(plr)
	end
end)()

;(function()
	--[[
		SAVE ON LEAVE, AND WAIT FOR IT ON SHUTDOWN.

		PlayerRemoving started a save and cleared the profile in the same
		breath, and BindToClose only saved players still in Svc.Players -- which,
		during a shutdown, the leaving players already are not. Nothing waited
		for the save already running, so the server could close underneath it
		and everything since the last 45-second autosave was gone: a finished
		tutorial step, a sale, a roll. Closing a Studio test hits this every time.

		Now each save is counted while it runs, and shutdown waits for the count
		to reach zero (inside the roughly 30 seconds Roblox allows).
		IIFE, not a do-block: do-locals still burn the main chunk's 200 registers.
	]]
	local inFlight, saving = 0, {}
	local function saveTracked(plr)
		local id = plr.UserId
		if saving[id] then
			return
		end
		saving[id] = true
		inFlight += 1
		local ok, err = pcall(save, plr)
		inFlight -= 1
		saving[id] = nil
		if not ok then
			warn("[Mine] save errored for " .. tostring(id) .. ": " .. tostring(err))
		end
	end

	Svc.Players.PlayerRemoving:Connect(function(plr)
		local p = profiles[plr.UserId]
		if p then
			LeaderboardService.queueUpdate(plr.UserId, p.prestige, p.gems, LeaderboardService.profileStardustValue(p))
		end
		TradeService.onLeave(net, plr.UserId)
		SocialService.onPlayerLeave(plr.UserId)
		if p then
			p._releasing = true
		end
		saveTracked(plr)
		profiles[plr.UserId] = nil
		swingBudget[plr.UserId] = nil
		vipPassOwned[plr.UserId] = nil
	end)

	game:BindToClose(function()
		for _, plr in ipairs(Svc.Players:GetPlayers()) do
			if profiles[plr.UserId] then
				profiles[plr.UserId]._releasing = true
				task.spawn(saveTracked, plr)
			end
		end
		task.wait()
		local deadline = os.clock() + 25
		while inFlight > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end)()

task.spawn(function()
	while true do
		task.wait(45)
		for _, plr in ipairs(Svc.Players:GetPlayers()) do save(plr) end
	end
end)

--[[
	THE WORMHOLE BAG CASHES ITSELF.

	Every autoSellSec (180 on the Wormhole), and ONLY when the bag is actually
	full. That condition is the whole point: it is a bag that empties itself
	when it can hold no more, not a drip of free coins for standing still.

	Which is also why the bag is not `infinite` any more -- cap() rewrites an
	infinite bag to 1e15 slots, so it could never be full and this could never
	fire once. Founders keeps infinity and is the better bag for it.

	The clock runs whether or not the bag is full, so the timer a player sees
	is honest: it says when the next attempt happens, not when a sale happens.
]]
task.spawn(function()
	while true do
		task.wait(2)
		local now = os.clock()
		for _, plr in ipairs(Svc.Players:GetPlayers()) do
			local p = profiles[plr.UserId]
			local row = p and C.BACKPACKS[p.backpackTier]
			local every = row and tonumber(row.autoSellSec)
			if p and every and every > 0 then
				if not p.autoSellAt then
					p.autoSellAt = now + every
				elseif now >= p.autoSellAt then
					p.autoSellAt = now + every
					if (tonumber(p.load) or 0) >= cap(p) then
						pcall(sellAll, plr)
					end
				end
			elseif p then
				-- Swapped off the bag: drop the clock so it restarts clean.
				p.autoSellAt = nil
			end
		end
	end
end)

-- The client shows these rules too, but the server is the one that decides.
function Verbs.skillBuy(plr, id)
	local p = profiles[plr.UserId]
	if type(id) ~= "string" then
		return
	end
	--[[
		THE TREE CHANGES IN THE CLOUDS.

		Buying, resetting, sacrificing and swapping presets all happen on the
		cloud deck and nowhere else. That rule used to be a lockout, because the
		only way up was a rebirth and one broken block shut the window until the
		next. The Clouds is a place now: the Skills panel sends you up any time
		(goClouds), and "in the Clouds" is where the server sees your character
		standing -- so walking off the deck or jumping to the lobby ends it with
		no flag to forget to clear.

		The refusal snapshots so a wheel that still thinks you are up there
		corrects itself instead of waiting for the next unrelated change.
	]]
	if not C.playerInClouds(plr) then
		net:FireClient(plr, "toast", "Go to the Clouds to change your tree")
		snap(plr)
		return
	end
	local state, slot = skillState(p)
	local ok, why, other, cost = Skills.canBuy(state, id)
	if not ok then
		local msg = "Locked"
		if why == "tokens" then
			msg = "Not enough skill points"
		elseif why == "maxed" then
			msg = "Already fully ranked"
		elseif why == "road" then
			msg = "You took the other road: " .. (other and other.name or "")
		elseif why == "rival" then
			msg = "Rival keystone owned: " .. (other and other.name or "")
		elseif why == "prereq" then
			msg = "Buy what it connects to first"
		end
		net:FireClient(plr, "toast", msg)
		return
	end
	slot.levels[id] = (slot.levels[id] or 0) + 1
	slot.spent += cost
	snap(plr)
	walk(plr)
end

function Verbs.skillPreset(plr, wanted)
	local p = profiles[plr.UserId]
	local slotIndex = math.clamp(tonumber(wanted) or 1, 1, Skills.PRESETS.max)
	if slotIndex > Skills.presetsAvailable(p.boughtSecond) then
		net:FireClient(plr, "toast", "Second preset costs " .. Skills.PRESETS.secondSlotCost .. " skill points")
		return
	end
	if not C.playerInClouds(plr) then
		net:FireClient(plr, "toast", "Swap builds in the Clouds")
		snap(plr)
		return
	end
	p.skillPresets = p.skillPresets or {}
	p.skillPresets[slotIndex] = p.skillPresets[slotIndex] or { levels = {}, spent = 0 }
	p.skillSlot = slotIndex
	snap(plr)
	walk(plr)
end

-- The second preset is the one thing tokens buy that is not power.
function Verbs.skillBuySlot(plr)
	local p = profiles[plr.UserId]
	if p.boughtSecond then
		return
	end
	if not C.playerInClouds(plr) then
		net:FireClient(plr, "toast", "Buy the second preset in the Clouds")
		snap(plr)
		return
	end
	local state, slot = skillState(p)
	if state.tokens < Skills.PRESETS.secondSlotCost then
		net:FireClient(plr, "toast", "Needs " .. Skills.PRESETS.secondSlotCost .. " skill points")
		return
	end
	slot.spent += Skills.PRESETS.secondSlotCost
	-- Recorded so a reset of this preset knows these 25 were not a node.
	slot.slotCharge = (slot.slotCharge or 0) + Skills.PRESETS.secondSlotCost
	p.boughtSecond = true
	p.skillPresets[2] = p.skillPresets[2] or { levels = {}, spent = 0 }
	net:FireClient(plr, "toast", "Second preset unlocked")
	markDirty(plr)
	snap(plr)
end

--[[
	RESET, SACRIFICE, AND THE WAY UP.

	Written as Verbs fields rather than top-level locals: this script sits
	against Luau's 200-register ceiling, and all three are only ever called
	from the dispatcher below.
]]

-- Every node in the active preset back to free points. Free, because a reset
-- that cost anything would make every experiment a permanent loss.
function Verbs.skillReset(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	if not C.playerInClouds(plr) then
		net:FireClient(plr, "toast", "Reset your tree in the Clouds")
		snap(plr)
		return
	end
	local state, slot = skillState(p)
	if state.refund <= 0 and next(slot.levels) == nil then
		net:FireClient(plr, "toast", "Nothing to reset")
		return
	end
	slot.levels = {}
	slot.spent = state.charge
	slot.slotCharge = state.charge
	net:FireClient(plr, "toast", string.format("Tree reset: %d skill point%s back",
		state.refund, state.refund == 1 and "" or "s"))
	markDirty(plr)
	snap(plr)
	walk(plr)
end

--[[
	SELL AND BUY BACK.

	One free skill point for UNUSED_SKILL_POINT_SELL tokens, and the same price
	to buy it back. Same price both ways is what makes selling safe to try: the
	only thing ever permanently gone is what you roll temperaments with.

	Only free points are sold -- a point in a node comes out through Reset
	first. And a sold point is gone from every preset, so the sale is refused if
	any preset has already spent it; burning it anyway would leave that preset
	owing a point it never had.

	Buying is NOT capped at what you sold any more. A point you sold comes back
	first (`skillBurned`), and after that the same price buys a NEW one
	(`skillBought`) for as long as the tree still has a level to spend it on.
	That is the far end of the token economy: recycle a flagship, buy points,
	and out-build what rebirths alone would ever hand you (1,355 to max the
	tree against 460 from forty rebirths).
]]
function Verbs.skillSell(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	if not C.playerInClouds(plr) then
		net:FireClient(plr, "toast", "Sell skill points in the Clouds")
		snap(plr)
		return
	end
	local state = skillState(p)
	if (state.tokens or 0) < 1 then
		net:FireClient(plr, "toast", "No free skill points to sell")
		return
	end
	local budget = (p.skillEarned or 0) + (p.skillBought or 0) - (p.skillBurned or 0) - 1
	for _, preset in pairs(p.skillPresets or {}) do
		if type(preset) == "table" and (preset.spent or 0) > budget then
			net:FireClient(plr, "toast", "Your other preset is using that point")
			return
		end
	end
	local pay = Skills.UNUSED_SKILL_POINT_SELL or 30
	p.skillBurned = (p.skillBurned or 0) + 1
	p.temperTokens = (p.temperTokens or 0) + pay
	net:FireClient(plr, "toast", string.format("Sold 1 skill point: +%d tokens", pay))
	markDirty(plr)
	snap(plr)
end

function Verbs.skillBuyBack(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	if not C.playerInClouds(plr) then
		net:FireClient(plr, "toast", "Buy skill points back in the Clouds")
		snap(plr)
		return
	end
	local price = Skills.BUYBACK_TOKENS or Skills.UNUSED_SKILL_POINT_SELL or 30
	if (p.temperTokens or 0) < price then
		net:FireClient(plr, "toast", string.format("A skill point costs %d tokens", price))
		return
	end
	--[[
		Same price either way: a point you sold comes back first, and once there
		are none of those left you are buying a new one outright. The only
		ceiling is a tree with nothing left to spend on.
	]]
	local bought = false
	if (p.skillBurned or 0) >= 1 then
		p.skillBurned -= 1
	else
		local cap = (Skills.maxTreePoints and Skills.maxTreePoints()) or 0
		local owned = (p.skillEarned or 0) + (p.skillBought or 0)
		if cap > 0 and owned >= cap then
			net:FireClient(plr, "toast", "Your tree is maxed -- there is nothing left to spend a point on")
			return
		end
		p.skillBought = (p.skillBought or 0) + 1
		bought = true
	end
	p.temperTokens -= price
	net:FireClient(plr, "toast", string.format(
		bought and "Bought 1 skill point: -%d tokens" or "Bought back 1 skill point: -%d tokens", price))
	markDirty(plr)
	snap(plr)
end

--[[
	A CASE, NOT A PACK.

	Bought with temper tokens (20 flat). Tokens come from rebirth and from
	selling forever tools, so the case is the main token sink. The winner is
	rolled HERE and the reel is built around it.
]]
function Verbs.openTemperCase(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local Temper = require(shared.MineTemper)
	local price = tonumber(Temper.CASE_PRICE_TOKENS) or 20
	local want = rollCount(payload)
	if (p.temperTokens or 0) < price then
		net:FireClient(plr, "toast", (Temper.CASE_NAME or "Case") .. " costs " .. price .. " tokens")
		return
	end
	local rng = Random.new()
	p.tempers = p.tempers or {}
	local done, spent, last = 0, 0, nil
	for _ = 1, want do
		if (p.temperTokens or 0) < price then break end
		local kit, rarity = Temper.rollTemperament(rng)
		if not kit then break end
		-- Charged only once the case has actually produced something.
		p.temperTokens -= price
		spent += price
		done += 1
		local had = p.tempers[kit.id]
		if had then
			had.rarity = Temper.betterGrade(had.rarity, rarity)
			had.n = (tonumber(had.n) or 1) + 1
		else
			p.tempers[kit.id] = { rarity = Temper.normalizeRarity(rarity), n = 1 }
		end
		local reel, at = Temper.caseReel(rng, kit, rarity)
		last = { kit = kit, rarity = rarity, reel = reel, at = at, dupe = had ~= nil }
	end
	if done == 0 then
		net:FireClient(plr, "toast", "That case came up empty -- nothing was charged")
		return
	end
	if math.floor(tonumber(p.intro) or 0) == 36 then
		p.introTemperRolls = (p.introTemperRolls or 0) + done
		if p.introTemperRolls >= 5 then
			introAdvance(plr, p, 36)
		else
			introSend(plr, p)
		end
	end
	-- One reel however many were bought. A hundred back-to-back ceremonies is
	-- not a reward -- same shape the 3-for-50 bundle already uses.
	net:FireClient(plr, "temperCase", {
		reel = last.reel, at = last.at, id = last.kit.id, name = last.kit.name,
		rarity = Temper.normalizeRarity(last.rarity), word = Temper.wordOf(last.rarity),
		dupe = last.dupe,
		bundle = (done > 1) and done or nil,
	})
	if done > 1 then
		net:FireClient(plr, "toast", string.format("Opened %d cases (-%d tokens)", done, spent))
	end
	if done < want then
		net:FireClient(plr, "toast", string.format("Ran out of tokens after %d of %d", done, want))
	end
	introAdvance(plr, p, 16)
	markDirty(plr)
	snap(plr)
end

-- 3 cases for 50 tokens (vs 60 at singles). Shown once after first rebirth.
function Verbs.openTemperCaseBundle(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local Temper = require(shared.MineTemper)
	local n = tonumber(Temper.CASE_BUNDLE_COUNT) or 3
	local price = tonumber(Temper.CASE_BUNDLE_TOKENS) or 50
	if (p.prestige or 0) < 1 then
		net:FireClient(plr, "toast", "Rebirth once to unlock the case bundle")
		return
	end
	if (p.temperTokens or 0) < price then
		net:FireClient(plr, "toast", string.format("Need %d tokens for %d cases", price, n))
		return
	end
	p.temperTokens -= price
	p.tempers = p.tempers or {}
	local last
	for _ = 1, n do
		local rng = Random.new()
		local kit, rarity = Temper.rollTemperament(rng)
		if kit then
			local had = p.tempers[kit.id]
			if had then
				had.rarity = Temper.betterGrade(had.rarity, rarity)
				had.n = (tonumber(had.n) or 1) + 1
			else
				p.tempers[kit.id] = { rarity = Temper.normalizeRarity(rarity), n = 1 }
			end
			local reel, at = Temper.caseReel(rng, kit, rarity)
			last = { kit = kit, rarity = rarity, reel = reel, at = at }
		end
	end
	if last then
		net:FireClient(plr, "temperCase", {
			reel = last.reel, at = last.at, id = last.kit.id, name = last.kit.name,
			rarity = Temper.normalizeRarity(last.rarity), word = Temper.wordOf(last.rarity),
			bundle = n,
		})
	end
	net:FireClient(plr, "toast", string.format("Opened %d cases (-%d tokens)", n, price))
	markDirty(plr)
	snap(plr)
end

function Verbs.scrapTemper(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(payload) ~= "table" then
		return
	end
	local Temper = require(shared.MineTemper)
	local id = tostring(payload.id or payload.temperId or "")
	local owned = (p.tempers or {})[id]
	if not owned then
		net:FireClient(plr, "toast", "You do not own that temperament")
		return
	end
	local pay = Temper.scrapTokens(owned.rarity)
	local n = math.max(1, math.floor(tonumber(owned.n) or 1))
	if n > 1 then
		owned.n = n - 1
	else
		p.tempers[id] = nil
		-- Unequip anywhere it was fitted.
		for _, fam in ipairs({ "pickaxe", "drill", "explosive" }) do
			local row = (p.toolTempers or {})[fam]
			if row then
				if row.temperId == id then row.temperId, row.temperRarity = nil, nil end
				if type(row.tempers) == "table" then
					for si, slot in ipairs(row.tempers) do
						if slot and slot.id == id then row.tempers[si] = nil end
					end
				end
			end
		end
		for _, row in ipairs(p.chestTools or {}) do
			if type(row) == "table" then
				if row.temperId == id then row.temperId, row.temperRarity = nil, nil end
				if type(row.tempers) == "table" then
					for si, slot in ipairs(row.tempers) do
						if slot and slot.id == id then row.tempers[si] = nil end
					end
				end
			end
		end
	end
	p.temperTokens = (p.temperTokens or 0) + pay
	net:FireClient(plr, "toast", string.format("Scrapped for %d tokens", pay))
	markDirty(plr)
	snap(plr)
end

-- Fit one you own onto a tool family or a flagship. Free: the case was the
-- cost, and a temperament you own is yours to move between tools.
function Verbs.equipTemper(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(payload) ~= "table" then
		return
	end
	local Temper = require(shared.MineTemper)
	local id = tostring(payload.id or payload.temperId or "")
	local owned = (p.tempers or {})[id]
	local kit = Temper.kit(id)
	if not (owned and kit) then
		net:FireClient(plr, "toast", "You do not own that temperament")
		return
	end
	local target
	local family = payload.family
	if family then
		if family ~= "pickaxe" and family ~= "drill" and family ~= "explosive" then
			net:FireClient(plr, "toast", "Unknown tool family")
			return
		end
		if ((p.tools or {})[family] or 0) < 1 then
			net:FireClient(plr, "toast", "You do not own a " .. family .. " yet")
			return
		end
		p.toolTempers = p.toolTempers or {}
		p.toolTempers[family] = p.toolTempers[family] or { temperRolls = 0 }
		target = p.toolTempers[family]
	else
		local toolId = tostring(payload.toolId or "")
		for _, row in ipairs(p.chestTools or {}) do
			if type(row) == "table" and row.id == toolId then
				target = row
				break
			end
		end
		if not target then
			net:FireClient(plr, "toast", "Unknown flagship")
			return
		end
	end
	local slots = Temper.slotCount(target, Tools.chestTool(target.id or ""))
	local slot = math.clamp(math.floor(tonumber(payload.slot) or 1), 1, slots)
	target.tempers = target.tempers or {}
	if #target.tempers == 0 and target.temperId then
		target.tempers[1] = { id = target.temperId, rarity = target.temperRarity }
	end
	target.tempers[slot] = { id = id, rarity = owned.rarity }
	local primary = target.tempers[1] or { id = id, rarity = owned.rarity }
	target.temperId = primary.id
	target.temperRarity = primary.rarity
	target.temperSlots = slots
	net:FireClient(plr, "toast", Temper.wordOf(owned.rarity) .. " " .. tostring(kit.name) .. " fitted")
	introAdvance(plr, p, 16)
	markDirty(plr)
	snap(plr)
	walk(plr)
end

function Verbs.rollTemper(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	reconcileChestTools(p)
	--[[
		Two things take a temperament: a flagship, by id, or a tool FAMILY --
		pickaxe, drill, explosive. A family's temperament is stored on the family
		rather than on a rung, because rebirth resets the coin ladder and a roll
		paid for in tokens should not go with it. Rolled from the Forge or from
		the Enchanter's Temper tab; both send this.
	]]
	local family = type(payload) == "table" and payload.family or nil
	local ft
	if family then
		if family ~= "pickaxe" and family ~= "drill" and family ~= "explosive" then
			net:FireClient(plr, "toast", "Unknown tool family")
			return
		end
		if ((p.tools or {})[family] or 0) < 1 then
			net:FireClient(plr, "toast", "You do not own a " .. family .. " yet")
			return
		end
		p.toolTempers = p.toolTempers or {}
		p.toolTempers[family] = p.toolTempers[family] or { temperRolls = 0 }
		ft = p.toolTempers[family]
	else
		local toolId = type(payload) == "table" and (payload.id or payload.toolId) or payload
		toolId = tostring(toolId or "")
		for _, row in ipairs(p.chestTools or {}) do
			local rid = (type(row) == "table") and row.id or row
			if rid == toolId then
				ft = row
				break
			end
		end
		if type(ft) ~= "table" then
			net:FireClient(plr, "toast", "Unknown flagship")
			return
		end
	end
	local Temper = require(shared.MineTemper)
	--[[
		Tokens, flat, and gone for good.

		This charged the active preset's `spent` -- the field skill nodes charge
		-- so Reset refunded every roll and a temperament could be rerolled
		forever for free. Tokens are a separate balance nothing refunds.
	]]
	local cost = Skills.TEMPER_ROLL_COST or 10
	if (p.temperTokens or 0) < cost then
		net:FireClient(plr, "toast", string.format("Need %d tokens to roll temperament", cost))
		return
	end
	p.temperTokens -= cost
	local kit, rarity = Temper.rollTemperament(Random.new())
	local def = Tools.chestTool((type(ft) == "table" and ft.id) or "")
	local slots = Temper.slotCount(ft, def)
	local slot = math.clamp(math.floor(tonumber(payload and payload.slot) or 1), 1, slots)
	ft.tempers = ft.tempers or {}
	-- Migrate legacy single temper into slot 1.
	if #ft.tempers == 0 and ft.temperId then
		ft.tempers[1] = { id = ft.temperId, rarity = ft.temperRarity }
	end
	ft.tempers[slot] = { id = kit.id, rarity = rarity, paid = true }
	-- Into the collection, so it can be moved to another tool later instead of
	-- being rerolled away.
	p.tempers = p.tempers or {}
	local ownRow = p.tempers[kit.id]
	if ownRow then
		ownRow.rarity = Temper.betterGrade(ownRow.rarity, rarity)
		ownRow.n = (tonumber(ownRow.n) or 1) + 1
	else
		p.tempers[kit.id] = { rarity = Temper.normalizeRarity(rarity), n = 1 }
	end
	-- Keep legacy fields synced to slot 1 for older UI.
	local primary = ft.tempers[1] or { id = kit.id, rarity = rarity }
	ft.temperId = primary.id
	ft.temperRarity = primary.rarity
	ft.temperSlots = slots
	ft.temperRolls = (ft.temperRolls or 0) + 1
	net:FireClient(plr, "toast", string.format("Spent %d tokens on temperament (slot %d): %s %s", cost, slot, rarity, kit.name))
	introAdvance(plr, p, 16)
	markDirty(plr)
	snap(plr)
	walk(plr)
end

-- Up to the cloud deck, any time, free. The server moves the character itself,
-- so its own view of where the player stands is already the deck by the time
-- the snapshot is built.
--[[
	THE POUCH VERBS. Four: upgrade it, lock a row, sell a row, sell everything.

	Selling ore pays GEMS. It is the only gem tap in the game, against three
	sinks -- zones, runes, and the pouch's own rungs -- so the price per unit is
	the number the whole gem economy rests on. It lives in MineOrePouch, is
	derived from the work the rock cost, and is read here rather than recomputed:
	a server that prices ore differently from the panel that offered the price is
	a server that lies.
]]
function Verbs.upgradeOrePouch(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local Pouch = require(shared:WaitForChild("MineOrePouch"))
	local tier = Dig.pouchTier(p)
	local cost = Pouch.upgradeCost(tier)
	if not cost then
		net:FireClient(plr, "toast", "Your pouch is the biggest one there is")
		return
	end
	if (tonumber(p.gems) or 0) < cost then
		net:FireClient(plr, "toast", string.format("Next pouch costs %s gems",
			Verbs._benchNum(cost)))
		return
	end
	p.gems = (tonumber(p.gems) or 0) - cost
	p.orePouchTier = math.min(Pouch.MAX_TIER, tier + 1)
	local def = Pouch.tier(p.orePouchTier)
	net:FireClient(plr, "toast", string.format("%s  ·  holds %s ore",
		tostring(def and def.name or "Pouch"),
		Verbs._benchNum(Pouch.capacity(p.orePouchTier))))
	markDirty(plr)
	snap(plr)
end

--[[
	Lock or unlock one ore. A locked ore is never sold by Sell All.

	This is what lets Sell All be one button behind one confirmation instead of a
	prompt per row: the ores a player would hate to lose are the ones they
	locked, and the button cannot reach them.
]]
function Verbs.toggleOreLock(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local id = tostring((type(payload) == "table" and payload.oreId) or "")
	local ore = C.oreById(id)
	if not ore then
		net:FireClient(plr, "toast", "That ore is not in the roster")
		return
	end
	p.oreLocks = p.oreLocks or {}
	if p.oreLocks[id] then
		p.oreLocks[id] = nil
		net:FireClient(plr, "toast", (ore.name or id) .. " unlocked")
	else
		p.oreLocks[id] = true
		net:FireClient(plr, "toast", (ore.name or id) .. " locked -- Sell All will skip it")
	end
	markDirty(plr)
	snap(plr)
end

--[[
	Sell one ore. `count` sells that many, or everything of it when absent.

	A LOCKED ORE STILL SELLS HERE. The lock guards the bulk button, not the row:
	a player tapping one row and naming an amount has said exactly what they
	mean, and refusing them would make the lock a thing to undo rather than a
	safety net.
]]
function Verbs.sellOre(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local Pouch = require(shared:WaitForChild("MineOrePouch"))
	local id = tostring((type(payload) == "table" and payload.oreId) or "")
	local ore = C.oreById(id)
	if not ore then
		net:FireClient(plr, "toast", "That ore is not in the roster")
		return
	end
	p.ores = p.ores or {}
	local have = math.max(0, math.floor(tonumber(p.ores[id]) or 0))
	if have <= 0 then
		net:FireClient(plr, "toast", "You have none of that")
		return
	end
	local want = math.floor(tonumber(type(payload) == "table" and payload.count) or have)
	want = math.clamp(want, 1, have)
	local gems = Pouch.stackValue(ore, want)
	p.ores[id] = have - want
	if p.ores[id] <= 0 then
		p.ores[id] = nil
	end
	p.gems = (tonumber(p.gems) or 0) + gems
	net:FireClient(plr, "toast", string.format("Sold %s %s  +%s gems",
		Verbs._benchNum(want), tostring(ore.name or id), Verbs._benchNum(gems)))
	markDirty(plr)
	snap(plr)
end

--[[
	SELL ALL, behind a confirmation.

	Two calls, not one. Without `confirm` the server prices the sale and sends
	the numbers back for the panel to show; with it, the sale happens. The plan
	is built by the same MineOrePouch.sellAllPlan both times, so the figure a
	player agreed to is the figure they are paid -- rather than a client-side
	estimate the server then quietly disagrees with.

	Locked ores are excluded by the plan itself, so there is no path through here
	that can sell one.
]]
function Verbs.sellAllOres(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local Pouch = require(shared:WaitForChild("MineOrePouch"))
	p.ores = p.ores or {}
	p.oreLocks = p.oreLocks or {}
	local plan = Pouch.sellAllPlan(p.ores, p.oreLocks)
	if plan.units <= 0 then
		local anyLocked = next(p.oreLocks) ~= nil
		net:FireClient(plr, "toast", anyLocked
			and "Nothing to sell -- everything you hold is locked"
			or "Your pouch is empty")
		return
	end
	if not (type(payload) == "table" and payload.confirm) then
		-- Ask first. The panel shows these numbers and sends the same verb back
		-- with confirm = true.
		net:FireClient(plr, "confirmSellAll", {
			units = plan.units,
			gems = plan.gems,
			rows = #plan.rows,
			locked = (function()
				local n = 0
				for _ in pairs(p.oreLocks) do
					n += 1
				end
				return n
			end)(),
		})
		return
	end
	for _, row in ipairs(plan.rows) do
		p.ores[row.id] = nil
	end
	p.gems = (tonumber(p.gems) or 0) + plan.gems
	net:FireClient(plr, "toast", string.format("Sold %s ore  +%s gems",
		Verbs._benchNum(plan.units), Verbs._benchNum(plan.gems)))
	markDirty(plr)
	save(plr)
	snap(plr)
end

function Verbs.goClouds(plr)
	tp(plr, cloudCf())
	snap(plr)
end

--------------------------------------------------------------------------------
-- AFK chill pad: park idle miners, chip one endless block, snap them back if
-- they wander. Luck + chestLuck raise pack odds / quality; pick tier cuts the
-- wait from ~30s (starter) down to ~10s (endgame).
--------------------------------------------------------------------------------
-- AFK helpers live on one table so they do not each burn a main-chunk local
-- register (Luau's 200-local ceiling).
Verbs.Afk = {}
Verbs.Afk.active = {} -- [userId] = true
Verbs.Afk.nextAt = {} -- [userId] = os.clock()
Verbs.Afk.refreshAt = {} -- [userId] = os.clock() when to same-place teleport
Verbs.Afk.ignoreUntil = {}
Verbs.Afk.moveCon = {}
Verbs.Afk.jumpCon = {}

function Verbs.Afk.clearWatch(uid)
	local c = Verbs.Afk.moveCon[uid]
	if c then
		c:Disconnect()
	end
	Verbs.Afk.moveCon[uid] = nil
	c = Verbs.Afk.jumpCon[uid]
	if c then
		c:Disconnect()
	end
	Verbs.Afk.jumpCon[uid] = nil
end

function Verbs.Afk.bindMove(plr)
	local uid = plr.UserId
	Verbs.Afk.clearWatch(uid)
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	Verbs.Afk.ignoreUntil[uid] = os.clock() + 2.5
	local function snapBack()
		if not Verbs.Afk.active[uid] then
			return
		end
		if os.clock() < (Verbs.Afk.ignoreUntil[uid] or 0) then
			return
		end
		Verbs.Afk.ignoreUntil[uid] = os.clock() + 0.6
		Verbs.Afk.stop(plr, "moved")
	end
	Verbs.Afk.moveCon[uid] = hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if hum.MoveDirection.Magnitude > 0.35 then
			snapBack()
		end
	end)
	Verbs.Afk.jumpCon[uid] = hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			snapBack()
		end
	end)
end

function Verbs.Afk.sit(plr)
	pcall(function()
		Dig.Auth.allowTpUser(plr.UserId, 2.5)
	end)
	--[[
		GOING AFK DOES NOT MOVE YOU.

		This used to haul the player off to the AfkChill pad. The pad does
		nothing the loop needs -- mineTick pays out on a timer and the endless
		block is refreshed by attribute, neither of which cares where anybody is
		standing -- so all it ever did was take you away from wherever you chose
		to stop. Settle them in place instead.
	]]
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	if hum then
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
	Verbs.Afk.ignoreUntil[plr.UserId] = os.clock() + 2.5
end

function Verbs.Afk.padCf()
	local world = workspace:FindFirstChild("MineWorld")
	local chill = world and world:FindFirstChild("AfkChill")
	local spawn = chill and chill:FindFirstChild("Spawn")
	local blk = chill and chill:FindFirstChild("MineBlock")
	local deck = chill and chill:FindFirstChild("Deck")
	local standY = nil
	if deck then
		standY = deck.Position.Y + deck.Size.Y * 0.5 + 3
	elseif spawn then
		standY = spawn.Position.Y + 3
	end
	if spawn and blk and standY then
		local pos = Vector3.new(spawn.Position.X, standY, spawn.Position.Z)
		return CFrame.lookAt(pos, Vector3.new(blk.Position.X, pos.Y, blk.Position.Z))
	end
	if spawn then
		local pos = spawn.Position + Vector3.new(0, 3, 0)
		return spawn.CFrame - spawn.Position + pos
	end
	local pad = C.AFK_PAD or Vector3.new(36, 6, 36)
	-- Default lounge faces +Z where the endless block sits when we build the pad.
	return CFrame.lookAt(pad + Vector3.new(0, 3, -4), pad + Vector3.new(0, 3, 5))
end

function Verbs.Afk.block()
	local world = workspace:FindFirstChild("MineWorld")
	local chill = world and world:FindFirstChild("AfkChill")
	return chill and chill:FindFirstChild("MineBlock")
end

function Verbs.Afk.intervalSec(p)
	local picks = Tools.TOOLS.pickaxe or {}
	local maxT = math.max(2, #picks)
	local tool = equippedTool(p)
	local tier = 1
	if tool and tool.tier then
		tier = tool.tier
	elseif p.tools and p.tools.pickaxe then
		tier = p.tools.pickaxe
	else
		tier = p.pickaxeTier or 1
	end
	tier = math.clamp(math.floor(tier), 1, maxT)
	local lo = C.AFK_SEC_STARTER or 30
	local hi = C.AFK_SEC_ENDGAME or 10
	local sec = lo - ((tier - 1) / (maxT - 1)) * (lo - hi)
	local b = boosts(p)
	sec = sec / math.max(0.5, b.mineSpeed or 1)
	return math.clamp(sec, hi * 0.85, lo + 5)
end

function Verbs.Afk.grantPack(plr, p, b)
	local ZonePacks = require(shared:WaitForChild("MineZonePacks"))
	local idx = math.clamp(tonumber(p.maxUnlockedZone) or 1, 1, #C.ZONES)
	--[[
		WHICH ZONE'S PACK THIS IS.

		AFK paid the deepest unlocked zone every single time, so the reward was a
		flat stream of one pack and there was no reason to care that the zones
		behind you existed at all.

		One in five now comes from your top zone; the other four come from below
		it, weighted by depth (w = i) so the zone you just cleared is the
		likeliest of them and Meadow the rarest. A Primordium player gets a
		spread of their whole run rather than drowning in starter packs.
	]]
	local rng = Random.new()
	if idx > 1 and rng:NextNumber() >= Const.AFK_TOP_ZONE_SHARE then
		local total = 0
		for i = 1, idx - 1 do
			total += i
		end
		local r = rng:NextNumber() * total
		local acc = 0
		for i = 1, idx - 1 do
			acc += i
			if r <= acc then
				idx = i
				break
			end
		end
	end
	local zone = C.ZONES[idx]
	if not zone then
		return nil
	end
	local cl = math.max(0.01, b.chestLuck or 1)
	-- Higher chestLuck skews the slot toward rare / legendary.
	local wCommon, wRare, wLeg = 70, 22 * cl, 8 * cl
	local total = wCommon + wRare + wLeg
	local roll = Random.new():NextNumber() * total
	local slot = "pack_common"
	if roll > wCommon + wRare then
		slot = "pack_legendary"
	elseif roll > wCommon then
		slot = "pack_rare"
	end
	local packId = ZonePacks.id(zone.id, slot)
	local zpack = ZonePacks.get(packId)
	local setId = (zone.sets and zone.sets[1]) or "dragons_dawn"
	local row = {
		kind = "afk",
		packId = packId,
		packName = (zpack and zpack.name) or packId,
		zoneId = zone.id,
		setId = setId,
	}
	-- PACK luck, same as every other row.luck stamp.
	local stamped = math.max(1, Dig.packLuck(b))
	if stamped > 1 then
		row.luck = stamped
	end
	p.packs = p.packs or {}
	table.insert(p.packs, row)
	return row
end

function Verbs.Afk.coinsFor(p, b)
	-- Coins, plus a small VIP gem drip on the tick itself.
	local zoneN = math.max(1, math.floor(tonumber(p.maxUnlockedZone) or 1))
	local pick = math.max(1, math.floor(tonumber(p.pickaxeTier) or 1))
	local base = (C.AFK_COINS_BASE or 8)
		+ (zoneN - 1) * (C.AFK_COINS_PER_ZONE or 4)
		+ (pick - 1) * (C.AFK_COINS_PER_PICK or 3)
	b = b or {}
	local petMul = 1 + math.clamp(((b.luck or 1) - 1) * 0.5 + ((b.chestLuck or 1) - 1) * 0.35, 0, 1.5)
	local coins = math.floor(base * petMul)
	if p.vipPass then
		coins = math.floor(coins * (C.VIP_AFK_MULT or 1.50))
	end
	if p.coinDouble then
		coins *= 2
	end
	return coins
end

function Verbs.Afk.mineTick(plr)
	local p = profiles[plr.UserId]
	if not p or not Verbs.Afk.active[plr.UserId] then
		return
	end
	local b = boosts(p)
	local coins = Verbs.Afk.coinsFor(p, b)
	if p.zoneId == "bigbang" then
		if not (p.eventTools and p.eventToolId and p.eventTools[p.eventToolId]) then
			return
		end
		p.spaceCoins = (p.spaceCoins or 0) + coins
	else
		p.coins = (p.coins or 0) + coins
	end
	if p.vipPass then
		p.gems = (p.gems or 0) + math.max(0, math.floor(tonumber(C.VIP_AFK_GEMS) or 1))
	end
	bumpStat(plr, p, "blocks")

	local blk = Verbs.Afk.block()
	if blk then
		local maxHp = blk:GetAttribute("MaxHP") or 30
		blk:SetAttribute("HP", maxHp) -- pop + refresh (endless)
	end

	local petMul = 1 + math.clamp(((b.luck or 1) - 1) * 0.5 + ((b.chestLuck or 1) - 1) * 0.35, 0, 1.5)
	local chance = (C.AFK_PACK_BASE or (1 / 45)) * (b.luck or 1) * (b.chestLuck or 1) * petMul
	chance = math.min(C.AFK_PACK_CAP or 0.18, chance)
	local gotPack = nil
	if Random.new():NextNumber() < chance then
		gotPack = Verbs.Afk.grantPack(plr, p, b)
	end

	markDirty(plr)
	snap(plr)
	net:FireClient(plr, "afkMine", {
		coins = coins,
		interval = Verbs.Afk.intervalSec(p),
		pack = gotPack and (gotPack.packName or gotPack.packId) or nil,
		chance = chance,
	})
	if gotPack then
		net:FireClient(plr, "toast", "AFK pack: " .. tostring(gotPack.packName or gotPack.packId))
	end
end

function Verbs.Afk.stop(plr, reason)
	local uid = plr.UserId
	if not Verbs.Afk.active[uid] then
		return
	end
	Verbs.Afk.active[uid] = nil
	Verbs.Afk.nextAt[uid] = nil
	Verbs.Afk.refreshAt[uid] = nil
	Verbs.Afk.ignoreUntil[uid] = nil
	Verbs.Afk.clearWatch(uid)
	local p = profiles[uid]
	if p then
		p.afk = false
		markDirty(plr)
	end
	net:FireClient(plr, "afk", { active = false, reason = reason })
	-- Waking does not move you either. There is no pad to leave any more, so
	-- sending them to lobby spawn would be the teleport we just removed, only
	-- on the way out instead of the way in.
	if reason == "wake" or reason == "moved" then
		net:FireClient(plr, "toast", "You're back.")
	end
end

function Verbs.Afk.refreshSession(plr)
	-- Soft reset of Roblox's client idle clock: leave and rejoin the same place
	-- while staying AFK. Profile.afk is already true and will resume on boot.
	-- Teleports cannot work in Studio; skip instead of erroring every refresh.
	if Svc.Run:IsStudio() then
		return
	end
	local p = profiles[plr.UserId]
	if not p or not Verbs.Afk.active[plr.UserId] then
		return
	end
	p.afk = true
	--[[
		Remember exactly where they are standing so the hop can put them back.
		The keep-alive teleport is meant to be invisible: going AFK at the
		bottom of a pit and coming back at the lobby spawn is the same as being
		moved, which is the one thing AFK must never do.

		Stored as four plain numbers -- a CFrame is not a DataStore value.
	]]
	do
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local cf = root.CFrame
			local _, yaw = cf:ToEulerAnglesYXZ()
			p.afkAt = { cf.X, cf.Y, cf.Z, yaw }
		end
	end
	markDirty(plr)
	pcall(save, plr)
	-- Drop the in-server AFK loop so a failed teleport does not double-tick;
	-- on successful rejoin, profile.afk + mineAfkResume restart chill.
	Verbs.Afk.active[plr.UserId] = nil
	Verbs.Afk.nextAt[plr.UserId] = nil
	Verbs.Afk.refreshAt[plr.UserId] = nil

	local function attempt(opts)
		local ok, err = pcall(function()
			Svc.Teleport:TeleportAsync(game.PlaceId, { plr }, opts)
		end)
		if ok then
			return true
		end
		warn("[Mine] AFK refresh teleport failed", err)
		local ok2 = pcall(function()
			Svc.Teleport:Teleport(game.PlaceId, plr, { mineAfkResume = true })
		end)
		return ok2
	end

	local opts = Instance.new("TeleportOptions")
	-- Prefer the same server so the chill pad / session feel continuous.
	pcall(function()
		opts.ServerInstanceId = game.JobId
	end)
	opts:SetTeleportData({ mineAfkResume = true })
	if not attempt(opts) then
		-- Same-server teleport can fail on dying servers; retry any server.
		local fallback = Instance.new("TeleportOptions")
		fallback:SetTeleportData({ mineAfkResume = true })
		if not attempt(fallback) then
			-- Stay AFK in-place and try again soon rather than leaving them to the kick.
			Verbs.Afk.active[plr.UserId] = true
			Verbs.Afk.nextAt[plr.UserId] = os.clock() + Verbs.Afk.intervalSec(p)
			Verbs.Afk.refreshAt[plr.UserId] = os.clock() + 60
			net:FireClient(plr, "toast", "AFK keep-alive teleport failed — retrying…")
		end
	end
end

function Verbs.Afk.start(plr)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	if Verbs.Afk.active[plr.UserId] then
		Verbs.Afk.sit(plr)
		Verbs.Afk.bindMove(plr)
		return
	end
	Verbs.Afk.active[plr.UserId] = true
	p.afk = true
	Verbs.Afk.sit(plr)
	local waitSec = Verbs.Afk.intervalSec(p)
	Verbs.Afk.nextAt[plr.UserId] = os.clock() + waitSec
	Verbs.Afk.refreshAt[plr.UserId] = os.clock() + (C.AFK_REFRESH_SEC or (10 * 60))
	net:FireClient(plr, "afk", {
		active = true,
		interval = waitSec,
		coins = Verbs.Afk.coinsFor(p),
		packBase = C.AFK_PACK_BASE or (1 / 120),
	})
	net:FireClient(plr, "toast", "AFK chill — mining slowly. Wake from the HUD when you are back.")
	Verbs.Afk.bindMove(plr)
end

task.spawn(function()
	while true do
		task.wait(0.35)
		local now = os.clock()
		-- Re-enter chill after refresh teleport / reconnect while profile.afk is set.
		for uid, p in pairs(profiles) do
			if p and p.afk and not Verbs.Afk.active[uid] then
				if Svc.Run:IsStudio() then
					p.afk = false
				else
					local plr = Svc.Players:GetPlayerByUserId(uid)
					if plr and plr.Character then
						Verbs.Afk.start(plr)
					end
				end
			end
		end
		for uid, _ in pairs(Verbs.Afk.active) do
			local plr = Svc.Players:GetPlayerByUserId(uid)
			if not plr or not profiles[uid] then
				Verbs.Afk.active[uid] = nil
				Verbs.Afk.nextAt[uid] = nil
				Verbs.Afk.refreshAt[uid] = nil
				Verbs.Afk.ignoreUntil[uid] = nil
				Verbs.Afk.clearWatch(uid)
			else
				local watch = Verbs.Afk.moveCon[uid]
				if not watch or not watch.Connected then
					Verbs.Afk.bindMove(plr)
				end
				if now >= (Verbs.Afk.nextAt[uid] or 0) then
					Verbs.Afk.mineTick(plr)
					Verbs.Afk.nextAt[uid] = now + Verbs.Afk.intervalSec(profiles[uid])
				end
				if now >= (Verbs.Afk.refreshAt[uid] or math.huge) then
					Verbs.Afk.refreshAt[uid] = now + (C.AFK_REFRESH_SEC or (10 * 60))
					task.spawn(Verbs.Afk.refreshSession, plr)
				end
			end
		end
	end
end)


--[[
	THE BLACKSMITH BENCH.

	Ore tools level on their own 1..TOOL_MAX_LEVEL scale, paid for in ore and
	stardust. MineConfig owns the pricing so the bench, the recycler and the UI
	cannot drift apart: toolUpgradeCost for one step, toolSpent for everything
	poured in, toolRecycle for what comes back.

	Every entry point takes a UID. Not an index -- the bag reorders whenever a
	tool is found or scrapped, and an index captured when the panel was drawn
	names a different tool by the time the button is pressed. Packs already
	learned this; the comment on openAt says so.

	The uid never changes here. Upgrading mutates `level` and nothing else, so
	a tool is the same object at level 900 that it was at level 1.
]]
function Verbs._findOreTool(p, uid)
	if type(uid) ~= "string" or uid == "" then
		return nil, nil
	end
	for i, t in ipairs(p.oreTools or {}) do
		if type(t) == "table" and t.uid == uid then
			return t, i
		end
	end
	return nil, nil
end

--[[
	Every number the server quotes a player, in one place.

	It used to format its own: "%.1fK", "%.1fM", then "%.2e" past a billion.
	Three problems, all of which matter when the number is a price. It ROUNDED
	("%.1f" on 1.99M reads 2.0M, so a quote could exceed what is charged, which
	currencies must never do), it showed two or three significant figures where
	the rule is four, and its suffixes ran out at a billion -- and ore values at
	depth pass a billion well before the end of the ladder.

	MineAbbrev.currency floors, shows four, and carries suffixes the whole way,
	so the server and the client read a price identically.
]]
--[[
	The one number -> string the SERVER uses for anything a player reads.

	It is MineBigNum now, which is what TODO 0.8 always said it should be:
	"big numbers are SERVER-SIDE", and this is where the server turns one into
	text. It used to call MineAbbrev.currency, the client-side formatter, which
	left MineBigNum with no callers at all.

	THE SWAP IS INVISIBLE, and that is the point rather than a happy accident.
	The two produce byte-identical output for every magnitude below 10^63 --
	pinned by tools/verify/bignum.js, which also records where they part company
	above it. Getting there needed a real fix: MineBigNum floored to one decimal
	flat, so 1234 read "1.2 K", two significant figures against the four its own
	header and 0.8/0.9 all call for.

	MineAbbrev stays where it is. It is in ReplicatedStorage because the client
	needs a formatter for numbers it works out itself (a preview, a running
	total), and MineBigNum is deliberately server-only. The guarantee that
	matters is not that the client never formats -- it is that when it does, it
	cannot disagree with the server, and that is now a checked property.
]]
function Verbs._benchNum(n)
	return require(script.Parent:WaitForChild("MineBigNum")).auto(n)
end

--[[
	The ore an ore tool is made of is the ore it eats to level. Anything else
	would let a player bank one cheap ore and level every tool they own with it.

	typeMult comes from the tool's RARITY RANK, not a weight field -- tool defs
	carry a rarity, and MineTools.RARITY_RANK turns that into 1 for Common up
	to 8 for Exotic. toolCostMult raises it to TOOL_COST_TYPE (0.5), so a rarer
	frame costs about 2.8x a Common one to level, never less.
]]
-- One rule, in MineOreTools. This was a third copy of the frame-rarity lookup
-- (MineForge had one, equippedTool has another), and all three computed the
-- same function of ore tier by different routes. See MineOreTools.typeMult.
function Verbs._oreToolTypeMult(tool)
	-- Required here, not at the top: this script is on Luau's 200-local ceiling,
	-- and `OreTools` is a local inside two other functions rather than a file
	-- global. Writing the bare name would compile to a GLOBAL read and be nil.
	local OreTools = require(shared:WaitForChild("MineOreTools"))
	return OreTools.typeMult(tool.familyId or "pickaxe", tool.tier)
end

function Verbs._oreToolCost(tool)
	local oreDef = C.ORES and C.ORES[tonumber(tool.tier) or 1]
	local typeMult = Verbs._oreToolTypeMult(tool)
	local level = math.max(1, tonumber(tool.level) or 1)
	local ore, dust = C.toolUpgradeCost(tool.tier, level, typeMult)
	return ore, dust, oreDef, typeMult
end

function Verbs.upgradeOreTool(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local uid = (type(payload) == "table") and payload.uid or payload
	local tool = Verbs._findOreTool(p, uid)
	if not tool then
		net:FireClient(plr, "toast", "That tool is not in your bag")
		return
	end
	local level = math.max(1, tonumber(tool.level) or 1)

	-- The wooden pickaxe levels on coins and has its own, much lower cap. It
	-- is the free starter: charging ore for the tool whose job is to win you
	-- your first ore would deadlock a new save.
	if C.isCoinTool and C.isCoinTool(tool) then
		Verbs._upgradeCoinTool(plr, p, tool, level, payload)
		return
	end

	if level >= C.TOOL_MAX_LEVEL then
		net:FireClient(plr, "toast", "That tool is at max level")
		return
	end

	local ore, dust, oreDef = Verbs._oreToolCost(tool)
	if not ore or not dust then
		net:FireClient(plr, "toast", "That tool cannot be levelled")
		return
	end
	local oreId = oreDef and oreDef.id
	if not oreId then
		net:FireClient(plr, "toast", "That tool has no ore")
		return
	end

	-- How many steps the player can actually afford, capped by the request and
	-- by the level ceiling. `count` lets the panel offer +1 / +10 / max without
	-- a round trip per level.
	local want = math.floor(tonumber(type(payload) == "table" and payload.count) or 1)
	want = math.clamp(want, 1, C.TOOL_MAX_LEVEL - level)

	p.ores = p.ores or {}
	local haveOre = tonumber(p.ores[oreId]) or 0
	local haveDust = tonumber(p.dust) or 0
	local typeMult = Verbs._oreToolTypeMult(tool)
	local spentOre, spentDust, steps = 0, 0, 0
	for i = 0, want - 1 do
		local o, d = C.toolUpgradeCost(tool.tier, level + i, typeMult)
		if not o then break end
		if haveOre - spentOre < o or haveDust - spentDust < d then break end
		spentOre += o
		spentDust += d
		steps += 1
	end

	if steps == 0 then
		net:FireClient(plr, "toast", string.format(
			"Needs %s %s and %s stardust",
			Verbs._benchNum(ore),
			(oreDef and oreDef.name) or oreId,
			Verbs._benchNum(dust)))
		return
	end

	p.ores[oreId] = haveOre - spentOre
	p.dust = haveDust - spentDust
	tool.level = level + steps          -- the uid is untouched, on purpose
	bumpStat(plr, p, "upgrades")
	net:FireClient(plr, "toast", string.format("+%d  ->  level %d", steps, tool.level))
	snap(plr)
	markDirty(plr)
end

--[[
	The wooden pickaxe's coin ladder.

	Same shape as the ore path -- walk the steps the player can actually afford,
	capped by the request and by the ceiling -- so +1 / +10 / MAX cost one round
	trip rather than one per level. Prices come from MineConfig.woodPickCoinCost
	and nowhere else.
]]
--[[
	GRADUATION. The wooden pickaxe exists to reach the stone pick (TODO 0.10),
	and this is the handover.

	`C.TUTORIAL_GRADUATION_TOOL` has existed as a constant with no reader, so
	the rule was written down and never implemented: the wooden pick capped at
	five levels and the player was simply stuck on it, holding a tool that
	could not improve and had not bought them anything.

	It hands over a COIN-LADDER rung (Tools.TOOLS.pickaxe), which is a different
	roster from the Forge tool being levelled -- that is the point. The wooden
	pick is a Forge tool with typeId wood_pick; the stone pick is rung 2 of the
	shop ladder. p.tools.pickaxe is a highest-rung marker rather than a list of
	receipts, so setting it grants that rung and everything under it, exactly as
	buyTool does when someone buys ahead.

	Free, and only once: it no-ops if the player already owns that rung or
	better, so a player who bought their way past it is not handed anything and
	nobody can re-trigger it.

	Returns true when it actually granted, so the caller can say so.
]]
function Verbs._graduateTutorialPick(plr, p)
	local id = C.TUTORIAL_GRADUATION_TOOL
	if type(id) ~= "string" or id == "" then
		return false
	end
	local list = Tools.TOOLS and Tools.TOOLS.pickaxe
	if type(list) ~= "table" then
		return false
	end
	local tier, row
	for i, r in ipairs(list) do
		if r.id == id then
			tier, row = i, r
			break
		end
	end
	if not tier then
		return false
	end
	p.tools = p.tools or {}
	if (tonumber(p.tools.pickaxe) or 0) >= tier then
		return false
	end
	p.tools.pickaxe = tier
	net:FireClient(plr, "toast", string.format(
		"The %s is yours -- the Wooden Pickaxe has done its job", tostring(row.name or id)))
	return true
end

function Verbs._upgradeCoinTool(plr, p, tool, level, payload)
	if level >= C.WOOD_PICK_MAX_LEVEL then
		-- At the cap and still on the starter: hand the graduation tool over
		-- rather than repeating "at max level" at someone with nowhere to go.
		if Verbs._graduateTutorialPick(plr, p) then
			snap(plr)
			markDirty(plr)
			return
		end
		net:FireClient(plr, "toast", "The Wooden Pickaxe is at max level")
		return
	end

	local want = math.floor(tonumber(type(payload) == "table" and payload.count) or 1)
	want = math.clamp(want, 1, C.WOOD_PICK_MAX_LEVEL - level)

	local haveCoins = tonumber(p.coins) or 0
	local spent, steps = 0, 0
	for i = 0, want - 1 do
		local c = C.woodPickCoinCost(level + i)
		if not c then break end
		if haveCoins - spent < c then break end
		spent += c
		steps += 1
	end

	if steps == 0 then
		net:FireClient(plr, "toast", string.format("Needs %s coins",
			Verbs._benchNum(C.woodPickCoinCost(level) or 0)))
		return
	end

	p.coins = haveCoins - spent
	tool.level = level + steps          -- the uid is untouched, on purpose
	bumpStat(plr, p, "upgrades")
	net:FireClient(plr, "toast", string.format("+%d  ->  level %d", steps, tool.level))
	-- Reaching the cap IS the graduation, so it happens on the step that gets
	-- there rather than on a second click the player has no reason to make.
	if tool.level >= C.WOOD_PICK_MAX_LEVEL then
		Verbs._graduateTutorialPick(plr, p)
	end
	snap(plr)
	markDirty(plr)
end

--[[
	FORGE: build a tool out of ore.

	payload = { familyId = "pickaxe", typeId = "iron_pick", oreId = "halite" }

	Everything is re-derived here from the roster and MineConfig. The client
	sends three ids and nothing else -- no cost, no tier, no level -- so a
	modified client can pick a different recipe but can never pick a different
	price, and can never mint a tool out of an ore it does not hold.

	The tool is minted at level 1 carrying the ORE's tier, because tier is what
	the whole level curve and the ore-it-eats lookup key off (_oreToolCost reads
	C.ORES[tool.tier]). A tool forged from Halite levels on Halite.
]]
--[[
	Equip an ore tool, or put it away.

	uid-keyed like the rest of the bench: a row index names a different tool the
	moment the list reorders. An empty uid unequips, which is how a player gets
	back to their ladder pickaxe without scrapping anything.

	One object claims the hand at a time. A chest flagship and a fossil tool are
	both cleared here, because equippedTool checks the ore tool FIRST and would
	otherwise silently mask a flagship the player thinks they are holding.
]]
function Verbs.equipOreTool(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local uid = (type(payload) == "table") and payload.uid or payload
	uid = tostring(uid or "")
	if uid == "" then
		p.oreToolEquipped = nil
		givePickaxe(plr)
		markDirty(plr)
		snap(plr)
		return
	end
	local tool = Verbs._findOreTool(p, uid)
	if not tool then
		net:FireClient(plr, "toast", "That tool is not in your bag")
		return
	end

	p.oreToolEquipped = tool.uid
	p.chestTool = nil
	p.shopToolId = nil
	p.toolFamily = tool.familyId or "pickaxe"

	givePickaxe(plr)
	local oreDef = C.ORES and C.ORES[tonumber(tool.tier) or 1]
	net:FireClient(plr, "toast", string.format("Equipped  %s  (breaking power %d)",
		(oreDef and oreDef.name) or ("Tier " .. tostring(tool.tier)),
		C.toolBreakingPower(tool)))
	snap(plr)
	markDirty(plr)
end

function Verbs.craftOreTool(plr, payload)
	local p = profiles[plr.UserId]
	if not p or type(payload) ~= "table" then
		return
	end

	local familyId = tostring(payload.familyId or "pickaxe")
	local oreId = tostring(payload.oreId or "")

	--[[
		THE ORE IS THE TOOL.

		Owner, 2026-10-03: "i dont want different tools to cost different ores."

		This verb used to take a typeId AND an oreId from the client and trust
		the pair, so one frame could be forged out of any ore at any price --
		which is exactly what made the Forge read as nonsense. The frame is
		DERIVED from the ore's tier now, by the same pure function the panel
		quotes with, so the two cannot drift and a modified client cannot ask
		for a deep ore in a cheap frame. payload.typeId is ignored on purpose.

		MineOreTools is required here rather than at the top of the file: this
		script is at 197 of Luau's 200 top-level locals, and a forge is not a
		hot path.
	]]
	local oreDef = C.oreById and C.oreById(oreId)
	if not oreDef or not oreDef.tier then
		net:FireClient(plr, "toast", "That ore is not in the roster")
		return
	end

	local OreTools = require(shared:WaitForChild("MineOreTools"))
	local def = OreTools.frameForTier(familyId, oreDef.tier)
	if not def then
		net:FireClient(plr, "toast", "Nothing in that family can be forged")
		return
	end

	-- The starter is given, not forged. frameForTier already filters it out by
	-- price, so this is belt and braces rather than the only guard.
	if C.WOOD_PICK_ID and def.id == C.WOOD_PICK_ID then
		net:FireClient(plr, "toast", "The Wooden Pickaxe is free, not forged")
		return
	end

	p.oreTools = p.oreTools or {}
	if #p.oreTools >= 200 then
		net:FireClient(plr, "toast", "Your tool rack is full - scrap something first")
		return
	end

	local typeMult = Verbs._oreToolTypeMult({ familyId = familyId, typeId = def.id })
	local cost = C.toolCraftCost(oreDef.tier, typeMult)

	p.ores = p.ores or {}
	local have = tonumber(p.ores[oreId]) or 0
	if have < cost then
		net:FireClient(plr, "toast", string.format("Needs %s %s",
			Verbs._benchNum(cost), oreDef.name or oreId))
		return
	end

	p.ores[oreId] = have - cost

	--[[
		A FORGED TOOL INHERITS YOUR LEVELLING.

		It used to arrive at level 1, and that made forging up a DOWNGRADE at
		every single tier. Measured (tools/forge-feel.js): a fresh tier-(T+1)
		tool is x0.003 of the maxed tier-T tool already in your hand, and has to
		be levelled to 30 of 30 just to break even. Every tier, all the way up.

		It cannot be tuned away either. A fresh tool only wins if one tier step
		is worth a whole climb, and with 81 tier steps inside the damage budget
		the best possible case is tier step = climb = x1.265 -- which makes
		levelling worth nothing at all. 82 tiers is what forces the step small,
		so the fix has to be mechanical rather than numerical.

		Carrying the level makes forging an upgrade the moment you pay for it
		(x1.167, the honest tier step) and recasts the two axes: LEVELS are an
		early ramp you climb once and keep, TIER is the progression. That is
		already how ORE_REACH and the breaking gate treat the game.

		Inherited from the best tool on the rack, not from a tool of the same
		family, because the levels were paid for in ore and dust once and the
		player does not owe them twice for choosing a different frame. Clamped,
		so a profile carrying a pre-cap level cannot smuggle it past the cap.
	]]
	local inherited = 1
	for _, t in ipairs(p.oreTools) do
		if type(t) == "table" then
			local lv = math.floor(tonumber(t.level) or 1)
			if lv > inherited then
				inherited = lv
			end
		end
	end
	inherited = math.clamp(inherited, 1, tonumber(C.TOOL_MAX_LEVEL) or 30)

	--[[
		`base` is what makes the inheritance safe to scrap.

		The row records the level it was FORGED at, so recycling can refund the
		levels this tool actually bought rather than the levels it was handed.
		Without it, forge -> scrap -> repeat paid out half a full climb each time
		for the price of one craft. See MineConfig.toolRecycle.
	]]
	local row = {
		uid = instanceHex16(),
		typeId = def.id,
		familyId = familyId,
		tier = oreDef.tier,
		level = inherited,
		base = inherited,
	}
	table.insert(p.oreTools, row)

	bumpStat(plr, p, "crafts")
	net:FireClient(plr, "toast", "Forged  " .. OreTools.name(oreDef, familyId))
	snap(plr)
	markDirty(plr)
	--[[
		Equip what was just forged.

		This was a copy of equipOreTool's TOGGLE pasted into craft, and it read
		`uid` -- a local that does not exist in this function. Luau compiles an
		undeclared name as a GLOBAL read, so `uid` was nil in both branches:
		`p.oreToolEquipped == nil` took the first branch whenever nothing was
		held and the second assigned nil anyway. Either way the field ended up
		nil, so forging never equipped the new tool and, if you were holding
		one, silently put it away. The row's id is `row.uid`.

		There is no toggle to do here: you cannot be holding a tool that did
		not exist a line ago.
	]]
	p.oreToolEquipped = row.uid
	p.chestTool = nil
	p.toolEquipped = true
	givePickaxe(plr)
	markDirty(plr)
	snap(plr)
end

--[[
	ENCHANT A TOOL. One verb, one flat price, one roll.

	Owner, 2026-10-04: applying a trait is "the same rarity as rune/temperment/skins",
	Exotic at 1/1000 and Exotic V at 1/5000, level random 1-5, and the price
	"stays the same with rebirths (broke players arent going to try to get
	exotic V, endgame players will.)".

	So this is a GACHA, not a purchase: you pay MineTraits.ROLL_PRICE and get
	what the table gives you. The price reads no prestige, no rebirth count, no
	zone and no tool tier -- tools/verify/traits.js asserts that, because a
	price that quietly scaled with rebirth would break the one sentence the
	owner was most specific about.

	Server-authoritative in the way that matters: the client names a uid and
	nothing else. The rarity, the trait and the level are all rolled here
	with a server rng.
]]
function Verbs.rollTrait(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local Traits = Dig.Traits
	local uid = (type(payload) == "table") and payload.uid or payload
	local tool = Verbs._findOreTool(p, uid)
	if not tool then
		net:FireClient(plr, "toast", "That tool is not in your bag")
		return
	end

	local cost = Traits.ROLL_PRICE
	local have = tonumber(p.gems) or 0
	if have < cost then
		net:FireClient(plr, "toast", string.format("Needs %s gems",
			Verbs._benchNum(cost)))
		return
	end

	local rolled = Traits.roll(Random.new())
	if not rolled then
		net:FireClient(plr, "toast", "The enchanter has nothing to give")
		return
	end

	p.gems = have - cost
	--[[
		A roll REPLACES what was there. There is no "keep the better one"
		prompt: that turns every roll into a dialog, and the gamble is the
		feature. The old one is named in the toast so a player who just lost
		something good sees what it was.
	]]
	local had = type(tool.trait) == "table" and Traits.label(tool.trait) or nil
	tool.trait = rolled

	local OreTools = require(shared:WaitForChild("MineOreTools"))
	net:FireClient(plr, "toast", string.format("%s  \u{00B7}  %s%s",
		OreTools.toolName(tool), Traits.label(rolled),
		had and ("   (was " .. had .. ")") or ""))
	bumpStat(plr, p, "traits")
	-- Re-give the tool so its name and its stats both follow the roll.
	if p.oreToolEquipped == tool.uid then
		givePickaxe(plr)
	end
	markDirty(plr)
	snap(plr)
end

function Verbs.recycleOreTool(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local uid = (type(payload) == "table") and payload.uid or payload
	local tool, index = Verbs._findOreTool(p, uid)
	if not tool or not index then
		net:FireClient(plr, "toast", "That tool is not in your bag")
		return
	end
	if tool.equipped then
		net:FireClient(plr, "toast", "Unequip it first")
		return
	end

	local _, _, oreDef, typeMult = Verbs._oreToolCost(tool)
	local level = math.max(1, tonumber(tool.level) or 1)
	--[[
		The level this tool was FORGED at. Levels it inherited cost nothing, so
		they refund nothing; only the climb bought on this tool comes back.

		Rows saved before `base` existed fall back to 1 and refund on the old
		terms, which is the generous direction and affects only tools already in
		a profile.
	]]
	local base = math.clamp(math.floor(tonumber(tool.base) or 1), 1, level)
	local ore, dust = C.toolRecycle(tool.tier, level, typeMult, base)
	local oreId = oreDef and oreDef.id

	-- Let go before it stops existing, or the hand keeps a uid that no longer
	-- resolves. equippedTool self-heals from this, but re-giving the pickaxe
	-- here is what actually puts the ladder tool back in the player's hand.
	local wasHeld = (p.oreToolEquipped == tool.uid)
	table.remove(p.oreTools, index)
	if wasHeld then
		p.oreToolEquipped = nil
		givePickaxe(plr)
	end
	if oreId and ore > 0 then
		local kept, spilled = Dig.addOre(p, oreId, ore)
		if spilled > 0 then
			Dig.pouchFullToast(plr, p)
		end
		-- Report what was banked, not what was owed, so the toast below cannot
		-- promise ore the pouch had no room for.
		ore = kept
	end
	if dust > 0 then
		p.dust = (tonumber(p.dust) or 0) + dust
	end
	net:FireClient(plr, "toast", string.format("Scrapped  +%s %s  +%s stardust",
		Verbs._benchNum(ore),
		(oreDef and oreDef.name) or "ore",
		Verbs._benchNum(dust)))
	snap(plr)
	markDirty(plr)
end

net.OnServerEvent:Connect(function(plr, action, payload)
	if action == "swing" and typeof(payload) == "Instance" then
		if not profiles[plr.UserId] then load(plr) end
		local ok, err = pcall(swingBlock, plr, payload)
		if not ok then warn("[Mine] " .. tostring(err)) end
		return
	end
	if busy[plr.UserId] then return end
	busy[plr.UserId] = true
	local ok, err = pcall(function()
		if not profiles[plr.UserId] then load(plr) end
		if Verbs.policyBlocks(plr, action) then return end
		if action == "dig" and typeof(payload) == "Instance" then swingBlock(plr, payload)
		elseif action == "craftOreTool" then Verbs.craftOreTool(plr, payload)
		elseif action == "rollTrait" then Verbs.rollTrait(plr, payload)
		elseif action == "equipOreTool" then Verbs.equipOreTool(plr, payload)
		elseif action == "upgradeOreTool" then Verbs.upgradeOreTool(plr, payload)
		elseif action == "recycleOreTool" then Verbs.recycleOreTool(plr, payload)
		elseif action == "equipOreTool" then Verbs.equipOreTool(plr, payload)
		elseif action == "throwAt" then throwAt(plr, payload)
		elseif action == "bagGo" then
			local go = (payload == "shop") and "shop" or "sell"
			gotoStation(plr, go)
			-- A button labelled SELL has to sell. gotoStation only walked you to
			-- the pad and returned, leaving the prompt still to be pressed.
			if go == "sell" then
				sellAll(plr)
			end
		elseif action == "afkStart" then
			Verbs.Afk.start(plr)
		elseif action == "afkStop" then
			Verbs.Afk.stop(plr, "wake")
		elseif action == "afkRefresh" then
			-- Client asks early when Idled time is climbing; same keep-alive as the timer.
			if Verbs.Afk.active[plr.UserId] then
				Verbs.Afk.refreshSession(plr)
			end
		elseif action == "sell" then
			gotoStation(plr, "sell")
			-- Same here: arrive AND sell.
			sellAll(plr)
		elseif action == "open" then openFrom(plr)
		elseif action == "openAt" then openAt(plr, payload)
		elseif action == "openMany" then openMany(plr, payload)
		elseif action == "openLucky" then Verbs.openLucky(plr, payload)
		elseif action == "luckyGradeUp" then Verbs.luckyGradeUp(plr, payload)
		elseif action == "scrapMany" then scrapMany(plr, payload)
		elseif action == "equip" then equip(plr, payload)
		elseif action == "unequip" then unequip(plr, payload)
		elseif action == "merge" then merge(plr, payload and payload.ids, payload and payload.useDust)
		elseif action == "sellTool" then Verbs.sellTool(plr, payload)
		elseif action == "fusePassTools" then Verbs.fusePassTools(plr)
		elseif action == "salvage" then salvage(plr, payload)
		elseif action == "scrap" then scrapItem(plr, payload)
		elseif action == "power" then powerUp(plr, payload)
		elseif action == "buy" then buy(plr, payload)
		elseif action == "introAck" then
			local p = profiles[plr.UserId]
			if p then
				local step = math.floor(tonumber(p.intro) or 1)
				local d = Intro.steps[step]
				-- Step 3 becomes claimable once any non-starter shop pick is owned.
				if (d and d.ack) or (step == 3 and ownsBetterPickaxe(p)) then
					introAdvance(plr, p, step)
				end
			end
		elseif action == "introPing" then
			local p = profiles[plr.UserId]
			local want = math.floor(tonumber(payload) or 0)
			if p and math.floor(tonumber(p.intro) or 0) == want then
				introAdvance(plr, p, want)
			end
		elseif action == "prestige" then tryPrestige(plr)
		elseif action == "buyZone" then buyZone(plr, payload)
		elseif action == "equipCharm" then equipCharm(plr, payload)
		elseif action == "mergeCharm" then Verbs.mergeCharm(plr, payload)
		elseif action == "equipVfx" then equipVfx(plr, payload)
		elseif action == "equipBag" then
			local p = profiles[plr.UserId]
			if p then
				local which = tostring(type(payload) == "table" and (payload.id or payload[1]) or payload or "")
				if which == "founders" and p.foundersBag then
					p.equippedBag = "founders"
				elseif which == "wormhole" and p.wormholeBag then
					p.equippedBag = "wormhole"
				else
					p.equippedBag = "ladder"
				end
				giveBackpackModel(plr)
				walk(plr)
				markDirty(plr)
				snap(plr)
			end
		elseif action == "buyVfx" then buyVfx(plr, payload)
		elseif action == "buyCharmsPack" then buyCharmsPack(plr)
		elseif action == "buyLuckyCharm" then buyLuckyCharm(plr)
		elseif action == "buyProductCredits" then buyProductWithCredits(plr, type(payload) == "table" and payload.key or payload)
		elseif action == "buyBattlePassCredits" then buyBattlePassCredits(plr)
		elseif action == "skillBuy" then Verbs.skillBuy(plr, payload)
		elseif action == "skillPreset" then Verbs.skillPreset(plr, payload)
		elseif action == "skillBuySlot" then Verbs.skillBuySlot(plr)
		elseif action == "skillReset" then Verbs.skillReset(plr)
		-- skillSacrifice is the old name for selling; kept so a stale client still sells.
		elseif action == "skillSell" or action == "skillSacrifice" then Verbs.skillSell(plr)
		elseif action == "skillBuyBack" then Verbs.skillBuyBack(plr)
		elseif action == "rollTemper" then Verbs.rollTemper(plr, payload)
		elseif action == "openTemperCase" then Verbs.openTemperCase(plr, payload)
		elseif action == "openTemperCaseBundle" then Verbs.openTemperCaseBundle(plr)
		elseif action == "scrapTemper" then Verbs.scrapTemper(plr, payload)
		elseif action == "equipTemper" then Verbs.equipTemper(plr, payload)
		elseif action == "goClouds" then Verbs.goClouds(plr)
		elseif action == "buyTool" then buyTool(plr, payload)
		elseif action == "buyDepthTool" then buyDepthTool(plr, payload)
		elseif action == "rollRune" then Verbs.rollRuneBanner(plr, payload)
		elseif action == "rollGear" then Verbs.rollGearBanner(plr, payload)
		elseif action == "fuseRune" then Verbs.fuseRunes(plr, payload)
		elseif action == "socketToolRune" then Verbs.socketToolRune(plr, payload)
		elseif action == "destroyToolRune" then destroyToolRune(plr, payload)
		elseif action == "unsocketToolRune" then destroyToolRune(plr, payload)
		elseif action == "socketPetRune" then Verbs.socketPetRune(plr, payload)
		-- The client has always fired this from the hat-merge button; it was the
		-- only one of 93 client actions with no branch here, so the button did
		-- nothing at all. Verbs.mergeHats itself was complete.
		elseif action == "mergeHats" then Verbs.mergeHats(plr, payload)
		elseif action == "upgradeGear" then Verbs.upgradeGear(plr, payload)
		elseif action == "upgradeOrePouch" then Verbs.upgradeOrePouch(plr)
		elseif action == "toggleOreLock" then Verbs.toggleOreLock(plr, payload)
		elseif action == "buyCharm" then Verbs.buyCharm(plr, payload)
		elseif action == "buyTraderCase" then Verbs.buyTraderCase(plr, payload)
		elseif action == "launchSeason" then Verbs.launchSeason(plr)
		elseif action == "sellOre" then Verbs.sellOre(plr, payload)
		elseif action == "sellAllOres" then Verbs.sellAllOres(plr, payload)
		elseif action == "equipGear" then Verbs.equipGearPiece(plr, payload)
		elseif action == "equipBest" then Verbs.equipBest(plr)
		elseif action == "unequipGear" then Verbs.unequipGearPiece(plr, payload)
		elseif action == "socketGearRune" then Verbs.socketGearRune(plr, payload)
		elseif action == "buyScroll" then Verbs.buyScroll(plr, payload)
		elseif action == "drinkPotion" then
			local p = profiles[plr.UserId]
			if not p or type(payload) ~= "table" then return end
			local ok, defOrErr, err = pcall(function()
				return require(shared:WaitForChild("MinePotions")).drink(p, payload.id)
			end)
			if not ok then
				net:FireClient(plr, "toast", "Potion failed")
				return
			end
			local def, e = defOrErr, err
			if not def then
				net:FireClient(plr, "toast", tostring(e or "Can't drink that"))
				return
			end
			markDirty(plr)
			snap(plr)
			net:FireClient(plr, "toast", "Drank " .. def.name)
		elseif action == "mergePotion" then
			local p = profiles[plr.UserId]
			if not p or type(payload) ~= "table" then return end
			local ok, defOrErr, err = pcall(function()
				return require(shared:WaitForChild("MinePotions")).merge(p, payload.id)
			end)
			if not ok then
				net:FireClient(plr, "toast", "Merge failed")
				return
			end
			local def, e = defOrErr, err
			if not def then
				net:FireClient(plr, "toast", tostring(e or "Can't merge that"))
				return
			end
			markDirty(plr)
			snap(plr)
			net:FireClient(plr, "toast", "Merged into " .. def.name .. "  (-" .. tostring(e or 0) .. " dust)")
		elseif action == "buyCart" then buyCart(plr, payload)
		elseif action == "buyDustPack" then
			local p = profiles[plr.UserId]
			if not p or type(payload) ~= "table" then return end
			local id = tostring(payload.id or "")
			local qty = math.clamp(math.floor(tonumber(payload.qty) or 1), 1, 10)
			local shop = ensureDustShop()
			local offer
			for _, row in ipairs(shop.offers or {}) do
				if row.id == id then offer = row break end
			end
			if not offer then
				net:FireClient(plr, "toast", "That pack isn't on the stardust shelf right now")
				snap(plr)
				return
			end
			if type(p.dustShop) ~= "table" or p.dustShop.key ~= shop.key then
				p.dustShop = { key = shop.key, bought = {} }
			end
			local already = tonumber(p.dustShop.bought[id]) or 0
			local left = offer.personalMax - already
			if left <= 0 then
				net:FireClient(plr, "toast", "You've bought all of these this rotation")
				return
			end
			qty = math.min(qty, left)
			local pay = offer.price * qty
			if (p.dust or 0) < pay then
				net:FireClient(plr, "toast", "Need " .. pay .. " stardust")
				return
			end
			local okStock, why = takeDustStock(id, qty)
			if not okStock then
				net:FireClient(plr, "toast", tostring(why))
				snap(plr)
				return
			end
			p.dust -= pay
			p.dustShop.bought[id] = already + qty
			if (offer.kind or "pack") == "potion" then
				pcall(function()
					require(shared:WaitForChild("MinePotions")).grant(p, id, qty)
				end)
				net:FireClient(plr, "toast", "Bought " .. qty .. "x " .. (offer.name or id) .. " for stardust")
			else
				p.packs = p.packs or {}
				local def = Packs.PACK_BY_ID and Packs.PACK_BY_ID[id]
				local setIds = {}
				for sid in pairs(Cards.SETS or {}) do table.insert(setIds, sid) end
				table.sort(setIds)
				for _ = 1, qty do
					table.insert(p.packs, {
						packId = id,
						packName = (def and def.name) or id,
						setId = (#setIds > 0) and setIds[Random.new():NextInteger(1, #setIds)] or "dragons_dawn",
					})
				end
				net:FireClient(plr, "toast", "Bought " .. qty .. "x " .. ((def and def.name) or id) .. " for stardust")
				net:FireClient(plr, "purchaseFx", { kind = "pack", packId = id, count = qty, name = (def and def.name) or id })
			end
			introAdvance(plr, p, 35)
			markDirty(plr)
			snap(plr)
		elseif action == "joinVip" then joinVip(plr)
		elseif action == "buyPouch" then Verbs.buyPouch(plr, payload)
		elseif action == "buyCrate" then Verbs.buyCrate(plr, payload)
		elseif action == "armWhiteScroll" then Verbs.armWhiteScroll(plr, payload)
		elseif action == "debugGrantRune" then Verbs.debugGrantRune(plr, payload)
		elseif action == "debugGrantBlastSet" then Verbs.debugGrantBlastSet(plr)
		elseif action == "debugGrantL99Blast" then Verbs.debugGrantL99Blast(plr, payload)
		elseif action == "blackUnequipToolRune" then Verbs.blackUnequipToolRune(plr, payload)
		elseif action == "applyOmniscroll" then Verbs.applyOmniscroll(plr, payload)
		elseif action == "buyCreditPack" then Verbs.buyCreditPack(plr, payload)
		elseif action == "buyCharter" then Verbs.buyCharter(plr, payload)
		elseif action == "buySeam" then Verbs.buySeam(plr, payload)
		elseif action == "equipTool" then equipTool(plr, payload)
		elseif action == "equipShopTool" then
			local p = profiles[plr.UserId]
			if p then
				local okBuy, ShopBuy = pcall(function()
					return require(shared:WaitForChild("MineShopBuy"))
				end)
				local okL, Ladders = pcall(function()
					return require(shared:WaitForChild("MineShopLadders"))
				end)
				if okBuy and ShopBuy and okL and Ladders then
					ShopBuy.equip(plr, p, payload, {
						ShopLadders = Ladders, net = net,
						givePickaxe = givePickaxe, giveBackpackModel = giveBackpackModel, snap = snap,
					})
				end
			end
		elseif action == "fossil_assemble" or action == "fossil_equip" or action == "fossil_sell" then
			--[[
				FOSSILS ARE RETIRED. The bench is gone, and so are the three verbs
				that drove it: assemble, equip, sell.

				Answered rather than dropped because an old client still has the
				buttons, and a button that does nothing at all is the worst of the
				three outcomes. Anything a save still holds is cashed out on load
				(see the fossil migration in load) rather than here, so there is
				nothing for these to act on by the time a player could press them.
			]]
			net:FireClient(plr, "toast", "The fossil bench is gone -- what you had was paid out in gems")
		elseif action == "equipChestTool" then
			local pc = profiles[plr.UserId]
			local want = ""
			if type(payload) == "table" then
				want = payload.id or payload.toolId or ""
			else
				want = payload
			end
			want = tostring(want or "")
			-- A `fossilId` payload used to equip a fossil forever-tool here.
			-- Fossils are retired, so an old client sending one gets told rather
			-- than silently equipping nothing.
			if type(payload) == "table" and payload.fossilId ~= nil
				and tostring(payload.fossilId) ~= "" then
				net:FireClient(plr, "toast", "Fossil tools are gone -- they were paid out in gems")
			elseif want == "" then
				pc.chestTool = nil
				givePickaxe(plr)
				markDirty(plr)
				snap(plr)
			else
				local found = false
				for _, row in ipairs(pc.chestTools or {}) do
					local id = (type(row) == "table") and row.id or row
					if id == want then
						local def = Tools.chestTool(id)
						if def and def.family == "backpack" then
							pc.chestBag = id
						else
							pc.chestTool = id
						end
						found = true
						break
					end
				end
				if not found then
					net:FireClient(plr, "toast", "You do not own that secret")
				else
					-- A secret overrides the ladder; an unequipped player must be
					-- re-armed or givePickaxe no-ops and mining toasts
					-- "Equip a tool first".
					pc.shopToolId = nil
					pc.toolEquipped = true
					givePickaxe(plr)
					giveBackpackModel(plr)
					markDirty(plr)
					snap(plr)
			end
			end
		elseif action == "unequipTool" then unequipTool(plr)
		elseif action == "goTo" then gotoStation(plr, payload)
		elseif action == "rideElevator" then
			local p = profiles[plr.UserId]
			if not p or type(payload) ~= "table" then return end
			local seam = math.max(0, math.floor(tonumber(payload.seam) or 0))
			local z = C.zoneById(payload.zoneId or p.zoneId) or C.ZONES[1]
			Dig.Plazas.ride(plr, nil, p, tp, ensureZone, net, snap, seam)
		elseif action == "devGrant" and Svc.Run:IsStudio() then
			-- Studio only. Never reachable on a live server.
			if type(payload) == "table" then
				if payload.coins then
					local p_dev = profiles[plr.UserId]
					p_dev.coins = (p_dev.coins or 0) + payload.coins
				end
				-- Studio only: hand over a chest flagship by id, so the sockets and
				-- gear screens can be exercised without farming one out of a chest.
				if payload.chestTool then
					local p_devt = profiles[plr.UserId]
					local def = Tools.chestTool(payload.chestTool)
					if def then
						p_devt.chestTools = p_devt.chestTools or {}
						local already = false
						for _, ct in ipairs(p_devt.chestTools) do
							if ((type(ct) == "table") and ct.id or ct) == def.id then already = true end
						end
						if not already then
							grantChestTool(plr, p_devt, def.id)
						end
						p_devt.chestTool = def.id
						givePickaxe(plr)
						net:FireClient(plr, "toast", "Granted " .. tostring(def.name))
					else
						net:FireClient(plr, "toast", "No chest tool called " .. tostring(payload.chestTool))
					end
				end
				-- Studio only: move the pass along without mining a season's
				-- worth of blocks, and flip ownership, so both tracks can be
				-- exercised. Bypasses the daily cap on purpose.
				-- Studio only: replay the first-session guide from any step.
				-- Studio only: jump the ladder and fake the counters, so a quest
				-- gated on 10,000 blocks can be exercised without mining them.
				-- Studio only: push one of the day's three to any progress, so a
				-- quest gated on 400 blocks can be claimed without mining them.
				if type(payload.dq) == "table" then
					local p_devdq = profiles[plr.UserId]
					-- `stale` backdates the stored day so the next ensure rerolls,
					-- which is the only way to exercise the day boundary without
					-- waiting for midnight UTC.
					if payload.dq.stale and type(p_devdq.dailyQuests) == "table" then
						p_devdq.dailyQuests.day = -1
					end
					local dq = ensureDailyQuests(p_devdq, plr.UserId)
					local row = dq.list[math.floor(tonumber(payload.dq.index) or 0)]
					if row then
						row.progress = math.max(0, math.floor(tonumber(payload.dq.progress) or 0))
						if payload.dq.claimed ~= nil then
							row.claimed = payload.dq.claimed and true or false
						end
						markDirty(plr)
						snap(plr)
					end
				end
				if payload.quest then
					local p_devq = profiles[plr.UserId]
					p_devq.quest = math.clamp(math.floor(payload.quest), 1, Quests.COUNT + 1)
					markDirty(plr)
					snap(plr)
				end
				if type(payload.stats) == "table" then
					local p_devst = profiles[plr.UserId]
					p_devst.stats = p_devst.stats or {}
					for k, v in pairs(payload.stats) do
						if type(v) == "number" then
							p_devst.stats[k] = math.max(0, math.floor(v))
						end
					end
					markDirty(plr)
					snap(plr)
				end
				if payload.dailyBack then
					local p_devd = profiles[plr.UserId]
					p_devd.daily = p_devd.daily or { streak = 0, last = 0 }
					p_devd.daily.last = (tonumber(p_devd.daily.last) or 0) - math.floor(payload.dailyBack)
					markDirty(plr)
					snap(plr)
				end
				if payload.dailyStreak then
					local p_devs = profiles[plr.UserId]
					p_devs.daily = p_devs.daily or { streak = 0, last = 0 }
					p_devs.daily.streak = math.max(0, math.floor(payload.dailyStreak))
					markDirty(plr)
					snap(plr)
				end
				if payload.intro then
					local p_devi = profiles[plr.UserId]
					-- Clamp to Intro.done, not to a hardcoded 4. The step count
					-- changed when the chest line was added, and a fixed bound
					-- silently refuses to set the "finished" state.
					p_devi.intro = math.clamp(math.floor(payload.intro), 1, Intro.done)
					markDirty(plr)
					introSend(plr, p_devi)
				end
				if payload.passXp or payload.passOwned ~= nil then
					local p_devp = profiles[plr.UserId]
					p_devp.pass = p_devp.pass or Scrolls.emptyPass()
					if payload.passXp then
						p_devp.pass.xp = math.max(0, (p_devp.pass.xp or 0) + payload.passXp)
					end
					if payload.passOwned ~= nil then
						p_devp.pass.owned = payload.passOwned and true or false
					end
					markDirty(plr)
					net:FireClient(plr, "toast", "Pass: tier "
						.. Scrolls.passTier(p_devp.pass.xp)
						.. (p_devp.pass.owned and " (paid)" or " (free)"))
				end
				if payload.gems then
					local p_devg = profiles[plr.UserId]
					p_devg.gems = (p_devg.gems or 0) + payload.gems
				end
				if payload.credits then
					local p_devc = profiles[plr.UserId]
					p_devc.credits = (p_devc.credits or 0) + payload.credits
				end
				local p_dev0 = profiles[plr.UserId]
				if payload.packs then
					-- Studio only: open N real packs so there is something to look at in
					-- the binder. It goes through openPack, the same path a chest drop
					-- takes, so nothing tested this way is a special case.
					local ids = {}
					for id in pairs(Cards.SETS) do
						table.insert(ids, id)
					end
					table.sort(ids)
					for i = 1, math.min(payload.packs, 24) do
						local roster = Packs.PACKS or {}
						local rp = roster[((i - 1) % math.max(#roster, 1)) + 1]
						table.insert(p_dev0.packs, {
							setId = ids[((i - 1) % #ids) + 1],
							packId = rp and rp.id or nil,
							packName = rp and rp.name or nil,
						})
					end
					snap(plr)
				end
				if payload.tool then
					local pd = profiles[plr.UserId]
					equippedTool(pd)
					pd.tools[payload.tool] = payload.tier or 1
					pd.toolFamily = payload.tool
					givePickaxe(plr)
					giveBackpackModel(plr)
				end
				-- Studio only: force zone ladder / gems so buyZone can be replayed.
				if payload.maxUnlockedZone ~= nil then
					local pd = profiles[plr.UserId]
					pd.maxUnlockedZone = math.max(1, math.floor(tonumber(payload.maxUnlockedZone) or 1))
					pd.zoneId = (C.ZONES[pd.maxUnlockedZone] and C.ZONES[pd.maxUnlockedZone].id) or "meadow"
				end
				if payload.gems ~= nil then
					local pd = profiles[plr.UserId]
					pd.gems = math.max(0, math.floor(tonumber(payload.gems) or 0))
				end
			end
			snap(plr)
		elseif action == "enterZone" then
			local msg = enterZone(plr, payload)
			if msg then
				if string.find(msg, "Buy ", 1, true) then
					-- Unowned next-zone portal Enter: attempt buyZone (toasts success/fail).
					buyZone(plr, payload)
					local again = enterZone(plr, payload)
					if again and not string.find(again, "Buy ", 1, true) then
						net:FireClient(plr, "toast", again)
					end
				else
					net:FireClient(plr, "toast", msg)
				end
			end
		elseif action == "returnSurface" then
			Verbs.returnSurface(plr)
		elseif action == "camp" then
			tp(plr, lobbyCf())
			snap(plr)
		elseif action == "claimQuest" then Verbs.claimQuest(plr)
		elseif action == "claimDailyQuest" then Verbs.claimDailyQuest(plr, payload)
		elseif action == "claimMilestone" then Quests.svClaimMilestone(plr, payload)
		elseif action == "claimContract" then Quests.svClaimContract(plr, payload)
		elseif action == "claimDaily" then Verbs.claimDaily(plr)
		elseif action == "claimDailySurprise" then Verbs.claimDailySurprise(plr)
		elseif action == "groupWheelSpin" then
			GroupWheelService.spin(plr, profiles, {
				net = net,
				markDirty = markDirty,
				snap = snap,
				grantPacks = Verbs.grantPacks,
				LuckyBlocks = LuckyBlocks,
				mint = mint,
			})
		elseif action == "discordLink" then Verbs.discordLink(plr, payload)
		elseif action == "claimPass" then Verbs.claimPass(plr, payload)
		elseif action == "setSetting" then
			Verbs.setSetting(plr, payload)
		elseif action == "claimPlaytime" then Verbs.claimPlaytime(plr, payload)
		elseif action == "redeemCode" then
			Verbs.redeemCode(plr, payload)
		elseif action == "tradeAsk" then
			TradeService.invite(net, profiles, plr, typeof(payload) == "table" and (payload.to or payload.userId) or payload)
		elseif action == "tradeRespond" then
			TradeService.respond(net, profiles, plr, typeof(payload) == "table" and payload.accept == true)
		elseif action == "coinflipAsk" then
			-- A coinflip is a mode inside the trade window now.
			net:FireClient(plr, "toast", "Open a trade, then switch it to COINFLIP")
		elseif action == "tradeOffer" then
			TradeService.setOffer(net, profiles, plr, payload, { isCardSerial = isCardSerial, runeBusy = runeBusy })
		elseif action == "tradeMode" then
			TradeService.setMode(net, profiles, plr, typeof(payload) == "table" and payload.mode or payload)
		elseif action == "tradeMark" then
			TradeService.mark(net, profiles, plr, payload)
		elseif action == "tradeWant" then
			TradeService.want(net, profiles, plr, payload)
		elseif action == "tradePeek" then
			TradeService.peek(net, profiles, plr, { isCardSerial = isCardSerial, runeBusy = runeBusy })
		elseif action == "tradeBack" then
			TradeService.back(net, profiles, plr)
		elseif action == "tradeReady" then
			TradeService.setReady(net, profiles, plr, payload == true or (typeof(payload) == "table" and payload.ready))
		elseif action == "tradeAccept" then
			TradeService.accept(net, profiles, plr)
		elseif action == "tradeConfirm" then
			TradeService.confirm(net, profiles, plr, {
				transferSerial = transferSerial,
				isCardSerial = isCardSerial,
				runeBusy = runeBusy,
				save = save,
				push = function(p) if p then snap(p) end end,
			})
		elseif action == "tradeCancel" then
			TradeService.cancel(net, plr.UserId, "Trade cancelled")
		elseif action == "profileView" then
			local uid = typeof(payload) == "table" and (payload.userId or payload.to) or payload
			local pub = SocialService.publicProfile(profiles, uid)
			if pub then
				net:FireClient(plr, "profileView", pub)
			else
				net:FireClient(plr, "toast", "Player offline or unknown")
			end
		elseif action == "friendRequest" then
			SocialService.friendRequest(plr, typeof(payload) == "table" and (payload.userId or payload.to) or payload)
		elseif action == "friendAccept" then
			SocialService.friendAccept(plr, typeof(payload) == "table" and payload.userId or payload)
		elseif action == "friendDecline" then
			SocialService.friendDecline(plr, typeof(payload) == "table" and payload.userId or payload)
		elseif action == "friendRemove" then
			SocialService.friendRemove(plr, typeof(payload) == "table" and payload.userId or payload)
		elseif action == "socialListFriends" then
			SocialService.onPlayerJoin(plr)
		elseif action == "socialDM" then
			if typeof(payload) == "table" then
				SocialService.sendDM(plr, payload.to, payload.text)
			end
		elseif action == "socialGetDM" then
			SocialService.getDM(plr, typeof(payload) == "table" and payload.userId or payload)
		elseif action == "socialGlobal" then
			SocialService.globalChat(plr, typeof(payload) == "table" and payload.text or payload)
		elseif action == "socialCreateGroup" then
			if typeof(payload) == "table" then
				SocialService.createGroup(plr, payload.name, payload.kind)
			end
		elseif action == "socialInviteGroup" then
			if typeof(payload) == "table" then
				SocialService.inviteGroup(plr, payload.groupId, payload.userId)
			end
		elseif action == "socialLeaveGroup" then
			SocialService.leaveGroup(plr, typeof(payload) == "table" and payload.groupId or payload)
		elseif action == "socialGroupMsg" then
			if typeof(payload) == "table" then
				SocialService.groupMessage(plr, payload.groupId, payload.text)
			end
		elseif action == "socialListGroups" then
			SocialService.listGroups(plr)
		elseif action == "leaderboardGet" then
			net:FireClient(plr, "leaderboard", LeaderboardService.payloadFor(plr.UserId))
		end
	end)
	busy[plr.UserId] = nil
	if not ok then warn("[Mine] " .. tostring(err)) end
end)

task.defer(function()
	local world = workspace:WaitForChild("MineWorld")
	local bound = setmetatable({}, { __mode = "k" })
	local function tryEnterOrBuy(plr, zoneId)
		local msg = enterZone(plr, zoneId)
		if not msg then
			return
		end
		if string.find(msg, "Buy ", 1, true) then
			-- Unowned next-zone portal: buy then enter.
			buyZone(plr, zoneId)
			local again = enterZone(plr, zoneId)
			if again and not string.find(again, "Buy ", 1, true) then
				net:FireClient(plr, "toast", again)
			end
		else
			net:FireClient(plr, "toast", msg)
		end
	end
	local function bindPrompt(inst)
		if not inst:IsA("ProximityPrompt") or bound[inst] then
			return
		end
		bound[inst] = true
		inst.Triggered:Connect(function(plr)
			local parent = inst.Parent
			if not parent then return end
			local machine, zoneId = parent:GetAttribute("Machine"), parent:GetAttribute("ZoneId")
			local dest = parent:GetAttribute("Destination")
			if dest == "lobby" then
				tp(plr, lobbyCf())
				snap(plr)
			elseif dest == "clouds" then
				tp(plr, cloudCf())
				snap(plr)
			elseif dest == "surface" then
				local z = C.zoneById(zoneId or (profiles[plr.UserId] and profiles[plr.UserId].zoneId)) or C.ZONES[1]
				tp(plr, surfaceCf(z))
				snap(plr)
			elseif machine == "sell" then
				-- Same path the walk-on uses, so the two can never disagree.
				Verbs.sellAtPad(plr, parent, zoneId)
			elseif machine == "shop" then
				-- The Blacksmith owes every new player one pickaxe.
				Verbs.grantFirstPick(plr, profiles[plr.UserId])
				-- There was no branch for this at all. Twelve counters in the world are
				-- tagged Machine="shop" (Blacksmith, Chandlery, Bloodforge, Supply Pod)
				-- and every one of them fell straight through this if-chain, so walking
				-- up to a shop and pressing it did nothing at all.
				net:FireClient(plr, "openPanel", "shop")
			elseif machine == "open" then openFrom(plr)
			elseif machine == "prestige" then
				-- Open the Rebirth panel, never rebirth outright.
				net:FireClient(plr, "openPanel", "prestige")
			elseif machine == "groupWheel" then
				local p = profiles[plr.UserId]
				if not p then return end
				net:FireClient(plr, "openGroupWheel", GroupWheelService.payload(p))
			elseif machine == "elevator" then
				local p = profiles[plr.UserId]
				if not p then return end
				local z = C.zoneById(zoneId or p.zoneId) or C.ZONES[1]
				local deepest = (p.deepest and p.deepest[z.id]) or 0
				local floors = { 0 }
				for _, seam in ipairs(Dig.Depth.SEAMS or {}) do
					table.insert(floors, seam)
				end
				net:FireClient(plr, "openElevator", {
					zoneId = z.id,
					deepest = deepest,
					floors = floors,
				})
			elseif machine == "mineshaft" then
				local p = profiles[plr.UserId]
				if not p then
					return
				end
				-- Server-authoritative ride only (anti-TP): DigAuth + seam unlock inside Plazas.ride.
				Dig.Plazas.ride(plr, parent, p, tp, ensureZone, net, snap)
			elseif machine == "depth_shop" then
				local p = profiles[plr.UserId]
				if not p then return end
				local desk = tostring(parent:GetAttribute("DepthShop") or "")
				local seam = tonumber(parent:GetAttribute("Seam")) or Dig.Shop.deskSeam(desk)
				local z = C.zoneById(zoneId or p.zoneId) or C.ZONES[1]
				local zi = (C.zoneIndex and C.zoneIndex(z.id)) or 1
				local okSeam, why, need = Dig.Auth.canAccessSeam(p, z.id, seam)
				if not okSeam then
					if why == "need_depth" then
						net:FireClient(plr, "toast", "Reach depth " .. tostring(need or seam) .. " to use this shop.")
					elseif Dig.Depth.rebirthToast and need then
						net:FireClient(plr, "toast", Dig.Depth.rebirthToast(need, zi, seam))
					else
						net:FireClient(plr, "toast", "This depth shop is locked.")
					end
					return
				end
				desk = select(1, Dig.Auth.clampDesk(p, z.id, desk))
				local okShop, Shop = pcall(function()
					return require(shared:WaitForChild("MineDepthShop"))
				end)
				Shop = (okShop and Shop) or Dig.Shop
				local catalog = (seam and Shop.catalog(zi, seam, desk)) or {}
				for _, row in ipairs(catalog) do
					local fam = row.family
					local tier = row.tier or 0
					row.owned = fam and ((p.tools and (p.tools[fam] or 0) or 0) >= tier) or false
				end
				net:FireClient(plr, "openPanel", "depth_shop", {
					seam = seam,
					desk = desk,
					zoneId = z.id,
					catalog = catalog,
					ownedTools = p.tools or {},
					backpackTier = p.backpackTier or 1,
					coins = p.coins or 0,
					gems = p.gems or 0,
					spaceCoins = p.spaceCoins or 0,
					eventTools = p.eventTools,
					deepest = (p.deepest and p.deepest[z.id]) or 0,
				})
			elseif machine then
				net:FireClient(plr, "openPanel", machine)
			elseif dest then
				tryEnterOrBuy(plr, dest)
			elseif zoneId then
				tryEnterOrBuy(plr, zoneId)
			end
		end)
	end
	for _, inst in ipairs(world:GetDescendants()) do
		bindPrompt(inst)
		Verbs.bindSellPad(inst)
	end
	-- World rebuild / late outposts: keep portal + shop prompts wired.
	world.DescendantAdded:Connect(bindPrompt)
	world.DescendantAdded:Connect(Verbs.bindSellPad)
end)

-- AUTO-SELL. Standing on the pad is the whole interaction. Holding E to confirm
-- that yes, you would like the coins you spent ten minutes mining, is a keypress
-- that has never once been the answer to "no".
--
-- Done by position rather than by Touched, so it also fires when the bag-full
-- menu teleports you onto the pad and you arrive already standing still.
task.defer(function()
	local world = workspace:WaitForChild("MineWorld")
	local pads = {}
	local function consider(inst)
		if inst:IsA("BasePart") and inst:GetAttribute("Machine") == "sell" then
			table.insert(pads, inst)
			-- No prompt on a pad that acts by itself.
			for _, ch in ipairs(inst:GetDescendants()) do
				if ch:IsA("ProximityPrompt") then
					ch.Enabled = false
				end
			end
		end
	end
	for _, inst in ipairs(world:GetDescendants()) do
		consider(inst)
	end
	-- Outposts stream in with their zone, so the list stays open.
	world.DescendantAdded:Connect(consider)

	while true do
		task.wait(0.35)
		for _, plr in ipairs(Svc.Players:GetPlayers()) do
			local p = profiles[plr.UserId]
			local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local carrying = p and (
				(p.load or 0) > 0
				or (p.haulCoins or 0) > 0
				or (p.haulGems or 0) > 0
				or (function()
					-- Dirt/ores live in backpack for the bag UI; haul counters can
					-- desync. Still sell if the bag shows blocks.
					for _, item in ipairs(p.backpack or {}) do
						if item and item.kind ~= "chest" and item.kind ~= "crate" then
							return true
						end
					end
					return false
				end)()
			)
			if root and carrying then
				for _, pad in ipairs(pads) do
					if pad.Parent then
						-- Object space, so a rotated pad still tests as a box.
						local d = pad.CFrame:PointToObjectSpace(root.Position)
						local h = pad.Size * 0.5
						if math.abs(d.X) <= h.X and math.abs(d.Z) <= h.Z and math.abs(d.Y) <= h.Y + 4 then
							p._sellDesk = pad:GetAttribute("SellDesk") or "surface"
							pcall(sellAll, plr)
							break
						end
					end
				end
			end
		end
	end
end)

Verbs.grantReceipt = function(info)
	local plr = Svc.Players:GetPlayerByUserId(info.PlayerId)
	if not plr then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- Prompt refresh: ownership may have changed around a purchase flow.
	pcall(refreshVipPass, plr)
	local p = profiles[plr.UserId]
	if not p then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	for _, pack in ipairs(Scrolls.CREDIT_PACKS) do
		local pid = tonumber(pack.productId) or 0
		if pid > 0 and info.ProductId == pid then
			p.credits = (p.credits or 0) + (pack.credits or 0)
			pcall(function()
				game:GetService("AnalyticsService"):LogEconomyEvent(plr, Enum.AnalyticsEconomyFlowType.Source,
					"Credits", pack.credits or 0, p.credits, Enum.AnalyticsEconomyTransactionType.IAP.Name,
					"credits_" .. tostring(pack.id or pid))
			end)
			snap(plr)
			net:FireClient(plr, "toast", "+" .. pack.credits .. " credits!")
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	-- The pass is bought once and unlocks the paid track for the whole season.
	-- Tiers already earned stay earned, so buying at tier 7 immediately opens
	-- seven premium rewards to claim -- which is the point of buying late.
	local bp = Scrolls.BATTLE_PASS
	if bp and (tonumber(bp.productId) or 0) > 0 and info.ProductId == bp.productId then
		p.pass = p.pass or Scrolls.emptyPass()
		if not p.pass.owned then
			p.pass.owned = true
			p.pass.boughtAt = os.time()
			markDirty(plr)
		end
		snap(plr)
		net:FireClient(plr, "toast", "Battle Pass unlocked - claim your tiers in Inventory > Pass")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Robux bags + launch limiteds (Lucky Charm / Lucky Block pet).
	local function grantProduct(key)
		local Offers = require(shared:WaitForChild("MineRotatingOffers"))
		local deal = Offers.byId(key)
		if deal and deal.kind == "deal" then
			if Offers.deny(p, deal) then
				return true
			end
			Offers.grant(p, deal)
			markDirty(plr)
			snap(plr)
			net:FireClient(plr, "toast", deal.toast or (deal.title .. " claimed"))
			if deal.charm then
				walk(plr)
			end
			return true
		end
		if key == "patron_rig" then
			local target = nil
			for i, bp in ipairs(C.BACKPACKS or {}) do
				if bp.robux then target = i break end
			end
			if not target then return false end
			if (p.backpackTier or 1) < target then
				p.backpackTier = target
				p.foundersBag = true
				p.equippedBag = "founders"
				giveBackpackModel(plr)
				markDirty(plr)
			end
			snap(plr)
			net:FireClient(plr, "toast", "Founders Rig unlocked")
			return true
		end
		if key == "lucky_charm" then
			p.charms = p.charms or {}
			p.charms.lucky_charm = true
			-- Never auto-equip — player picks their build in Inventory → Equipment.
			markDirty(plr)
			snap(plr)
			net:FireClient(plr, "toast", "Lucky Charm owned — equip it in Inventory → Equipment")
			return true
		end
		if key == "starter_bundle" then
			local prod = C.product("starter_bundle") or {}
			local wantBag = math.max(1, math.floor(tonumber(prod.bagRung) or 2))
			if (p.backpackTier or 1) < wantBag then
				p.backpackTier = wantBag
				giveBackpackModel(plr)
			end
			p.coins = (p.coins or 0) + (tonumber(prod.coins) or 8000)
			if (tonumber(prod.commonPet) or 1) > 0 then
				local setId = "dragons_dawn"
				local pool = Cards.indicesOfRarity and Cards.indicesOfRarity(setId, "Common") or {}
				if #pool > 0 then
					local index = pool[Random.new():NextInteger(1, #pool)]
					local def = Cards.getCard and Cards.getCard(setId, index)
					if def then
						table.insert(p.cards, mint(def, plr.UserId, true))
					end
				end
			end
			p.starterBought = true
			markDirty(plr)
			snap(plr)
			net:FireClient(plr, "toast", "Starter Crate unlocked!")
			return true
		end
		if key == "weekend_haul" then
			local prod = C.product("weekend_haul") or {}
			Verbs.grantPacks(plr, p, prod.packs)
			for _, row in ipairs(prod.blocks or {}) do
				LuckyBlocks.grant(p, row.id, "F", row.qty or 1)
			end
			if prod.potionId then
				pcall(function()
					require(shared:WaitForChild("MinePotions")).grant(p, prod.potionId, prod.potionQty or 1)
				end)
			end
			markDirty(plr)
			snap(plr)
			net:FireClient(plr, "toast", "Weekend Haul claimed")
			return true
		end
		if key == "pet_slot" then
			--[[
				Retired product. It never had a live Roblox productId (0), and the
				buy path refuses before any prompt, so this cannot be reached by
				paying -- it exists so a stray receipt is acknowledged instead of
				being retried forever. It grants nothing because there is no
				fourth seat to grant.
			]]
			net:FireClient(plr, "toast", "Pet seats are no longer sold -- everyone has three")
			return true
		end
		if key == "coin_double" then
			p.coinDouble = true
			markDirty(plr)
			snap(plr)
			net:FireClient(plr, "toast", "2x Coins active")
			return true
		end
		if key == "auto_mine" then
			p.autoMineLicense = true
			markDirty(plr)
			snap(plr)
			net:FireClient(plr, "toast", "Auto-Mine License active")
			return true
		end
		if key == "lucky_block_pet" then
			-- Grant path reserved; pet roster wires the named kit when product IDs land.
			p.ownedPets = p.ownedPets or {}
			p.ownedPets.lucky_block = true
			markDirty(plr)
			snap(plr)
			net:FireClient(plr, "toast", "Lucky Block pet owned")
			return true
		end
		if key == "group_wheel_1" or key == "group_wheel_5" or key == "group_wheel_10" then
			-- Always bank spins on a paid receipt — the charge already cleared.
			local Wheel = require(shared:WaitForChild("MineGroupWheel"))
			local prod = C.product(key) or {}
			local n = math.max(1, math.floor(tonumber(prod.spins) or 1))
			GroupWheelService.grantPaidSpins(p, n)
			markDirty(plr)
			snap(plr)
			net:FireClient(plr, "groupWheel", {
				ok = false,
				reason = "bought",
				payload = Wheel.payload(p, os.time()),
			})
			net:FireClient(plr, "toast", string.format("+%d Group Wheel spin%s", n, n == 1 and "" or "s"))
			return true
		end
		return false
	end

	for key, prod in pairs(C.PRODUCTS or {}) do
		local pid = tonumber(prod.productId) or 0
		if pid > 0 and info.ProductId == pid then
			if not C.limitedSaleOpen or C.limitedSaleOpen() or key == "patron_rig" or key == "starter_bundle" then
				if grantProduct(key) then
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
			else
				net:FireClient(plr, "toast", "That limited is not on sale yet")
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end
	end
	-- Legacy: backpack rows that still carry productId directly.
	for i, bp in ipairs(C.BACKPACKS or {}) do
		local pid = tonumber(bp.productId) or 0
		if bp.robux and pid > 0 and info.ProductId == pid then
			if (p.backpackTier or 1) < i then
				p.backpackTier = i
				giveBackpackModel(plr)
				markDirty(plr)
			end
			snap(plr)
			net:FireClient(plr, "toast", (bp.name or "Founders Rig") .. " unlocked")
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

--[[
	PAID ROBUX: NEVER LOST, NEVER TWICE.

	Roblox re-sends a receipt until it hears PurchaseGranted -- to a fresh
	server, too, after a crash. So every PurchaseId is written into the profile
	and SAVED before we say granted. A retry of something already delivered is
	answered from that list (once it is safely on disk); a crash before the
	save means the grant never reached the datastore, so the retry delivers it
	again, exactly once.
]]
Svc.Marketplace.ProcessReceipt = function(info)
	local plr = Svc.Players:GetPlayerByUserId(info.PlayerId)
	local p = plr and profiles[plr.UserId]
	if not p or p._ephemeral then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	p.receipts = p.receipts or {}
	if p.receipts[info.PurchaseId] then
		if save(plr) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local decision = Verbs.grantReceipt(info)
	if decision ~= Enum.ProductPurchaseDecision.PurchaseGranted then
		return decision
	end
	p.receipts[info.PurchaseId] = os.time()
	-- Keep the newest hundred; Roblox stops retrying long before that.
	local ids = {}
	for id in pairs(p.receipts) do
		ids[#ids + 1] = id
	end
	if #ids > 100 then
		table.sort(ids, function(x, y)
			return p.receipts[x] > p.receipts[y]
		end)
		for i = 101, #ids do
			p.receipts[ids[i]] = nil
		end
	end
	if not save(plr) then
		-- Delivered in memory and noted; Roblox asks again, and that ask is
		-- answered from the list once a save lands.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	pcall(function()
		game:GetService("AnalyticsService"):LogCustomEvent(plr, "RobuxPurchase", tonumber(info.CurrencySpent) or 0)
	end)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

Svc.Marketplace.PromptGamePassPurchaseFinished:Connect(function(plr, gamePassId, wasPurchased)
	if not plr or not wasPurchased then
		return
	end
	local gid = tonumber(gamePassId)
	if gid == tonumber(C.FOUNDERS_GAMEPASS_ID or 1982786367) then
		local p = profiles[plr.UserId]
		local Founders = require(shared.MineFounders)
		if p and Founders.isMember(p) then
			net:FireClient(plr, "toast", "Founders Pack already active")
			return
		end
		if p then
			local seatsRef = { left = vipSeatsLeft }
			if Founders.grant(p, plr, "gamepass", {
				seatsRef = seatsRef,
				grantScrolls = grantScrolls,
				toast = function(plr2, msg) net:FireClient(plr2, "toast", msg) end,
			}) then
				vipSeatsLeft = seatsRef.left or vipSeatsLeft
				markDirty(plr)
				snap(plr)
			end
		end
		return
	end
	if gid ~= tonumber(C.VIP_GAMEPASS_ID or 1977363670) then
		return
	end
	if refreshVipPass(plr) then
		markDirty(plr)
		snap(plr)
		net:FireClient(plr, "toast", "VIP active -- sell from anywhere, bigger bag, faster walk, better AFK")
	end
end)

-- World Pulse loop: idle 15m → random event 1–5m → repeat.
require(shared.MineWorldEvents).startLoop(snap)

-- Owner grant panel: UserId allowlist lives in ServerScriptService.Mine.Admin.
require(script.Parent.Admin.MineAdmin).start({
	profiles = profiles,
	snap = snap,
	markDirty = markDirty,
	Packs = Packs,
	Cards = Cards,
	C = C,
	givePickaxe = givePickaxe,
	giveBackpackModel = giveBackpackModel,
	equippedTool = equippedTool,
	blank = blank,
	save = save,
})

-- Ensure AFK chill exists even if the world was built before this pad shipped.
-- IIFE so its locals do not burn main-chunk registers (Luau 200 cap).
;(function()
	local world = workspace:FindFirstChild("MineWorld")
	if world and not world:FindFirstChild("AfkChill") then
		local pad = C.AFK_PAD or Vector3.new(36, 6, 36)
		local ground = 5
		local chill = Instance.new("Folder")
		chill.Name = "AfkChill"
		chill.Parent = world
		local function p(props)
			local x = Instance.new("Part")
			x.Anchored = true
			x.CanCollide = props.CanCollide ~= false
			x.Size = props.Size
			x.CFrame = props.CFrame
			x.Color = props.Color or Color3.fromRGB(120, 120, 120)
			x.Material = props.Material or Enum.Material.SmoothPlastic
			x.Transparency = props.Transparency or 0
			x.Name = props.Name
			x.Parent = chill
			return x
		end
		p({
			Name = "Deck",
			Size = Vector3.new(18, 1.2, 18),
			CFrame = CFrame.new(pad.X, ground - 0.4, pad.Z),
			Color = Color3.fromRGB(110, 128, 96),
			Material = Enum.Material.Grass,
		})
		local spawn = p({
			Name = "Spawn",
			Size = Vector3.new(4, 1, 4),
			CFrame = CFrame.lookAt(
				Vector3.new(pad.X, ground + 0.5, pad.Z - 4),
				Vector3.new(pad.X, ground + 0.5, pad.Z + 5)
			),
			Transparency = 1,
			CanCollide = false,
		})
		spawn:SetAttribute("AfkPad", true)
		local bs = C.BLOCK or 4
		local blk = p({
			Name = "MineBlock",
			Size = Vector3.new(bs, bs, bs),
			CFrame = CFrame.new(pad.X, ground - 0.4 + bs * 0.5, pad.Z + 5),
			Color = Color3.fromRGB(150, 110, 72),
			Material = Enum.Material.Ground,
		})
		blk:SetAttribute("AfkBlock", true)
		blk:SetAttribute("Kind", "dirt")
		blk:SetAttribute("HP", 30)
		blk:SetAttribute("MaxHP", 30)
		blk:SetAttribute("ZoneId", "meadow")
	end
end)()

print("[Mine] server ready on place " .. tostring(game.PlaceId))
