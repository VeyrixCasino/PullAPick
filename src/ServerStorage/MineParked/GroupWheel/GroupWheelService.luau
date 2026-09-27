--[[
	GroupWheelService -- lobby Group Wheel pad + spin grants.

	Kept out of MineServer so the main script stays under Luau's register cap.
	MineServer only: require, build once, bindPrompt branch, net action.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local Wheel = require(shared:WaitForChild("MineGroupWheel"))
local PetRoster = require(shared:WaitForChild("MinePetRoster"))

local GroupWheelService = {}

local function groupId()
	return tonumber(C.GROUP_ID) or 0
end

local function inGroup(plr)
	local gid = groupId()
	if gid <= 0 then
		return RunService:IsStudio()
	end
	local ok, member = pcall(function()
		return plr:IsInGroupAsync(gid)
	end)
	return ok and member == true
end

function GroupWheelService.payload(p)
	return Wheel.payload(p, os.time())
end

function GroupWheelService.grantPaidSpins(p, n)
	n = math.max(0, math.floor(tonumber(n) or 0))
	if n <= 0 then
		return 0
	end
	p.groupWheel = type(p.groupWheel) == "table" and p.groupWheel or { last = 0, paid = 0 }
	p.groupWheel.paid = math.max(0, math.floor(tonumber(p.groupWheel.paid) or 0)) + n
	return p.groupWheel.paid
end

function GroupWheelService.applyReward(plr, p, reward, deps)
	deps = deps or {}
	reward = reward or {}
	local lines = {}
	local rng = deps.rng or Random.new()
	local petName = Wheel.resolvePetName(reward, rng)
	if petName and deps.mint then
		local roster = PetRoster.BY_NAME and PetRoster.BY_NAME[petName]
		local def = {
			setId = "group_wheel",
			index = 1,
			cardKey = "group_wheel:" .. petName,
			name = petName,
			rarityId = (roster and roster.tier) or "Exotic",
			typeId = "Crystal",
			animal = roster and roster.animal or nil,
			roleName = "Group Wheel",
			kind = "Unit",
			setName = "Group Wheel",
		}
		local c = deps.mint(def, plr.UserId)
		p.cards = p.cards or {}
		table.insert(p.cards, c)
		lines[#lines + 1] = string.format("%s (%s)", petName, tostring(def.rarityId))
	end
	local gems = math.floor(tonumber(reward.gems) or 0)
	if gems > 0 then
		p.gems = (p.gems or 0) + gems
		lines[#lines + 1] = gems .. " Gems"
	end
	local dust = math.floor(tonumber(reward.dust) or 0)
	if dust > 0 then
		p.dust = (p.dust or 0) + dust
		lines[#lines + 1] = dust .. " Stardust"
	end
	local tokens = math.floor(tonumber(reward.tokens) or 0)
	if tokens > 0 then
		p.temperTokens = (p.temperTokens or 0) + tokens
		lines[#lines + 1] = tokens .. " Temper Tokens"
	end
	if type(reward.packs) == "table" and deps.grantPacks then
		deps.grantPacks(plr, p, reward.packs)
		for _, row in ipairs(reward.packs) do
			lines[#lines + 1] = string.format("%s x%d", tostring(row.id), tonumber(row.qty) or 1)
		end
	end
	if type(reward.blocks) == "table" and deps.LuckyBlocks and deps.LuckyBlocks.grant then
		for _, row in ipairs(reward.blocks) do
			local id = tostring(row.id or "godly_lucky_block")
			local grade = tostring(row.grade or "A")
			local qty = math.max(1, math.floor(tonumber(row.qty) or 1))
			deps.LuckyBlocks.grant(p, id, grade, qty)
			lines[#lines + 1] = string.format("%s [%s] x%d", id, grade, qty)
		end
	end
	return lines
end

function GroupWheelService.spin(plr, profiles, deps)
	deps = deps or {}
	local net = deps.net
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local now = os.time()
	p.groupWheel = type(p.groupWheel) == "table" and p.groupWheel or { last = 0, paid = 0 }
	local paid = math.max(0, math.floor(tonumber(p.groupWheel.paid) or 0))
	if not Wheel.isLive(now) and paid <= 0 then
		if net then
			net:FireClient(plr, "groupWheel", {
				ok = false,
				reason = "ended",
				payload = Wheel.payload(p, now),
			})
			net:FireClient(plr, "toast", "Group Wheel week is over")
		end
		return
	end

	local usedPaid = false
	if paid > 0 then
		p.groupWheel.paid = paid - 1
		usedPaid = true
	else
		local gid = groupId()
		if gid <= 0 and not RunService:IsStudio() then
			if net then net:FireClient(plr, "toast", "Group Wheel is not configured yet.") end
			return
		end
		if not inGroup(plr) then
			if net then
				net:FireClient(plr, "groupWheel", {
					ok = false,
					reason = "group",
					groupId = gid,
					payload = Wheel.payload(p, now),
				})
				net:FireClient(plr, "toast", "Join the group for a free spin, or buy spins")
			end
			return
		end
		local ready, wait = Wheel.ready(p.groupWheel.last, now)
		if not ready then
			if net then
				net:FireClient(plr, "groupWheel", {
					ok = false,
					reason = "cooldown",
					wait = wait,
					payload = Wheel.payload(p, now),
				})
				local hrs = math.floor(wait / 3600)
				local mins = math.floor((wait % 3600) / 60)
				net:FireClient(plr, "toast", string.format("Next free spin in %dh %dm — or buy spins", hrs, mins))
			end
			return
		end
		p.groupWheel.last = now
	end

	local rng = Random.new()
	local seg, index = Wheel.roll(rng)
	deps.rng = rng
	local lines = GroupWheelService.applyReward(plr, p, seg.reward, deps)
	if deps.markDirty then deps.markDirty(plr) end
	if deps.snap then deps.snap(plr) end
	if net then
		net:FireClient(plr, "groupWheel", {
			ok = true,
			index = index,
			segId = seg.id,
			label = seg.label,
			sub = seg.sub,
			lines = lines,
			usedPaid = usedPaid,
			payload = Wheel.payload(p, now),
			promptFavorite = true,
		})
		net:FireClient(plr, "toast", "Group Wheel: " .. tostring(seg.label) .. "!")
		net:FireClient(plr, "loot", {
			kind = "groupWheel",
			label = seg.label,
			lines = lines,
		})
	end
end

local function part(props, parent)
	local p = Instance.new("Part")
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Anchored = true
	p.CanCollide = props.CanCollide == true
	p.Parent = parent
	return p
end

local function fmtSaleLeft(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	local d = math.floor(sec / 86400)
	local h = math.floor((sec % 86400) / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	if d > 0 then
		return string.format("%dd %dh %dm", d, h, m)
	end
	if h > 0 then
		return string.format("%dh %dm %ds", h, m, s)
	end
	if m > 0 then
		return string.format("%dm %ds", m, s)
	end
	return string.format("%ds", s)
end

local function surfaceLabel(faceParent, text, props)
	props = props or {}
	local sg = Instance.new("SurfaceGui")
	sg.Face = props.Face or Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = props.pps or 40
	sg.LightInfluence = 0
	sg.Parent = faceParent
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.Size = UDim2.fromScale(1, 1)
	lab.Font = Enum.Font.GothamBlack
	lab.TextScaled = true
	lab.TextColor3 = props.color or Color3.new(1, 1, 1)
	lab.TextStrokeTransparency = 0.4
	lab.Text = text
	lab.Parent = sg
	return lab
end

function GroupWheelService.build(lobby)
	if not lobby then
		return
	end
	local existing = lobby:FindFirstChild("GroupWheel")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "GroupWheel"
	folder.Parent = lobby

	-- Vertical prize wheel: thin face toward the lobby apron.
	local foot = Vector3.new(-24, 6.2, 10)
	local center = foot + Vector3.new(0, 7.2, 0)
	local faceToward = Vector3.new(-8, center.Y, 10)
	local faceCF = CFrame.lookAt(center, faceToward)

	-- Low podium.
	part({
		Name = "Base",
		Size = Vector3.new(10, 1.1, 8),
		CFrame = CFrame.new(foot) * CFrame.Angles(0, select(2, faceCF:ToEulerAnglesYXZ()), 0),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(36, 28, 18),
		CanCollide = true,
	}, folder)

	-- Thin backboard + posts (fixed stand).
	local back = part({
		Name = "Backboard",
		Size = Vector3.new(13.5, 13.5, 0.28),
		CFrame = faceCF * CFrame.new(0, 0, 0.55),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(22, 18, 28),
		CanCollide = false,
	}, folder)
	part({
		Name = "PostL",
		Size = Vector3.new(0.55, 14.5, 0.55),
		CFrame = faceCF * CFrame.new(-6.4, -0.4, 0.55),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(255, 196, 70),
		CanCollide = false,
	}, folder)
	part({
		Name = "PostR",
		Size = Vector3.new(0.55, 14.5, 0.55),
		CFrame = faceCF * CFrame.new(6.4, -0.4, 0.55),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(255, 196, 70),
		CanCollide = false,
	}, folder)
	part({
		Name = "Axle",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.1, 1.4, 1.4),
		CFrame = faceCF * CFrame.Angles(0, math.rad(90), 0),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(255, 220, 120),
		CanCollide = false,
	}, folder)

	-- Fixed pointer at the top (does not spin).
	local pointer = part({
		Name = "Pointer",
		Size = Vector3.new(0.7, 1.6, 0.45),
		CFrame = faceCF * CFrame.new(0, 7.15, -0.35),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 80, 100),
		CanCollide = false,
	}, folder)
	local pMesh = Instance.new("SpecialMesh")
	pMesh.MeshType = Enum.MeshType.Wedge
	pMesh.Parent = pointer
	pointer.CFrame = faceCF * CFrame.new(0, 7.15, -0.35) * CFrame.Angles(0, 0, math.rad(180))

	-- Spinning wheel model (thin face + colored option wedges).
	local wheel = Instance.new("Model")
	wheel.Name = "Wheel"
	wheel.Parent = folder

	local radius = 6.2
	local segs = Wheel.SEGMENTS
	local n = math.max(1, #segs)
	local depth = 0.32

	local pivot = part({
		Name = "Pivot",
		Size = Vector3.new(0.2, 0.2, 0.2),
		CFrame = faceCF,
		Transparency = 1,
		CanCollide = false,
	}, wheel)
	wheel.PrimaryPart = pivot

	local rim = part({
		Name = "Rim",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(depth + 0.12, radius * 2 + 0.55, radius * 2 + 0.55),
		CFrame = faceCF * CFrame.Angles(0, math.rad(90), 0),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 196, 70),
		CanCollide = false,
	}, wheel)

	for i, seg in ipairs(segs) do
		local ang = ((i - 0.5) / n) * math.pi * 2
		local arc = (2 * math.pi * radius / n) * 0.9
		local isMystery = seg.mystery == true or seg.id == "exotic"
		local col = isMystery and Color3.fromRGB(8, 6, 10) or (seg.color or Color3.fromRGB(255, 196, 70))
		local slice = part({
			Name = "Slice_" .. tostring(seg.id or i),
			Size = Vector3.new(math.max(0.55, arc), radius * 0.92, depth + 0.02),
			CFrame = faceCF * CFrame.Angles(0, 0, ang) * CFrame.new(0, radius * 0.46, -0.02),
			Material = Enum.Material.SmoothPlastic,
			Color = col,
			CanCollide = false,
		}, wheel)
		-- Peg between slices (carnival tick).
		part({
			Name = "Peg_" .. i,
			Size = Vector3.new(0.18, 0.18, 0.55),
			CFrame = faceCF * CFrame.Angles(0, 0, (i / n) * math.pi * 2) * CFrame.new(0, radius + 0.05, -0.2),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 230, 160),
			CanCollide = false,
		}, wheel)

		local labelText = isMystery and "?" or tostring(seg.label or "?")
		local labPart = part({
			Name = "Label_" .. i,
			Size = Vector3.new(math.clamp(arc * 0.85, 1.1, 2.6), 0.85, 0.08),
			CFrame = faceCF * CFrame.Angles(0, 0, ang) * CFrame.new(0, radius * 0.72, -0.22),
			Material = Enum.Material.SmoothPlastic,
			Color = isMystery and Color3.fromRGB(8, 6, 10) or col,
			CanCollide = false,
			Transparency = 1,
		}, wheel)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 50
		sg.LightInfluence = 0
		sg.Parent = labPart
		local lab = Instance.new("TextLabel")
		lab.BackgroundTransparency = 1
		lab.Size = UDim2.fromScale(1, 1)
		lab.Font = Enum.Font.GothamBlack
		lab.TextScaled = true
		lab.TextColor3 = isMystery and Color3.fromRGB(255, 70, 90) or Color3.fromRGB(20, 14, 8)
		lab.TextStrokeTransparency = isMystery and 0.2 or 0.55
		lab.Text = labelText
		lab.Parent = sg
	end

	local hub = part({
		Name = "Hub",
		Size = Vector3.new(2.2, 2.2, 0.7),
		CFrame = faceCF * CFrame.new(0, 0, -0.15),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 196, 70),
		CanCollide = false,
	}, wheel)
	surfaceLabel(hub, "SPIN", { color = Color3.fromRGB(30, 20, 10), pps = 55 })

	-- Idle spin — always slowly turning so every option rides past the pointer.
	local spinAng = 0
	local idleConn
	idleConn = RunService.Heartbeat:Connect(function(dt)
		if not folder.Parent or not wheel.Parent then
			if idleConn then idleConn:Disconnect() end
			return
		end
		spinAng += math.rad(16) * dt -- ~2.7 RPM idle crawl
		wheel:PivotTo(faceCF * CFrame.Angles(0, 0, spinAng))
	end)
	folder.Destroying:Connect(function()
		if idleConn then idleConn:Disconnect() end
	end)

	-- Title + week timer sign above the wheel.
	local sign = part({
		Name = "TimerSign",
		Size = Vector3.new(8.5, 2.4, 0.35),
		CFrame = faceCF * CFrame.new(0, 8.6, 0.2),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(20, 16, 26),
		CanCollide = false,
	}, folder)
	local signGui = Instance.new("SurfaceGui")
	signGui.Name = "TimerGui"
	signGui.Face = Enum.NormalId.Front
	signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.PixelsPerStud = 40
	signGui.LightInfluence = 0
	signGui.Parent = sign
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0.45, 0)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 220, 120)
	title.Text = "GROUP WHEEL"
	title.Parent = signGui
	local tag = Instance.new("TextLabel")
	tag.BackgroundTransparency = 1
	tag.Position = UDim2.new(0, 0, 0.4, 0)
	tag.Size = UDim2.new(1, 0, 0.28, 0)
	tag.Font = Enum.Font.GothamBold
	tag.TextScaled = true
	tag.TextColor3 = Color3.fromRGB(255, 120, 150)
	tag.Text = tostring(Wheel.TAGLINE or "Galaxy + Spark = EXOTIC")
	tag.Parent = signGui
	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.BackgroundTransparency = 1
	timer.Position = UDim2.new(0, 0, 0.68, 0)
	timer.Size = UDim2.new(1, 0, 0.3, 0)
	timer.Font = Enum.Font.GothamMedium
	timer.TextScaled = true
	timer.TextColor3 = Color3.fromRGB(200, 220, 255)
	timer.Text = "ENDS IN —"
	timer.Parent = signGui

	task.spawn(function()
		while folder.Parent do
			if Wheel.isLive() then
				timer.Text = "ENDS IN  " .. fmtSaleLeft(Wheel.saleLeft())
				timer.TextColor3 = Color3.fromRGB(200, 220, 255)
			else
				timer.Text = "WEEK ENDED"
				timer.TextColor3 = Color3.fromRGB(160, 160, 170)
			end
			task.wait(1)
		end
	end)

	-- Prompt pad in front of the wheel.
	local pad = part({
		Name = "Pad",
		Size = Vector3.new(7, 1, 5),
		CFrame = faceCF * CFrame.new(0, -6.7, -3.2),
		Transparency = 1,
		CanCollide = false,
	}, folder)
	pad:SetAttribute("Machine", "groupWheel")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Spin"
	prompt.ObjectText = "Group Wheel"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 18
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = pad

	CollectionService:AddTag(folder, "MineGroupWheel")
	return folder
end

return GroupWheelService
