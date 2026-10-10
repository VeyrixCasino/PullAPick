--[[
	MineAdmin — server-authoritative grant panel backend.

	Started by MineServer with live profile deps. All grants mutate the
	server profile table and push a snapshot. Remotes always re-check
	AdminAllowlist by numeric UserId. Client UI is cosmetic only.
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")

local Allowlist = require(script.Parent.AdminAllowlist)

local MAX_GRANTS_PER_MINUTE = 40
local MAX_CURRENCY = 1e12
local MAX_PACK_QTY = 50
local MAX_ZONE = 64
local UNAUTH_KICK_AFTER = 5
-- Admin-forged custom gear caps (server-side only; never trust client).
local MAX_FORGE_AMOUNT = 25
local MAX_FORGE_STAT_LINES = 8
local MAX_FORGE_PCT = 100 -- fraction: 1.0 = +100%, clamped to this
--[[
	RESERVED ID PREFIX — admin-forged items
	========================================
	Prefix: "adm_"
	  • creationId  = "adm_c_" .. 12 hex chars   (one id per forge action)
	  • instance id = "adm_" .. 12 hex .. "_" .. 4 hex copy index
	Normal loot / rolls / mint helpers use 16-char hex ONLY and MUST NEVER
	emit ids starting with "adm_". This namespace is reserved so admin customs
	cannot collide with or be overwritten by content generation.
]]
local ADMIN_ITEM_ID_PREFIX = "adm_"
local ADMIN_CREATION_PREFIX = "adm_c_"

local MineAdmin = {}

local function clampInt(n, lo, hi)
	n = math.floor(tonumber(n) or 0)
	if lo then n = math.max(lo, n) end
	if hi then n = math.min(hi, n) end
	return n
end

local function payloadPreview(payload)
	if type(payload) ~= "table" then
		return tostring(payload)
	end
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, payload)
	if ok then
		if #encoded > 240 then
			return string.sub(encoded, 1, 240) .. "…"
		end
		return encoded
	end
	return "{…}"
end

local function adminLog(userId, action, payload)
	print(string.format(
		"[MineAdmin] userId=%s action=%s payload=%s",
		tostring(userId),
		tostring(action),
		payloadPreview(payload)
	))
end

function MineAdmin.start(deps)
	assert(type(deps) == "table", "MineAdmin.start needs deps")
	assert(deps.profiles, "MineAdmin.start needs profiles")
	assert(deps.snap, "MineAdmin.start needs snap")
	assert(deps.Packs, "MineAdmin.start needs Packs")
	assert(deps.Cards, "MineAdmin.start needs Cards")
	assert(deps.C, "MineAdmin.start needs C")

	local profiles = deps.profiles
	local snap = deps.snap
	local markDirty = deps.markDirty
	local Packs = deps.Packs
	local Cards = deps.Cards
	local C = deps.C
	local givePickaxe = deps.givePickaxe
	local giveBackpackModel = deps.giveBackpackModel
	local equippedTool = deps.equippedTool
	-- Optional: `/admin launch now` reports a clear error rather than failing
	-- silently if MineServer ever stops passing it.
	local launchSeason = deps.launchSeason

	local mineFolder = RS:WaitForChild("Mine")
	local remotes = mineFolder:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = mineFolder

	local readyEv = remotes:FindFirstChild("AdminReady") or Instance.new("RemoteEvent")
	readyEv.Name = "AdminReady"
	readyEv.Parent = remotes

	local notifyEv = remotes:FindFirstChild("AdminNotify") or Instance.new("RemoteEvent")
	notifyEv.Name = "AdminNotify"
	notifyEv.Parent = remotes

	local invokeFn = remotes:FindFirstChild("AdminInvoke") or Instance.new("RemoteFunction")
	invokeFn.Name = "AdminInvoke"
	invokeFn.Parent = remotes

	local rateBuckets = {}
	local unauthStrikes = {}
	local chatDedupe = {}

	local function rateOk(userId)
		local now = os.clock()
		local bucket = rateBuckets[userId]
		if not bucket or (now - bucket.t0) >= 60 then
			rateBuckets[userId] = { t0 = now, count = 1 }
			return true
		end
		if bucket.count >= MAX_GRANTS_PER_MINUTE then
			return false
		end
		bucket.count += 1
		return true
	end

	local function pushReady(plr)
		if not plr or not plr.Parent then
			return
		end
		readyEv:FireClient(plr, Allowlist.isAdmin(plr.UserId))
	end

	local function setIds()
		local ids = {}
		for id in pairs(Cards.SETS or {}) do
			table.insert(ids, id)
		end
		table.sort(ids)
		return ids
	end

	local function grantPack(p, packId, qty)
		packId = tostring(packId or "")
		-- Lucky blocks are named by block id with an optional grade,
		-- "lucky_block" or "lucky_block:B", and granted as blocks, not packs.
		local blockId, grade = packId:match("^([%w_]+):?(%u*)$")
		local LuckyBlocks = require(RS.Mine.Shared.MineLuckyBlocks)
		if blockId and LuckyBlocks.def(blockId) then
			local Grades = require(RS.Mine.Shared.MineToolGrades)
			grade = (grade ~= "" and grade) or "F"
			if Grades.ORDER[Grades.rankOf(grade)] ~= grade then
				return false, "unknown_grade"
			end
			qty = clampInt(qty, 1, MAX_PACK_QTY)
			LuckyBlocks.grant(p, blockId, grade, qty)
			return true, qty
		end
		local def = Packs.PACK_BY_ID and Packs.PACK_BY_ID[packId]
		if not def then
			return false, "unknown_pack"
		end
		qty = clampInt(qty, 1, MAX_PACK_QTY)
		local ids = setIds()
		local rng = Random.new()
		p.packs = p.packs or {}
		for _ = 1, qty do
			table.insert(p.packs, {
				packId = packId,
				packName = def.name or packId,
				setId = (#ids > 0) and ids[rng:NextInteger(1, #ids)] or "dragons_dawn",
			})
		end
		return true, qty
	end

	local function addCurrency(p, field, amount)
		amount = clampInt(amount, -MAX_CURRENCY, MAX_CURRENCY)
		if amount == 0 then
			return 0
		end
		local cur = tonumber(p[field]) or 0
		local nextV = cur + amount
		if nextV < 0 then
			nextV = 0
		end
		if nextV > MAX_CURRENCY then
			nextV = MAX_CURRENCY
		end
		p[field] = nextV
		return amount
	end

	local function handleGrant(plr, payload)
		local p = profiles[plr.UserId]
		if not p then
			return { ok = false, err = "no_profile" }
		end
		if type(payload) ~= "table" then
			return { ok = false, err = "bad_payload" }
		end

		local changed = {}

		if payload.coins ~= nil then
			changed.coins = addCurrency(p, "coins", payload.coins)
		end
		if payload.gems ~= nil then
			changed.gems = addCurrency(p, "gems", payload.gems)
		end
		if payload.dust ~= nil then
			changed.dust = addCurrency(p, "dust", payload.dust)
		end
		if payload.credits ~= nil then
			changed.credits = addCurrency(p, "credits", payload.credits)
		end
		if payload.skillPoints ~= nil then
			changed.skillPoints = addCurrency(p, "skillEarned", payload.skillPoints)
		end
		if payload.temperTokens ~= nil then
			changed.temperTokens = addCurrency(p, "temperTokens", payload.temperTokens)
		end

		if payload.packId then
			local okPack, detail = grantPack(p, payload.packId, payload.packQty or 1)
			if not okPack then
				return { ok = false, err = detail }
			end
			changed.packId = tostring(payload.packId)
			changed.packQty = detail
		end

		if payload.maxUnlockedZone ~= nil then
			local zoneCount = #(C.ZONES or {})
			local z = clampInt(payload.maxUnlockedZone, 1, math.min(zoneCount > 0 and zoneCount or MAX_ZONE, MAX_ZONE))
			p.maxUnlockedZone = z
			if C.ZONES and C.ZONES[z] then
				p.zoneId = C.ZONES[z].id
			end
			changed.maxUnlockedZone = z
		end

		if payload.prestige ~= nil then
			p.prestige = clampInt(payload.prestige, 0, 9999)
			changed.prestige = p.prestige
		end

		if type(payload.tool) == "string" and payload.tool ~= "" then
			local fam = tostring(payload.tool)
			local tier = clampInt(payload.toolTier or 1, 1, 99)
			p.tools = p.tools or { pickaxe = 1, drill = 0, explosive = 0 }
			if equippedTool then
				equippedTool(p)
			end
			if p.tools[fam] ~= nil or fam == "pickaxe" or fam == "hammer" or fam == "drill" or fam == "explosive" then
				p.tools[fam] = tier
				p.toolFamily = fam
				p.toolEquipped = true
				if fam == "pickaxe" then
					p.pickaxeTier = tier
				end
				if givePickaxe then
					givePickaxe(plr)
				end
				if giveBackpackModel then
					giveBackpackModel(plr)
				end
				changed.tool = fam
				changed.toolTier = tier
			else
				return { ok = false, err = "unknown_tool_family" }
			end
		end

		if type(payload.gearHatId) == "string" and payload.gearHatId ~= "" then
			local Hats = require(RS.Mine.Shared.MineHats)
			local Gear = require(RS.Mine.Shared.MineGear)
			local def = Hats.BY_ID[payload.gearHatId]
			if not def or (def.kind and def.kind ~= "Hat") then
				return { ok = false, err = "unknown_hat" }
			end
			local piece = Gear.makePiece(
				HttpService:GenerateGUID(false),
				def.setId,
				"hat",
				def.grade,
				def
			)
			if not piece then
				return { ok = false, err = "hat_make_failed" }
			end
			p.gear = p.gear or {}
			table.insert(p.gear, piece)
			changed.gearHatId = def.id
		end

		if type(payload.gearFaceId) == "string" and payload.gearFaceId ~= "" then
			local Hats = require(RS.Mine.Shared.MineHats)
			local Gear = require(RS.Mine.Shared.MineGear)
			local def = Hats.BY_ID[payload.gearFaceId]
			if not def or def.kind ~= "Face" then
				return { ok = false, err = "unknown_face" }
			end
			local piece = Gear.makePiece(
				HttpService:GenerateGUID(false),
				def.setId,
				"face",
				def.grade,
				def
			)
			if not piece then
				return { ok = false, err = "face_make_failed" }
			end
			p.gear = p.gear or {}
			table.insert(p.gear, piece)
			changed.gearFaceId = def.id
		end

		if type(payload.temperId) == "string" and payload.temperId ~= "" then
			local Temper = require(RS.Mine.Shared.MineTemper)
			local kit = Temper.kit(payload.temperId)
			if not kit then
				return { ok = false, err = "unknown_temper" }
			end
			local rarity = Temper.normalizeRarity(payload.temperRarity) or kit.rarity or "F"
			p.tempers = p.tempers or {}
			local row = p.tempers[kit.id]
			if row then
				row.rarity = Temper.betterGrade(row.rarity, rarity)
				row.n = math.max(1, (tonumber(row.n) or 1) + 1)
			else
				p.tempers[kit.id] = { rarity = rarity, n = 1 }
			end
			changed.temperId = kit.id
			changed.temperRarity = rarity
		end

		if type(payload.namedToolId) == "string" and payload.namedToolId ~= "" then
			local ToolsMod = require(RS.Mine.Shared.MineTools)
			local toolId = tostring(payload.namedToolId)
			local ct = ToolsMod.chestTool(toolId) or ToolsMod.passTool(toolId)
			if ct then
				p.chestTools = p.chestTools or {}
				local already = false
				for _, row in ipairs(p.chestTools) do
					if ((type(row) == "table") and row.id or row) == ct.id then
						already = true
						break
					end
				end
				if not already then
					table.insert(p.chestTools, {
						id = ct.id, name = ct.name, family = ct.family,
						rarity = ct.rarity or ct.rarityId,
						rarityId = ct.rarity or ct.rarityId,
						temperRolls = 0,
					})
				end
				changed.namedToolId = ct.id
			else
				local fam = tostring(payload.namedToolFamily or "")
				local tier = clampInt(payload.namedToolTier or payload.toolTier or 1, 1, 99)
				if fam ~= "pickaxe" and fam ~= "hammer" and fam ~= "drill" and fam ~= "explosive" then
					return { ok = false, err = "unknown_named_tool" }
				end
				p.tools = p.tools or { pickaxe = 1, drill = 0, explosive = 0 }
				p.tools[fam] = tier
				p.toolFamily = fam
				p.toolEquipped = true
				if fam == "pickaxe" then
					p.pickaxeTier = tier
				end
				if givePickaxe then
					givePickaxe(plr)
				end
				if giveBackpackModel then
					giveBackpackModel(plr)
				end
				changed.namedToolId = toolId
				changed.tool = fam
				changed.toolTier = tier
			end
		end

		if next(changed) == nil then
			return { ok = false, err = "empty_grant" }
		end

		if markDirty then
			markDirty(plr)
		end
		snap(plr)
		adminLog(plr.UserId, "grant", changed)
		return { ok = true, changed = changed }
	end

	invokeFn.OnServerInvoke = function(plr, action, payload)
		if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
			return { ok = false, err = "bad_player" }
		end

		action = tostring(action or "")

		-- Safe boolean probe for everyone. Never trust a client-sent admin flag;
		-- this only answers after a server-side UserId allowlist check.
		if action == "isAdmin" then
			return { ok = true, admin = Allowlist.isAdmin(plr.UserId) }
		end

		-- Always re-check UserId allowlist on every privileged invoke.
		if not Allowlist.isAdmin(plr.UserId) then
			unauthStrikes[plr.UserId] = (unauthStrikes[plr.UserId] or 0) + 1
			warn(string.format(
				"[MineAdmin] REJECT unauthorized userId=%s action=%s strikes=%d",
				tostring(plr.UserId),
				action,
				unauthStrikes[plr.UserId]
			))
			if unauthStrikes[plr.UserId] >= UNAUTH_KICK_AFTER then
				pcall(function()
					plr:Kick("Unauthorized admin remote use")
				end)
			end
			return { ok = false, err = "unauthorized" }
		end

		if action == "catalog" then
			local packs = {}
			for _, row in ipairs(Packs.PACKS or {}) do
				table.insert(packs, { id = row.id, name = row.name, kind = row.kind })
			end
			local zones = {}
			for i, z in ipairs(C.ZONES or {}) do
				table.insert(zones, { index = i, id = z.id, name = z.name })
			end
			local Hats = require(RS.Mine.Shared.MineHats)
			local Temper = require(RS.Mine.Shared.MineTemper)
			local ToolsMod = require(RS.Mine.Shared.MineTools)
			local hats = {}
			for _, h in ipairs(Hats.LIST or {}) do
				table.insert(hats, {
					id = h.id, name = h.name, catalogId = h.catalogId,
					rarity = h.rarity, grade = h.grade, rap = h.rap, setId = h.setId,
				})
			end
			local faces = {}
			for _, h in ipairs(Hats.LEFTOVERS or {}) do
				if h.kind == "Face" then
					table.insert(faces, {
						id = h.id, name = h.name, catalogId = h.catalogId,
						rarity = h.rarity, grade = h.grade, rap = h.rap, setId = h.setId,
					})
				end
			end
			local tempers = {}
			for id, kit in pairs(Temper.BY_ID or {}) do
				table.insert(tempers, {
					id = id, name = kit.name or id, rarity = kit.rarity, stats = kit.stats,
				})
			end
			table.sort(tempers, function(a, b)
				return tostring(a.name) < tostring(b.name)
			end)
			local tools = {}
			for _, t in ipairs(ToolsMod.CHEST_TOOLS or {}) do
				table.insert(tools, {
					id = t.id, name = t.name, family = t.family,
					rarity = t.rarity or t.rarityId, kind = "chest",
				})
			end
			for _, t in ipairs(ToolsMod.PASS_TOOLS or {}) do
				table.insert(tools, {
					id = t.id, name = t.name, family = t.family,
					rarity = t.rarity or t.rarityId, kind = "pass",
				})
			end
			for fam, list in pairs(ToolsMod.TOOLS or {}) do
				if type(list) == "table" then
					for tier, t in ipairs(list) do
						table.insert(tools, {
							id = t.id, name = t.name, family = fam,
							tier = tier, rarity = t.rarity, kind = "ladder",
						})
					end
				end
			end
			return {
				ok = true, packs = packs, zones = zones,
				hats = hats, faces = faces, tempers = tempers, tools = tools,
			}
		end

		if action == "refresh" then
			adminLog(plr.UserId, "refresh", {})
			snap(plr)
			return { ok = true }
		end

		if action == "unlockAllZonesDepths" then
			local p = profiles[plr.UserId]
			if not p then
				return { ok = false, err = "no_profile" }
			end
			local Cfg = deps.C
			local nZones = #(Cfg.ZONES or {})
			p.maxUnlockedZone = math.max(tonumber(p.maxUnlockedZone) or 1, nZones)
			p.bigbangOwned = true
			p.deepest = type(p.deepest) == "table" and p.deepest or {}
			for _, z in ipairs(Cfg.ZONES or {}) do
				p.deepest[tostring(z.id)] = math.max(tonumber(p.deepest[tostring(z.id)]) or 0, 5000)
			end
			local plazas = script.Parent.Parent:FindFirstChild("MineDepthPlazas")
			if plazas then
				local ok, mod = pcall(require, plazas)
				if ok and mod and mod.openAllForPreview then
					pcall(mod.openAllForPreview)
				end
			end
			if markDirty then markDirty(plr.UserId) end
			snap(plr)
			adminLog(plr.UserId, "unlockAllZonesDepths", { zones = nZones, deepest = 5000 })
			return { ok = true, zones = nZones }
		end

		--[[
			forgeItem — mint N custom gear copies into inventory for later trading.
			Payload (validated server-side; never trust client):
			  robloxAssetId, slot (hat|face), rarity (F..SSS),
			  stats ({stat,pct} or "luck:150,dirtBreak:80" percent points),
			  amount, optional itemName / targetUserId.
			IDs use reserved prefix adm_ / adm_c_ (see file header).
		]]
		if action == "forgeItem" then
			if not rateOk(plr.UserId) then
				return { ok = false, err = "rate_limited" }
			end
			if type(payload) ~= "table" then
				return { ok = false, err = "bad_payload" }
			end

			local target = plr
			if payload.targetUserId ~= nil then
				local tid = tonumber(payload.targetUserId)
				if not tid then
					return { ok = false, err = "bad_target" }
				end
				target = Players:GetPlayerByUserId(tid)
				if not target then
					return { ok = false, err = "target_offline" }
				end
			end
			local p = profiles[target.UserId]
			if not p then
				return { ok = false, err = "no_profile" }
			end

			local assetId = math.floor(tonumber(payload.robloxAssetId) or 0)
			if assetId <= 0 then
				return { ok = false, err = "bad_asset_id" }
			end

			local slot = string.lower(tostring(payload.slot or "hat"))
			if slot ~= "hat" and slot ~= "face" then
				return { ok = false, err = "bad_slot" }
			end

			local rarity = string.upper(tostring(payload.rarity or "SSS"))
			local Gear = require(RS.Mine.Shared.MineGear)
			if not Gear.RARITY_RANK or not Gear.RARITY_RANK[rarity] then
				return { ok = false, err = "bad_rarity" }
			end

			local Stats = require(RS.Mine.Shared.MineStats)
			local function parseStats(raw)
				local out = {}
				local function push(stat, pct)
					stat = tostring(stat or "")
					if not (Stats.STATS and Stats.STATS[stat]) then
						return false, "unknown_stat:" .. stat
					end
					pct = tonumber(pct)
					if not pct then
						return false, "bad_pct:" .. stat
					end
					if pct <= 0 or pct > MAX_FORGE_PCT then
						return false, "pct_out_of_range:" .. stat
					end
					table.insert(out, { stat = stat, pct = math.floor(pct * 10000 + 0.5) / 10000 })
					return true
				end
				if type(raw) == "string" then
					-- "luck:150,dirtBreak:80" — numbers are PERCENT POINTS (+150% → pct 1.5).
					for token in string.gmatch(raw, "[^,;]+") do
						local st, n = string.match(token, "^%s*([%w_]+)%s*[:=]%s*([%d%.]+)%s*$")
						if not st then
							return nil, "bad_stats_token"
						end
						local okPush, errPush = push(st, (tonumber(n) or 0) / 100)
						if not okPush then
							return nil, errPush
						end
					end
				elseif type(raw) == "table" then
					for _, row in ipairs(raw) do
						if type(row) == "table" then
							local pct = tonumber(row.pct)
							if row.percentPoints ~= nil then
								pct = (tonumber(row.percentPoints) or 0) / 100
							end
							local okPush, errPush = push(row.stat, pct)
							if not okPush then
								return nil, errPush
							end
						end
					end
				else
					return nil, "bad_stats"
				end
				if #out == 0 then
					return nil, "empty_stats"
				end
				if #out > MAX_FORGE_STAT_LINES then
					return nil, "too_many_stats"
				end
				return out
			end

			local stats, statsErr = parseStats(payload.stats)
			if not stats then
				return { ok = false, err = statsErr or "bad_stats" }
			end

			local amount = clampInt(payload.amount or 1, 1, MAX_FORGE_AMOUNT)
			local itemName = tostring(payload.itemName or "")
			if itemName == "" then
				itemName = string.format("Admin Item #%d", assetId)
			end
			if #itemName > 64 then
				itemName = string.sub(itemName, 1, 64)
			end

			local primary = stats[1]
			local setId, setName = "bedrock", "Bedrock"
			for _, s in ipairs(Gear.SETS or {}) do
				if s.stat == primary.stat then
					setId, setName = s.id, s.name
					break
				end
			end

			local hex = string.gsub(HttpService:GenerateGUID(false), "-", ""):lower()
			local creationId = ADMIN_CREATION_PREFIX .. string.sub(hex, 1, 12)
			local minted = {}
			p.gear = p.gear or {}
			for i = 1, amount do
				local copyHex = string.format("%04x", i)
				local instanceId = ADMIN_ITEM_ID_PREFIX .. string.sub(hex, 1, 12) .. "_" .. copyHex
				local statsCopy = {}
				for _, row in ipairs(stats) do
					table.insert(statsCopy, { stat = row.stat, pct = row.pct })
				end
				local piece = {
					id = instanceId,
					setId = setId,
					setName = setName,
					stat = primary.stat,
					slot = slot,
					rarity = rarity,
					pct = primary.pct,
					stats = statsCopy,
					slotCount = 1,
					mult = 0,
					sockets = {},
					catalogId = assetId,
					hatId = "admin_forge",
					itemName = itemName,
					kind = (slot == "face") and "Face" or "Hat",
					adminForged = true,
					adminCreationId = creationId,
					adminForgedBy = plr.UserId,
					adminForgedAt = os.time(),
					adminRobloxAssetId = assetId,
				}
				piece.name = (Gear.shopName and Gear.shopName(piece)) or itemName
				table.insert(p.gear, piece)
				table.insert(minted, instanceId)
			end

			if markDirty then
				markDirty(target)
			end
			snap(target)

			print(string.format(
				"###ADMIN ITEM### CREATE creationId=%s admin=%s(%d) target=%s(%d) asset=%d slot=%s rarity=%s amount=%d ids=%s stats=%s",
				creationId,
				plr.Name,
				plr.UserId,
				target.Name,
				target.UserId,
				assetId,
				slot,
				rarity,
				amount,
				table.concat(minted, ","),
				payloadPreview(stats)
			))
			adminLog(plr.UserId, "forgeItem", {
				creationId = creationId,
				targetUserId = target.UserId,
				targetName = target.Name,
				robloxAssetId = assetId,
				slot = slot,
				rarity = rarity,
				stats = stats,
				amount = amount,
				itemName = itemName,
				instanceIds = minted,
			})
			return { ok = true, creationId = creationId, instanceIds = minted, amount = amount }
		end

		if action == "grant" then
			if not rateOk(plr.UserId) then
				return { ok = false, err = "rate_limited" }
			end
			local target = plr
			if type(payload) == "table" and payload.targetUserId ~= nil then
				local tid = tonumber(payload.targetUserId)
				if not tid then
					return { ok = false, err = "bad_target" }
				end
				target = Players:GetPlayerByUserId(tid)
				if not target then
					return { ok = false, err = "target_offline" }
				end
			end
			local okCall, result = pcall(handleGrant, target, payload)
			if not okCall then
				warn("[MineAdmin] grant error: " .. tostring(result))
				return { ok = false, err = "server_error" }
			end
			if result and result.ok then
				adminLog(plr.UserId, "grant_to", {
					targetUserId = target.UserId,
					targetName = target.Name,
					changed = result.changed,
				})
			end
			return result
		end

		if action == "resetSave" then
			if not rateOk(plr.UserId) then
				return { ok = false, err = "rate_limited" }
			end
			if type(payload) ~= "table" or tostring(payload.confirm) ~= "RESET" then
				return { ok = false, err = "confirm_required" }
			end
			local blankFn = deps.blank
			local saveFn = deps.save
			if type(blankFn) ~= "function" or type(saveFn) ~= "function" then
				return { ok = false, err = "reset_unavailable" }
			end
			local fresh = blankFn()
			profiles[plr.UserId] = fresh
			if markDirty then
				markDirty(plr)
			end
			saveFn(plr)
			adminLog(plr.UserId, "resetSave", { userId = plr.UserId })
			task.defer(function()
				pcall(function()
					plr:Kick("Save reset. Rejoin to start fresh.")
				end)
			end)
			return { ok = true }
		end

		return { ok = false, err = "unknown_action" }
	end

	local function notifyAdmin(admin, msg)
		msg = tostring(msg or "")
		print(string.format("[MineAdminChat] admin=%s(%d) %s", admin.Name, admin.UserId, msg))
		pcall(function()
			notifyEv:FireClient(admin, msg)
		end)
	end

	-- Target by numeric UserId OR exact Username. Never DisplayName / nickname.
	local function resolveTarget(token)
		token = tostring(token or "")
		local asId = tonumber(token)
		if asId then
			return Players:GetPlayerByUserId(asId)
		end
		local lower = string.lower(token)
		for _, p in ipairs(Players:GetPlayers()) do
			if string.lower(p.Name) == lower then
				return p
			end
		end
		return nil
	end

	local CURRENCY_KEYS = {
		credits = "credits",
		coins = "coins",
		gems = "gems",
		dust = "dust",
		skill = "skillPoints",
		skillpoints = "skillPoints",
		temper = "temperTokens",
		tempertokens = "temperTokens",
	}

	local function handleAdminChat(admin, raw)
		-- Authorization is UserId allowlist ONLY — never names/nicknames.
		if not Allowlist.isAdmin(admin.UserId) then
			return false
		end

		raw = string.gsub(tostring(raw or ""), "^%s+", "")
		raw = string.gsub(raw, "%s+$", "")
		-- Dedupe Chatted + TextChatCommand double-fire.
		local dedupeKey = tostring(admin.UserId) .. "|" .. string.lower(raw)
		local now = os.clock()
		if chatDedupe[dedupeKey] and (now - chatDedupe[dedupeKey]) < 0.5 then
			return true
		end
		chatDedupe[dedupeKey] = now
		local lower = string.lower(raw)
		local body = nil
		if lower == "/admin" or lower == "/mineadmin" then
			body = "help"
		elseif string.sub(lower, 1, 11) == "/mineadmin " then
			body = string.sub(raw, 12)
		elseif string.sub(lower, 1, 7) == "/admin " then
			body = string.sub(raw, 8)
		else
			return false
		end

		if not rateOk(admin.UserId) then
			notifyAdmin(admin, "rate limited")
			return true
		end

		local args = {}
		for token in string.gmatch(body, "%S+") do
			table.insert(args, token)
		end
		local cmd = string.lower(args[1] or "help")

		if cmd == "help" or cmd == "?" then
			notifyAdmin(admin, "/admin give <userId|Username|me> credits|coins|gems|dust|skill|temper <n>")
			notifyAdmin(admin, "/admin give <who> pack <packId> [qty] | zone <n> | tool <family> [tier]")
			notifyAdmin(admin, "/admin alltools [start] [count]  |  /admin alltools all   -- named tools into YOUR bag")
			-- No tool count here: it was "246" (3 families x 82 ores) and went
			-- stale the day hammers shipped. The command reports what it forged.
			notifyAdmin(admin, "/admin oretools [all|pickaxe|hammer|drill|explosive]  -- forge every ore tool in a family (bypasses the 200 cap)")
			notifyAdmin(admin, "/admin say <message>[|seconds]  -- banner on every player's screen")
			notifyAdmin(admin, "/admin launch status   -- is the season running, and how far in")
			notifyAdmin(admin, "/admin launch now      -- THROW THE SWITCH. Starts the season. Not undoable.")
			return true
		end

		--[[
			THE LAUNCH SWITCH. Without this the game could never start.

			MineLaunch pins seasonNow() to SEASON_START until launchedAt is set,
			and Verbs.launchSeason is the only thing that sets it -- correctly
			written, admin-gated, persisted. Nothing anywhere fired it. No
			client file contains the string and MineAdminClient has no
			FireServer calls at all, so the entire launch design was wired to
			nothing at the one point that mattered: rotating offers frozen on
			slot one forever, the battle pass never counting down, the Event
			Horizon window never opening or closing, the teaser rolling over
			for eternity.

			It is a chat command rather than a button because it must be hard
			to hit by accident. There is no unlaunch -- rewinding would re-lock
			what players earned -- so `now` is required as a second word and
			the bare `/admin launch` reports status instead of firing.
		]]
		if cmd == "launch" then
			local okL, Launch = pcall(function()
				return require(game:GetService("ReplicatedStorage")
					:WaitForChild("Mine"):WaitForChild("Shared"):WaitForChild("MineLaunch"))
			end)
			if not okL or not Launch then
				notifyAdmin(admin, "MineLaunch failed to load -- cannot launch")
				return true
			end
			local sub = string.lower(args[2] or "status")
			if Launch.isLaunched() then
				notifyAdmin(admin, string.format("Season is LIVE -- %.2f days in (launched at %d)",
					Launch.elapsed() / 86400, Launch.launchedAt))
				return true
			end
			if sub ~= "now" then
				notifyAdmin(admin, "Season is NOT launched. Everything seasonal sits at second zero.")
				notifyAdmin(admin, "Type  /admin launch now  to start it. This cannot be undone.")
				return true
			end
			--[[
				Through the deps table, not a remote. Verbs.launchSeason owns
				the whole operation -- the admin re-check, the already-launched
				guard, the datastore write BEFORE the announcement, and the
				broadcast -- so this must call it rather than reimplement any
				part of it. A second copy of "throw the switch" is how a game
				gets launched twice with two different timestamps.
			]]
			if type(launchSeason) ~= "function" then
				notifyAdmin(admin, "launchSeason was not passed to MineAdmin.start -- cannot launch")
				return true
			end
			launchSeason(admin)
			return true
		end

		if cmd == "give" then
			local who = args[2]
			if not who then
				notifyAdmin(admin, "usage: /admin give <userId|Username|me> …")
				return true
			end
			local target
			if string.lower(who) == "me" then
				target = admin
			else
				target = resolveTarget(who)
			end
			if not target then
				notifyAdmin(admin, "target offline / not found — use UserId or exact Username (not DisplayName)")
				return true
			end

			local what = string.lower(args[3] or "")
			local payload = {}
			if CURRENCY_KEYS[what] then
				local amt = tonumber(args[4])
				if not amt then
					notifyAdmin(admin, "need amount")
					return true
				end
				payload[CURRENCY_KEYS[what]] = amt
			elseif what == "pack" then
				payload.packId = args[4]
				payload.packQty = tonumber(args[5]) or 1
				if not payload.packId then
					notifyAdmin(admin, "need packId")
					return true
				end
			elseif what == "zone" then
				payload.maxUnlockedZone = tonumber(args[4])
				if not payload.maxUnlockedZone then
					notifyAdmin(admin, "need zone number")
					return true
				end
			elseif what == "tool" then
				payload.tool = args[4]
				payload.toolTier = tonumber(args[5]) or 1
				if not payload.tool then
					notifyAdmin(admin, "need tool family")
					return true
				end
			else
				notifyAdmin(admin, "unknown type '" .. what .. "' — try credits/pack/zone/tool")
				return true
			end

			local okCall, result = pcall(handleGrant, target, payload)
			if not okCall then
				notifyAdmin(admin, "server_error: " .. tostring(result))
				return true
			end
			if result and result.ok then
				notifyAdmin(admin, string.format(
					"ok → %s (%d) %s",
					target.Name,
					target.UserId,
					payloadPreview(result.changed)
				))
			else
				notifyAdmin(admin, "fail: " .. tostring(result and result.err))
			end
			return true
		end

		--[[
			/admin alltools [start] [count]   or   /admin alltools all

			Drops named chest tools straight into your own chestTools so you can
			flip through them in the inventory and find a bad one.

			PAGED ON PURPOSE. MineTools.CHEST_TOOLS is 1,624 rows; putting all of
			them in one profile writes a very large save and makes every snapshot
			carry the lot from then on. "all" is there if you want it, but the
			default page is 150 and the reply tells you the next command to run.
		]]
		--[[
			A word on every screen at once.
		
			Goes out over MineNet (the main channel the client already listens on)
			rather than the admin remotes, because AdminNotify is only ever fired at
			the one admin who typed the command -- everyone else is not connected to it.
		]]
		if cmd == "say" or cmd == "broadcast" or cmd == "announce" then
			local text = string.match(body, "^%S+%s+(.*)$")
			if not text or text == "" then
				notifyAdmin(admin, "usage: /admin say <message>   (optionally end with |<seconds>)")
				return true
			end
			-- "…|12" sets how long it stays up.
			local secs = tonumber(string.match(text, "|%s*(%d+)%s*$"))
			if secs then
				text = string.gsub(text, "|%s*%d+%s*$", "")
			end
			text = string.gsub(text, "%s+$", "")
			local mineNet = remotes:FindFirstChild("MineNet")
			if not mineNet then
				notifyAdmin(admin, "MineNet remote missing -- is the server script running?")
				return true
			end
			mineNet:FireAllClients("adminBroadcast", {
				text = text,
				secs = secs or 8,
				title = "ANNOUNCEMENT",
			})
			print(string.format("[MineAdminChat] BROADCAST by %s(%d): %s", admin.Name, admin.UserId, text))
			notifyAdmin(admin, string.format("broadcast to %d player(s) for %ds",
				#game:GetService("Players"):GetPlayers(), secs or 8))
			return true
		end
		
		--[[
			EVERY FORGED ORE TOOL, FOR TESTING. Owner, 2026-10-10: "GIVE ME
			EVERY SINGLE TOOLS TO MY INVENTORY."

			`alltools` above grants CHEST tools -- the named found ones. It
			does not touch the 246 FORGED tools, which are the real roster:
			82 ores x pickaxe / drill / explosive. Those only ever existed by
			crafting one at a time out of ore.

			`/admin oretools [family]` forges one of each. No family means all
			three.

			IT BYPASSES THE 200 RACK CAP, which normal crafting enforces at
			MineServer's craft verb. 246 does not fit in 200, and the cap is
			there to keep a real profile's save small -- an admin asking for
			the whole roster has said what they want. The count is reported so
			it is obvious what just landed.

			Rows are built in the same shape the craft verb stamps --
			uid / typeId / familyId / tier / level / base -- because
			equippedTool, the Forge and recycle all read those fields by name.
			`base` equals `level` so these grant tools refund NOTHING on
			scrap, which is correct: no ore was spent on them.
		]]
		if cmd == "oretools" then
			local p = profiles[admin.UserId]
			if not p then
				notifyAdmin(admin, "no profile loaded yet")
				return true
			end
			local okO, OreTools = pcall(function()
				return require(RS.Mine.Shared.MineOreTools)
			end)
			if not okO or not OreTools then
				notifyAdmin(admin, "MineOreTools failed to load")
				return true
			end
			local want = string.lower(tostring(args[2] or "all"))
			--[[
				Read from MineOreTools.FAMILY_ORDER rather than listing the
				families here. This said { pickaxe, drill, explosive } and
				silently skipped hammers the day they shipped -- "all tools"
				that quietly means "all but one family" is the worst kind of
				admin command. A fifth family now needs no edit here.
			]]
			local fams = (want == "all")
					and (OreTools.FAMILY_ORDER or { "pickaxe", "drill", "explosive" })
				or (want == "pickaxe" or want == "hammer" or want == "drill" or want == "explosive") and { want }
				or nil
			if not fams then
				notifyAdmin(admin, "usage: /admin oretools [" .. table.concat(OreTools.FAMILY_ORDER or {}, "|") .. "|all]")
				return true
			end
			p.oreTools = p.oreTools or {}
			-- Do not duplicate what is already racked.
			local have = {}
			for _, t in ipairs(p.oreTools) do
				if type(t) == "table" then
					have[tostring(t.familyId) .. "#" .. tostring(t.tier)] = true
				end
			end
			local added = 0
			for _, fam in ipairs(fams) do
				for _, ore in ipairs(C.ORES or {}) do
					local key = fam .. "#" .. tostring(ore.tier)
					if not have[key] then
						have[key] = true
						local def = OreTools.frameForTier and OreTools.frameForTier(fam, ore.tier)
						table.insert(p.oreTools, {
							uid = string.format("%08x%08x", math.random(0, 2 ^ 31 - 1), math.random(0, 2 ^ 31 - 1)),
							typeId = (def and def.id) or (fam .. "_" .. tostring(ore.tier)),
							familyId = fam,
							tier = ore.tier,
							level = 1,
							base = 1,
						})
						added += 1
					end
				end
			end
			if markDirty then
				markDirty(admin)
			end
			snap(admin)
			notifyAdmin(admin, string.format("oretools: +%d forged. Rack now %d (normal cap is 200).",
				added, #p.oreTools))
			return true
		end

		if cmd == "alltools" then
			local p = profiles[admin.UserId]
			if not p then
				notifyAdmin(admin, "no profile loaded yet")
				return true
			end
			local ToolsMod = require(RS.Mine.Shared.MineTools)
			local list = ToolsMod.CHEST_TOOLS or {}
			if #list == 0 then
				notifyAdmin(admin, "no CHEST_TOOLS catalog")
				return true
			end
			local wantAll = string.lower(tostring(args[2] or "")) == "all"
			local from = wantAll and 1 or math.max(1, math.floor(tonumber(args[2]) or 1))
			local count = wantAll and #list or math.clamp(math.floor(tonumber(args[3]) or 150), 1, 400)
			local last = math.min(#list, from + count - 1)
			p.chestTools = p.chestTools or {}
			local have = {}
			for _, row in ipairs(p.chestTools) do
				have[(type(row) == "table") and row.id or row] = true
			end
			local added = 0
			for i = from, last do
				local ct = list[i]
				if ct and ct.id and not have[ct.id] then
					have[ct.id] = true
					table.insert(p.chestTools, {
						id = ct.id,
						name = ct.name,
						family = ct.family,
						rarity = ct.rarity or ct.rarityId,
						rarityId = ct.rarity or ct.rarityId,
						temperRolls = 0,
					})
					added += 1
				end
			end
			if markDirty then
				markDirty(admin)
			end
			snap(admin)
			notifyAdmin(admin, string.format("alltools: +%d (rows %d-%d of %d). Holding %d.",
				added, from, last, #list, #p.chestTools))
			if last < #list then
				notifyAdmin(admin, string.format("next: /admin alltools %d %d", last + 1, count))
			end
			return true
		end

		notifyAdmin(admin, "unknown cmd — /admin help")
		return true
	end

	local function hookChat(plr)
		plr.Chatted:Connect(function(msg)
			handleAdminChat(plr, msg)
		end)
	end

	local function hook(plr)
		hookChat(plr)
		task.defer(function()
			task.wait(0.35)
			pushReady(plr)
		end)
	end

	-- TextChatService command (modern chat). Still gated by UserId allowlist.
	pcall(function()
		local TextChatService = game:GetService("TextChatService")
		local cmd = TextChatService:FindFirstChild("MineAdminCommand")
		if not cmd then
			cmd = Instance.new("TextChatCommand")
			cmd.Name = "MineAdminCommand"
			cmd.PrimaryAlias = "/admin"
			cmd.SecondaryAlias = "/mineadmin"
			cmd.Parent = TextChatService
		end
		cmd.Triggered:Connect(function(textSource, unfilteredText)
			local speaker = Players:GetPlayerByUserId(textSource.UserId)
			if not speaker then
				return
			end
			local text = tostring(unfilteredText or "")
			if string.sub(string.lower(text), 1, 6) ~= "/admin" and string.sub(string.lower(text), 1, 10) ~= "/mineadmin" then
				text = "/admin " .. text
			end
			handleAdminChat(speaker, text)
		end)
	end)

	Players.PlayerAdded:Connect(hook)
	for _, plr in ipairs(Players:GetPlayers()) do
		hook(plr)
	end

	Players.PlayerRemoving:Connect(function(plr)
		rateBuckets[plr.UserId] = nil
		unauthStrikes[plr.UserId] = nil
	end)

	print("[MineAdmin] started (UserId allowlist + /admin chat grants)")
end

return MineAdmin
