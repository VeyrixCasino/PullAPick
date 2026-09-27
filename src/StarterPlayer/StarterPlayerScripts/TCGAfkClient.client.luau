-- TCGAfkClient: minimal HUD + portal toasts. No city Storefront UI.
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local tcg = ReplicatedStorage:WaitForChild('TCG')
local PlaceConfig = require(tcg:WaitForChild('Shared'):WaitForChild('PlaceConfig'))
if not PlaceConfig.isAfk() then return end

local remotes = tcg:WaitForChild('Remotes')
local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')

local gui = Instance.new('ScreenGui')
gui.Name = 'TCGAfkUI'
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local card = Instance.new('Frame')
card.Name = 'AfkHud'
card.BackgroundColor3 = Color3.fromRGB(22, 28, 36)
card.BorderSizePixel = 0
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, 12)
card.Size = UDim2.fromOffset(380, 100)
card.Parent = gui
local corner = Instance.new('UICorner')
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = card

local title = Instance.new('TextLabel')
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 10)
title.Size = UDim2.new(1, -28, 0, 22)
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(150, 255, 170)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = 'AFK LOUNGE'
title.Parent = card

local timer = Instance.new('TextLabel')
timer.Name = 'Timer'
timer.BackgroundTransparency = 1
timer.Position = UDim2.new(0, 14, 0, 36)
timer.Size = UDim2.new(1, -28, 0, 18)
timer.Font = Enum.Font.GothamBold
timer.TextSize = 14
timer.TextColor3 = Color3.fromRGB(230, 235, 245)
timer.TextXAlignment = Enum.TextXAlignment.Left
timer.Text = 'Idle 0:00'
timer.Parent = card

local earn = Instance.new('TextLabel')
earn.Name = 'Earn'
earn.BackgroundTransparency = 1
earn.Position = UDim2.new(0, 14, 0, 58)
earn.Size = UDim2.new(1, -28, 0, 28)
earn.Font = Enum.Font.Gotham
earn.TextSize = 13
earn.TextColor3 = Color3.fromRGB(170, 180, 195)
earn.TextXAlignment = Enum.TextXAlignment.Left
earn.Text = 'Waiting for first idle tick…'
earn.Parent = card

local toast = Instance.new('TextLabel')
toast.Name = 'Toast'
toast.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
toast.BackgroundTransparency = 0.15
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -24)
toast.Size = UDim2.fromOffset(520, 40)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 14
toast.TextColor3 = Color3.fromRGB(240, 242, 250)
toast.Visible = false
toast.Parent = gui
local toastCorner = Instance.new('UICorner')
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = toast

local function fmt(sec)
	local m = math.floor(sec / 60)
	local s = sec % 60
	return string.format('%d:%02d', m, s)
end

local afkState = remotes:WaitForChild('AfkState', 12)
if afkState and afkState:IsA('RemoteEvent') then
	afkState.OnClientEvent:Connect(function(payload)
		if type(payload) ~= 'table' then return end
		timer.Text = 'Idle ' .. fmt(tonumber(payload.elapsed) or 0)
		earn.Text = string.format('This session: %d Coins  +%d pass XP  (budget %d left)',
			tonumber(payload.coins) or 0,
			tonumber(payload.xp) or 0,
			tonumber(payload.budgetLeft) or 0)
	end)
end

local portalNotify = remotes:WaitForChild('PortalNotify', 12)
if portalNotify and portalNotify:IsA('RemoteEvent') then
	portalNotify.OnClientEvent:Connect(function(payload)
		local text = type(payload) == 'table' and payload.text or tostring(payload)
		if not text or text == '' then return end
		toast.Text = text
		toast.Visible = true
		task.delay(5, function()
			if toast.Text == text then toast.Visible = false end
		end)
	end)
end

print('[AFK] client HUD ready role=' .. PlaceConfig.role())
