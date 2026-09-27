-- PortalService (AFK copy): return crystal -> MAIN. Studio Play toasts only.
local Players = game:GetService('Players')
local TeleportService = game:GetService('TeleportService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ProximityPromptService = game:GetService('ProximityPromptService')
local RunService = game:GetService('RunService')

local tcg = ReplicatedStorage:WaitForChild('TCG')
local remotes = tcg:WaitForChild('Remotes')
local shared = tcg:WaitForChild('Shared')
local PlaceConfig = require(shared.PlaceConfig)

local function ensureRemote(name, className)
	local existing = remotes:FindFirstChild(name)
	if existing then return existing end
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end

local portalNotify = ensureRemote('PortalNotify', 'RemoteEvent')
local IN_STUDIO = RunService:IsStudio()
local COOLDOWN = 6
local lastAttempt = {}
local inFlight = {}

local function portals()
	local found = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA('BasePart') and d:GetAttribute('PortalTarget') then
			table.insert(found, d)
		end
	end
	return found
end

local function notifyPlayer(player, text, kind)
	portalNotify:FireClient(player, { text = text, kind = kind or 'info' })
end

local function failureMessage(label, err)
	if IN_STUDIO then
		return 'Cross-place travel only works in the published game  ·  test on Roblox, not Studio Play'
	end
	local msg = tostring(err or '')
	if string.find(msg, 'not 200', 1, true) or string.find(msg, 'HttpError', 1, true) then
		return 'Could not reach ' .. label .. '  ·  make sure that place is published in this experience'
	end
	return 'Could not travel to ' .. label .. '  ·  try again shortly'
end

local function setStatus(portal, text, colour)
	for _, gui in ipairs(portal:GetDescendants()) do
		if gui:IsA('BillboardGui') then
			local status = gui:FindFirstChild('Status')
			if status and status:IsA('TextLabel') then
				status.Text = text
				if colour then status.TextColor3 = colour end
			end
		end
	end
end

local function targetFor(portal)
	local want = portal:GetAttribute('PortalTarget')
	if want == 'exchange' then return PlaceConfig.EXCHANGE_PLACE_ID, 'the Exchange' end
	if want == 'afk' then return PlaceConfig.AFK_PLACE_ID, 'the AFK Lounge' end
	return PlaceConfig.MAIN_PLACE_ID, 'the city'
end

local function shut(portal)
	local prompt = portal:FindFirstChildWhichIsA('ProximityPrompt')
	if prompt then prompt.Enabled = false; prompt.ActionText = 'Closed' end
	portal.Transparency = 0.85
	setStatus(portal, 'NOT OPEN YET  ·  no place id set', Color3.fromRGB(240, 170, 120))
end

local function travel(player, portal)
	local placeId, label = targetFor(portal)
	if not PlaceConfig.isConfigured(placeId) then
		setStatus(portal, 'NOT OPEN YET  ·  no place id set', Color3.fromRGB(240, 170, 120))
		return
	end
	if placeId == game.PlaceId then return end
	if IN_STUDIO then
		notifyPlayer(player, failureMessage(label, 'studio'), 'info')
		setStatus(portal, 'STUDIO PLAY  ·  publish to test travel', Color3.fromRGB(240, 190, 120))
		task.delay(8, function() setStatus(portal, '', Color3.fromRGB(240, 170, 120)) end)
		return
	end
	local userId = player.UserId
	if inFlight[userId] then return end
	local now = os.clock()
	if now - (lastAttempt[userId] or -math.huge) < COOLDOWN then return end
	lastAttempt[userId] = now
	inFlight[userId] = true
	local options = Instance.new('TeleportOptions')
	options:SetTeleportData({ from = game.PlaceId })
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(placeId, { player }, options)
	end)
	if not ok then
		inFlight[userId] = nil
		local text = failureMessage(label, err)
		warn('[Portal] teleport to ' .. label .. ' failed: ' .. tostring(err))
		notifyPlayer(player, text, 'error')
		setStatus(portal, text, Color3.fromRGB(240, 140, 140))
	end
end

TeleportService.TeleportInitFailed:Connect(function(player, result, message)
	inFlight[player.UserId] = nil
	notifyPlayer(player, failureMessage('your destination', message), 'error')
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name ~= 'Enter' and prompt.Name ~= 'Portal' then return end
	local portal = prompt.Parent
	if portal and portal:IsA('BasePart') and portal:GetAttribute('PortalTarget') then
		travel(player, portal)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	inFlight[player.UserId] = nil
	lastAttempt[player.UserId] = nil
end)

task.defer(function()
	local open, closed = 0, 0
	for _, portal in ipairs(portals()) do
		local placeId = targetFor(portal)
		if PlaceConfig.isConfigured(placeId) and placeId ~= game.PlaceId then open += 1 else shut(portal); closed += 1 end
	end
	print(('[Portal] %d open, %d closed%s'):format(open, closed, IN_STUDIO and ' (Studio: cross-place travel disabled)' or ''))
end)
