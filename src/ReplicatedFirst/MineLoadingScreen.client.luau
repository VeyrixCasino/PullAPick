-- MINE FOR CARDS loading splash (assets/mine-for-cards-icon-v4-hype.png).
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local LOADING_IMAGE = "rbxassetid://88438205722708"

local player = Players.LocalPlayer
while not player do
	player = Players.LocalPlayer
	task.wait()
end

local gui = Instance.new("ScreenGui")
gui.Name = "MineLoadingScreen"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local bg = Instance.new("Frame")
bg.Name = "Bg"
bg.BorderSizePixel = 0
bg.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
bg.Size = UDim2.fromScale(1, 1)
bg.Parent = gui

local art = Instance.new("ImageLabel")
art.Name = "Art"
art.BackgroundTransparency = 1
art.BorderSizePixel = 0
art.Image = LOADING_IMAGE
art.ScaleType = Enum.ScaleType.Fit
art.AnchorPoint = Vector2.new(0.5, 0.5)
art.Position = UDim2.fromScale(0.5, 0.46)
art.Size = UDim2.fromScale(0.62, 0.62)
art.Parent = bg
local artRatio = Instance.new("UIAspectRatioConstraint")
artRatio.AspectRatio = 1
artRatio.Parent = art

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.fromScale(0.5, 0.78)
title.Size = UDim2.new(0.86, 0, 0.07, 0)
title.Font = Enum.Font.GothamBlack
title.Text = "MINE FOR CARDS"
title.TextColor3 = Color3.fromRGB(255, 196, 72)
title.TextScaled = true
title.Parent = bg
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(40, 22, 6)
titleStroke.Thickness = 2
titleStroke.Parent = title

local barHost = Instance.new("Frame")
barHost.Name = "BarHost"
barHost.AnchorPoint = Vector2.new(0.5, 1)
barHost.Position = UDim2.new(0.5, 0, 1, -48)
barHost.Size = UDim2.new(0.42, 0, 0, 10)
barHost.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
barHost.BorderSizePixel = 0
barHost.Parent = bg
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barHost

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.BorderSizePixel = 0
fill.BackgroundColor3 = Color3.fromRGB(255, 196, 72)
fill.Size = UDim2.fromScale(0.08, 1)
fill.Parent = barHost
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
gui.Parent = playerGui

TweenService:Create(fill, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	Size = UDim2.fromScale(0.92, 1),
}):Play()

if not game:IsLoaded() then
	game.Loaded:Wait()
end
task.wait(0.35)

local fade = TweenService:Create(bg, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 1,
})
local fadeArt = TweenService:Create(art, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	ImageTransparency = 1,
})
local fadeTitle = TweenService:Create(title, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	TextTransparency = 1,
})
local fadeStroke = TweenService:Create(titleStroke, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	Transparency = 1,
})
fade:Play()
fadeArt:Play()
fadeTitle:Play()
fadeStroke:Play()
fade.Completed:Wait()
gui:Destroy()
