-- MineIridescence: S / SS / SSS is one badge, one colour scheme.
-- Print rarity still owns the card background. This module only draws the mark.

local RunService = game:GetService("RunService")

local MineIridescence = {}

local HEX = {
	"D3F3F1", -- Ice Cold
	"DAE9EE", -- Icy Peak
	"CCDCFD", -- Blue Cream
	"E7D6E7", -- Silent Lavender
	"EDCCE4", -- Winter Pink
	"E8BFFB", -- Clear Violet
	"BBBEFE", -- Pastel Light Indigo
	"BFEFFF", -- Baby Blue
	"C4F0F0", -- Aqua Mist
}

local STOPS = {}
for i, h in ipairs(HEX) do
	STOPS[i] = Color3.fromHex(h)
end
MineIridescence.STOPS = STOPS
MineIridescence.INK = STOPS[7] -- Pastel Light Indigo, readable on dark glass

local COUNTS = { S = 1, SS = 2, SSS = 3 }

local function sequence()
	local n = #STOPS
	local keys = {}
	for i = 1, n do
		keys[i] = ColorSequenceKeypoint.new((i - 1) / n, STOPS[i])
	end
	keys[n + 1] = ColorSequenceKeypoint.new(1, STOPS[1])
	return ColorSequence.new(keys)
end

local SEQ = sequence()

local live = {}
local hooked = false

local function hook()
	if hooked then
		return
	end
	hooked = true
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		local rot = (t * 9) % 360
		local ox = math.sin(t * 0.14) * 0.08
		local oy = math.cos(t * 0.1) * 0.045
		for host, grads in pairs(live) do
			if not host.Parent then
				live[host] = nil
			else
				for i, g in ipairs(grads) do
					if g.Parent then
						g.Rotation = rot + (i - 1) * 18
						g.Offset = Vector2.new(ox, oy)
					end
				end
			end
		end
	end)
end

local function iridGrad(parent, extraRot)
	local g = Instance.new("UIGradient")
	g.Name = "IridGrad"
	g.Color = SEQ
	g.Rotation = extraRot or 0
	g.Parent = parent
	return g
end

function MineIridescence.isMark(grade)
	return COUNTS[grade] ~= nil
end

function MineIridescence.clear(host)
	if not host then
		return
	end
	local chip = host:FindFirstChild("GradeBadge")
	if chip then
		live[chip] = nil
		chip:Destroy()
	end
end

local function letter(parent, x, h, z, ghost)
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.Font = Enum.Font.FredokaOne
	lab.Text = "S"
	lab.TextScaled = true
	lab.TextColor3 = Color3.new(1, 1, 1)
	lab.TextTransparency = ghost and 0.55 or 0
	lab.Rotation = ghost and -14 or -9
	lab.Size = UDim2.fromOffset(math.floor(h * 0.92), h)
	lab.Position = UDim2.fromOffset(x + (ghost and 1 or 0), ghost and 1 or 0)
	lab.ZIndex = z
	lab.Parent = parent
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = math.max(12, math.floor(h * 0.86))
	constraint.Parent = lab
	if not ghost then
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = math.max(1.2, h * 0.06)
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = 0.12
		stroke.Parent = lab
		return lab, iridGrad(lab, 0), iridGrad(stroke, 40)
	end
	return lab, iridGrad(lab, 12)
end

function MineIridescence.badge(parent, grade, opts)
	opts = opts or {}
	MineIridescence.clear(parent)
	local n = COUNTS[grade]
	if not (parent and n) then
		return nil
	end
	hook()
	local h = math.max(18, math.floor(opts.height or 28))
	-- Extra letters add less than a full width so SS / SSS squat into one chip.
	local step = math.floor(h * 0.36)
	local w = math.floor(h * 0.86 + (n - 1) * step + h * 0.12)
	local chip = Instance.new("Frame")
	chip.Name = "GradeBadge"
	chip.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
	chip.BackgroundTransparency = 0.08
	chip.BorderSizePixel = 0
	chip.AnchorPoint = opts.anchor or Vector2.new(1, 0)
	chip.Position = opts.position or UDim2.new(1, -4, 0, 4)
	chip.Size = UDim2.fromOffset(w, h)
	chip.ZIndex = opts.z or 8
	chip.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, math.floor(h * 0.28))
	corner.Parent = chip
	local rim = Instance.new("UIStroke")
	rim.Thickness = math.max(1.4, h * 0.07)
	rim.Color = Color3.new(1, 1, 1)
	rim.Transparency = 0.05
	rim.Parent = chip
	local grads = { iridGrad(chip, -20), iridGrad(rim, 28) }
	local x0 = math.floor(h * 0.04)
	for i = 1, n do
		local x = x0 + (i - 1) * step
		local z = (opts.z or 8) + i
		local _, gGhost = letter(chip, x, h, z, true)
		local _, gFill, gStroke = letter(chip, x, h, z + 1, false)
		table.insert(grads, gGhost)
		table.insert(grads, gFill)
		if gStroke then
			table.insert(grads, gStroke)
		end
	end
	live[chip] = grads
	return chip
end

return MineIridescence
