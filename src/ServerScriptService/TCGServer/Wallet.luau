--!strict
local Wallet = {}
Wallet.FOLDER_NAME = 'Wallet'
Wallet.CURRENCIES = { 'Cash', 'Coins', 'Gems', 'FusionDust' }
Wallet.STARTING_COINS = 2500
local function ensureFolder(player)
	local legacy = player:FindFirstChild('leaderstats')
	if legacy then legacy:Destroy() end
	local folder = player:FindFirstChild(Wallet.FOLDER_NAME)
	if not folder then
		folder = Instance.new('Folder')
		folder.Name = Wallet.FOLDER_NAME
		folder.Parent = player
	end
	return folder
end
function Wallet.ensure(player)
	local ls = ensureFolder(player)
	for _, name in ipairs(Wallet.CURRENCIES) do
		if not ls:FindFirstChild(name) then
			local v = Instance.new('IntValue')
			v.Name = name
			v.Value = 0
			v.Parent = ls
		end
	end
	return ls
end
function Wallet.value(player, currency)
	local ls = Wallet.ensure(player)
	local v = ls:FindFirstChild(currency)
	if v and v:IsA('IntValue') then return v end
	return nil
end
function Wallet.get(player, currency)
	local v = Wallet.value(player, currency)
	return v and v.Value or 0
end
function Wallet.add(player, currency, amount)
	local v = Wallet.value(player, currency)
	if not v then return false end
	local delta = math.floor(tonumber(amount) or 0)
	if delta == 0 then return true end
	v.Value = math.max(0, v.Value + delta)
	return true
end
function Wallet.snapshot(player)
	local out = {}
	for _, name in ipairs(Wallet.CURRENCIES) do out[name] = Wallet.get(player, name) end
	return out
end
local DataStoreService = game:GetService('DataStoreService')
local dataStore = nil
pcall(function() dataStore = DataStoreService:GetDataStore('TCGPlayerWallet_v1') end)
function Wallet.loadAsync(player)
	Wallet.ensure(player)
	if not dataStore then return end
	local ok, saved = pcall(function() return dataStore:GetAsync(tostring(player.UserId)) end)
	if ok and type(saved) == 'table' then
		for _, name in ipairs(Wallet.CURRENCIES) do
			local amount = tonumber(saved[name])
			if amount then
				local v = Wallet.value(player, name)
				if v then v.Value = math.max(0, math.floor(amount)) end
			end
		end
	elseif ok then
		local coins = Wallet.value(player, 'Coins')
		if coins then coins.Value = Wallet.STARTING_COINS end
		task.spawn(Wallet.saveAsync, player)
	end
end
function Wallet.saveAsync(player)
	if not dataStore then return end
	local snapshot = Wallet.snapshot(player)
	pcall(function() dataStore:SetAsync(tostring(player.UserId), snapshot) end)
end
return Wallet
