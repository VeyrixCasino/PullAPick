-- Surface shop ladder purchases (MineShopLadders desk == surface).
-- Kept out of MineServer to avoid local-register pressure.

local shared = script.Parent

local MineShopBuy = {}

function MineShopBuy.buyEvent(plr, p, toolId, deps)
	local net = deps.net
	local snap = deps.snap
	local givePickaxe = deps.givePickaxe
	local okH, Horizon = pcall(function()
		return require(shared:WaitForChild("MineHorizonTools"))
	end)
	local tool = okH and Horizon and Horizon.byId(toolId)
	if not tool then
		net:FireClient(plr, "toast", "Unknown event tool")
		return true
	end
	if p.zoneId ~= "bigbang" then
		net:FireClient(plr, "toast", "Event tools are sold in Event Horizon")
		return true
	end
	local needDepth = math.floor(tonumber(tool.minDepth) or 0)
	local gotDepth = (p.deepest and p.deepest.bigbang) or 0
	if needDepth > gotDepth then
		net:FireClient(plr, "toast", "Reach depth " .. tostring(needDepth) .. " to unlock these shop options.")
		return true
	end
	p.eventTools = p.eventTools or {}
	if p.eventTools[tool.id] then
		p.eventToolId = tool.id
		net:FireClient(plr, "toast", "Equipped " .. tool.name)
		if givePickaxe then givePickaxe(plr) end
		if snap then snap(plr) end
		return true
	end
	local price = math.floor(tonumber(tool.price) or 0)
	if price > 0 and (p.spaceCoins or 0) < price then
		net:FireClient(plr, "toast", string.format("%s costs %s space", tool.name, tostring(price)))
		return true
	end
	if price > 0 then
		p.spaceCoins = (p.spaceCoins or 0) - price
	end
	p.eventTools[tool.id] = true
	p.eventToolId = tool.id
	p.toolEquipped = true
	p.chestTool = nil
	net:FireClient(plr, "toast", "Bought " .. tool.name .. " — Event Horizon only")
	if givePickaxe then givePickaxe(plr) end
	if snap then snap(plr) end
	return true
end

function MineShopBuy.buySurface(plr, p, payload, deps)
	if type(payload) ~= "table" or not payload.toolId then
		return false
	end
	if string.sub(tostring(payload.toolId), 1, 3) == "eh_" then
		return MineShopBuy.buyEvent(plr, p, tostring(payload.toolId), deps)
	end
	local ShopLadders = deps.ShopLadders
	local C = deps.C
	local net = deps.net
	local givePickaxe = deps.givePickaxe
	local giveBackpackModel = deps.giveBackpackModel
	local introAdvance = deps.introAdvance
	local snap = deps.snap

	local toolId = tostring(payload.toolId)
	local row = ShopLadders.byId(toolId)
	if not row or row.desk ~= "surface" then
		net:FireClient(plr, "toast", "Not sold at this shop")
		return true
	end
	local needZone = math.floor(tonumber(row.zoneIndex) or 1)
	if needZone > (p.maxUnlockedZone or 1) then
		local zone = C.ZONES[needZone]
		net:FireClient(plr, "toast", "Unlock " .. (zone and zone.name or ("zone " .. needZone)) .. " first")
		return true
	end
	p.ownedShopTools = p.ownedShopTools or {}
	if p.ownedShopTools[toolId] then
		net:FireClient(plr, "toast", "You already own " .. (row.name or toolId))
		return true
	end
	local price = math.floor(tonumber(row.price) or 0)
	if (p.coins or 0) < price then
		net:FireClient(plr, "toast", string.format("%s costs %s coins", row.name or toolId, tostring(price)))
		return true
	end
	p.coins -= price
	p.ownedShopTools[toolId] = true
	p.shopToolId = toolId
	p.toolFamily = row.family or "pickaxe"
	p.toolEquipped = true
	p.chestTool = nil
	givePickaxe(plr)
	giveBackpackModel(plr)
	if introAdvance then introAdvance(plr, p, 3) end
	-- A rune socketed into this tool before a rebirth is still in its slot.
	local waiting = p.shopToolRunes and p.shopToolRunes[toolId]
	net:FireClient(plr, "toast", "Bought " .. (row.name or toolId)
		.. (waiting and " — your rune is still in its slot" or ""))
	snap(plr)
	return true
end

function MineShopBuy.equip(plr, p, payload, deps)
	if type(payload) ~= "table" then return end
	local ShopLadders = deps.ShopLadders
	local net = deps.net
	local givePickaxe = deps.givePickaxe
	local giveBackpackModel = deps.giveBackpackModel
	local snap = deps.snap
	local id = tostring(payload.id or payload.toolId or "")
	if string.sub(id, 1, 3) == "eh_" then
		MineShopBuy.buyEvent(plr, p, id, deps)
		return
	end
	p.ownedShopTools = p.ownedShopTools or {}
	if id == "" or not p.ownedShopTools[id] then
		net:FireClient(plr, "toast", "You do not own that tool")
		return
	end
	local row = ShopLadders.byId(id)
	if not row then
		net:FireClient(plr, "toast", "Unknown tool")
		return
	end
	p.shopToolId = id
	p.chestTool = nil
	p.toolFamily = row.family or "pickaxe"
	p.toolEquipped = true
	givePickaxe(plr)
	giveBackpackModel(plr)
	snap(plr)
end

return MineShopBuy
