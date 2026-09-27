-- AfkService: Coin faucet for AFK place only.
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local tcg = ReplicatedStorage:WaitForChild('TCG')
local shared = tcg:WaitForChild('Shared')
local remotes = tcg:WaitForChild('Remotes')
local PlaceConfig = require(shared.PlaceConfig)

if not PlaceConfig.isAfk() then
	warn('[AFK] PlaceConfig.isAfk() false on place ' .. tostring(game.PlaceId) .. ' — faucet disabled')
	return
end

local MarketConfig = require(shared.MarketConfig)
local Wallet = require(script.Parent.Wallet)
local Progression = require(script.Parent.Progression)
local BattlePass = require(script.Parent.BattlePass)

local function ensureRemote(name, className)
	local existing = remotes:FindFirstChild(name)
	if existing then return existing end
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end

local afkState = ensureRemote('AfkState', 'RemoteEvent')
local AFK = MarketConfig.Afk
local TICK = math.max(60, AFK.tickSeconds or 90)
local COINS = math.max(1, AFK.coinsPerTick or 12)
local PASS_XP = math.max(0, AFK.xpPerTick or 8)
local MAX_TICKS = math.floor((AFK.sessionCapMinutes or 120) * 60 / TICK)
local session = {}

local function buildReturnPortal()
	local old = workspace:FindFirstChild('TCGAfkHub')
	if old then old:Destroy() end
	local hub = Instance.new('Folder')
	hub.Name = 'TCGAfkHub'
	hub.Parent = workspace
	local crystal = Instance.new('Part')
	crystal.Name = 'Crystal_CITY'
	crystal.Anchored = true
	crystal.Size = Vector3.new(3, 9, 3)
	crystal.Color = Color3.fromRGB(96, 210, 255)
	crystal.Material = Enum.Material.Neon
	crystal.Transparency = 0.15
	crystal.CFrame = CFrame.new(-78, 8, 0) * CFrame.Angles(0, math.rad(45), 0)
	crystal:SetAttribute('PortalTarget', 'main')
	crystal.Parent = hub
	local gui = Instance.new('BillboardGui')
	gui.Size = UDim2.fromOffset(160, 48)
	gui.StudsOffset = Vector3.new(0, 5.5, 0)
	gui.Parent = crystal
	local title = Instance.new('TextLabel')
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 34)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(96, 210, 255)
	title.Text = 'TCG Life'
	title.Parent = gui
	local status = Instance.new('TextLabel')
	status.Name = 'Status'
	status.BackgroundTransparency = 1
	status.Position = UDim2.new(0, 0, 0, 34)
	status.Size = UDim2.new(1, 0, 0, 24)
	status.Font = Enum.Font.GothamBold
	status.TextSize = 15
	status.TextColor3 = Color3.fromRGB(225, 228, 240)
	status.Text = 'Hold E'
	status.Parent = gui
	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'Portal'
	prompt.ActionText = 'Travel'
	prompt.ObjectText = 'TCG Life'
	prompt.HoldDuration = 1
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 14
	prompt.Parent = crystal
end

local function characterOk(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass('Humanoid')
	return char ~= nil and hum ~= nil and hum.Health > 0
end

local function fireState(player)
	local rec = session[player.UserId]
	if not rec then return end
	local used, left = Progression.idleBudget(player, MAX_TICKS)
	afkState:FireClient(player, {
		coins = rec.coins,
		xp = rec.xp,
		elapsed = math.floor(os.clock() - rec.started),
		nextTick = TICK,
		budgetLeft = left,
		budgetUsed = used,
	})
end

Players.PlayerAdded:Connect(function(player)
	Wallet.loadAsync(player)
	Progression.loadAsync(player)
	Wallet.ensure(player)
	session[player.UserId] = { started = os.clock(), coins = 0, xp = 0 }
	player.CharacterAdded:Connect(function()
		task.wait(0.4)
		fireState(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	Wallet.saveAsync(player)
	Progression.saveAsync(player)
	Progression.release(player)
	session[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		Wallet.saveAsync(player)
		Progression.saveAsync(player)
	end
end)

buildReturnPortal()
print('[Mine] optional TCG Life exit ready')
