-- MineDiscordLinkClient: Ctrl+L (Cmd+L) panel to enter Discord !link code
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local net = RS:WaitForChild("Mine"):WaitForChild("Remotes"):WaitForChild("MineNet")

local gui = Instance.new("ScreenGui")
gui.Name = "MineDiscordLinkGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 120
gui.Enabled = false
gui.Parent = plr:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.45)
frame.Size = UDim2.fromOffset(340, 160)
frame.BackgroundColor3 = Color3.fromRGB(18, 16, 22)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.fromOffset(12, 10)
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(230, 210, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Discord link"
title.Parent = frame

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, -24, 0, 36)
hint.Position = UDim2.fromOffset(12, 38)
hint.Font = Enum.Font.Gotham
hint.TextSize = 13
hint.TextColor3 = Color3.fromRGB(180, 170, 190)
hint.TextWrapped = true
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Text = "Prefer Inventory → Account. Or paste your Discord !link code here."
hint.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -24, 0, 36)
box.Position = UDim2.fromOffset(12, 78)
box.BackgroundColor3 = Color3.fromRGB(32, 28, 40)
box.Font = Enum.Font.GothamBold
box.TextSize = 20
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.PlaceholderText = "CODE"
box.Text = ""
box.ClearTextOnFocus = false
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

local go = Instance.new("TextButton")
go.Size = UDim2.fromOffset(100, 32)
go.Position = UDim2.new(1, -112, 1, -40)
go.BackgroundColor3 = Color3.fromRGB(120, 70, 200)
go.Font = Enum.Font.GothamBold
go.TextSize = 14
go.TextColor3 = Color3.new(1, 1, 1)
go.Text = "Link"
go.Parent = frame
Instance.new("UICorner", go).CornerRadius = UDim.new(0, 8)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(32, 28)
close.Position = UDim2.new(1, -40, 0, 8)
close.BackgroundTransparency = 1
close.Font = Enum.Font.GothamBold
close.TextSize = 18
close.TextColor3 = Color3.fromRGB(200, 180, 210)
close.Text = "X"
close.Parent = frame

local function toggle(on)
	-- Discord is an off-platform link: only where Roblox allows it for this
	-- player (the server sets PolicyDiscord on join).
	if plr:GetAttribute("PolicyDiscord") ~= true then
		gui.Enabled = false
		return
	end
	if on == nil then
		gui.Enabled = not gui.Enabled
	else
		gui.Enabled = on
	end
	if gui.Enabled then
		box:CaptureFocus()
	end
end

close.MouseButton1Click:Connect(function()
	toggle(false)
end)

local function submit()
	local code = box.Text
	if code == nil or code == "" then
		return
	end
	net:FireServer("discordLink", { code = code })
	box.Text = ""
	toggle(false)
end

go.MouseButton1Click:Connect(submit)
box.FocusLost:Connect(function(enter)
	if enter then
		submit()
	end
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.L and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) or UIS:IsKeyDown(Enum.KeyCode.LeftMeta) or UIS:IsKeyDown(Enum.KeyCode.RightMeta)) then
		toggle()
	end
end)

net.OnClientEvent:Connect(function(action)
	if action == "discordLinked" then
		toggle(false)
	end
end)
