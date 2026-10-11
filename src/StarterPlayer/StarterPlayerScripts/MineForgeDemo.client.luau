--[[
	MineForgeDemo.client -- two preview buttons and the two DEMO Forges behind
	them (MineForgeDemo: "molten" and "candy"). Owner, 2026-10-11: make demos
	"that pop up by some buttons on the screen"; if one is good it gets wired
	in for real, and this file goes.

	Its own script on purpose: MineClient is being edited by another session,
	and a demo should not need a single line of it. It keeps its own copy of
	the snapshot (the same "snapshot" event MineClient reads), fires the real
	forge verbs, and asks the server for a fresh snapshot ("snapNow") when a
	demo opens, so the numbers are right even if you have been standing still.
]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mine = RS:WaitForChild("Mine")
local shared = mine:WaitForChild("Shared")
local net = mine:WaitForChild("Remotes"):WaitForChild("MineNet")
local Demo = require(shared:WaitForChild("MineForgeDemo"))

local snap
local gui = Instance.new("ScreenGui")
gui.Name = "MineForgeDemoUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 40
gui.Parent = player:WaitForChild("PlayerGui")

local demos = {}
for _, theme in ipairs({ "molten", "candy" }) do
	demos[theme] = Demo.mount(gui, {
		theme = theme,
		getSnap = function()
			return snap
		end,
		send = function(verb, payload)
			net:FireServer(verb, payload)
		end,
	})
end

net.OnClientEvent:Connect(function(action, payload)
	if action == "snapshot" and type(payload) == "table" then
		snap = payload
		for _, d in pairs(demos) do
			if d.isOpen() then
				pcall(d.refresh)
			end
		end
	end
end)

-- The two preview buttons, left side, under the quest panel.
local function previewButton(label, y, a, b, theme)
	local btn = Instance.new("TextButton")
	btn.Name = "Preview_" .. theme
	btn.AnchorPoint = Vector2.new(0, 0.5)
	btn.Position = UDim2.new(0, 16, y, 0)
	btn.Size = UDim2.fromOffset(170, 50)
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.ZIndex = 30
	btn.Parent = gui
	-- The gradient goes on a fill under the label: on the button it would tint the text.
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.ZIndex = 30
	fill.Parent = btn
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 18)
	c.Parent = fill
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = 90
	g.Parent = fill
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(20, 12, 30)
	s.Thickness = 3
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = fill
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextSize = 24
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Text = label
	l.ZIndex = 31
	l.Parent = btn
	local ts = Instance.new("UIStroke")
	ts.Color = Color3.fromRGB(20, 12, 30)
	ts.Thickness = 2
	ts.Parent = l
	btn.MouseButton1Click:Connect(function()
		local d = demos[theme]
		if d.isOpen() then
			d.close()
			return
		end
		for t, other in pairs(demos) do
			if t ~= theme then
				other.close()
			end
		end
		pcall(function()
			net:FireServer("snapNow")
		end)
		d.open()
	end)
	return btn
end

previewButton("🔥 FORGE A", 0.66, Color3.fromRGB(255, 190, 70), Color3.fromRGB(220, 60, 20), "molten")
previewButton("🍬 FORGE B", 0.73, Color3.fromRGB(255, 140, 235), Color3.fromRGB(150, 60, 220), "candy")
