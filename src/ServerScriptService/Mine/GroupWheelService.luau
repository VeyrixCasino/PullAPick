--[[
	GroupWheelService -- the lobby DAILY WHEEL: the world model, the spin, the grant.

	Owner, 2026-10-10 (docs/TODO.md NOW, A1): every player gets one free spin a
	day, group members +1, and login streaks add more (MineGroupWheel.allowance).
	Kept out of MineServer for Luau's register cap. MineServer only requires
	this, builds it once, routes the "groupWheelSpin" verb and the "groupWheel"
	machine prompt, and puts `snapState` in the snapshot.

	Profile: `p.groupWheel = { day, used, paid, last }`. `day`/`used` count
	today's FREE spins; `paid` are banked Robux spins and never expire;
	`last` is the old wheel's field, still written so nothing reading it breaks.
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

--[[
	GROUP MEMBERSHIP, CACHED PER SESSION.

	IsInGroupAsync yields, and the old wheel called it inside every spin, under
	the per-player busy lock. The snapshot (up to 10 a second) needs the answer
	too, and must never yield. So it is looked up once, when the player joins,
	and the cache answers from then on. Until it answers the player counts as a
	non-member: the group bonus appears a moment later, never the other way.
]]
local members = {}

local function lookupMember(plr)
	local gid = groupId()
	if gid <= 0 then
		members[plr.UserId] = RunService:IsStudio()
		return
	end
	local ok, member = pcall(function()
		return plr:IsInGroupAsync(gid)
	end)
	members[plr.UserId] = ok and member == true
end

Players.PlayerAdded:Connect(function(plr)
	task.spawn(lookupMember, plr)
end)
Players.PlayerRemoving:Connect(function(plr)
	members[plr.UserId] = nil
end)
for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(lookupMember, plr)
end

function GroupWheelService.isMember(plr)
	return plr ~= nil and members[plr.UserId] == true
end

-- Small, for every snapshot: spins left, paid, time to reset, member.
function GroupWheelService.snapState(p, plr)
	return Wheel.state(p, os.time(), GroupWheelService.isMember(plr))
end

-- For the panel: the state plus the prize table it draws.
function GroupWheelService.payload(p, plr)
	local st = Wheel.state(p, os.time(), GroupWheelService.isMember(plr))
	st.segments = Wheel.SEGMENTS
	return st
end

function GroupWheelService.grantPaidSpins(p, n)
	n = math.max(0, math.floor(tonumber(n) or 0))
	if n <= 0 then
		return 0
	end
	p.groupWheel = type(p.groupWheel) == "table" and p.groupWheel or {}
	p.groupWheel.paid = math.max(0, math.floor(tonumber(p.groupWheel.paid) or 0)) + n
	return p.groupWheel.paid
end

-- Grant one slice's prize. Returns the lines the player reads ("Apex Pack x1").
function GroupWheelService.applyReward(plr, p, reward, deps)
	deps = deps or {}
	reward = reward or {}
	local lines = {}
	local rng = deps.rng or Random.new()
	local petName = Wheel.resolvePetName(reward, rng)
	if petName and deps.mint then
		local roster = PetRoster.BY_NAME and PetRoster.BY_NAME[petName]
		-- setId / cardKey stay "group_wheel": they are on minted cards (data).
		local def = {
			setId = "group_wheel",
			index = 1,
			cardKey = "group_wheel:" .. petName,
			name = petName,
			rarityId = (roster and roster.tier) or "Exotic",
			typeId = "Crystal",
			animal = roster and roster.animal or nil,
			roleName = "Daily Wheel",
			kind = "Unit",
			setName = "Daily Wheel",
		}
		local c = deps.mint(def, plr.UserId)
		p.cards = p.cards or {}
		table.insert(p.cards, c)
		lines[#lines + 1] = string.format("%s (%s pet)", petName, tostring(def.rarityId))
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
			lines[#lines + 1] = string.format("%s x%d", Wheel.prettyId(row.id), tonumber(row.qty) or 1)
		end
	end
	if type(reward.blocks) == "table" and deps.LuckyBlocks and deps.LuckyBlocks.grant then
		for _, row in ipairs(reward.blocks) do
			local id = tostring(row.id or "lucky_block")
			local grade = tostring(row.grade or "F")
			local qty = math.max(1, math.floor(tonumber(row.qty) or 1))
			deps.LuckyBlocks.grant(p, id, grade, qty)
			local def = deps.LuckyBlocks.def and deps.LuckyBlocks.def(id)
			lines[#lines + 1] = string.format("%s (grade %s) x%d", (def and def.name) or Wheel.prettyId(id), grade, qty)
		end
	end
	return lines
end

--[[
	ONE SPIN.

	Free spins go FIRST: they refill at midnight and a paid spin keeps forever,
	so spending a paid one while a free one sat unused was the player losing a
	spin. A paid spin is Robux turned into a random prize, so it obeys the
	regional paid-random rule (PolicyNoRandom); free spins are not paid and
	always work.
]]
function GroupWheelService.spin(plr, profiles, deps)
	deps = deps or {}
	local net = deps.net
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local now = os.time()
	local day = Wheel.dayIndex(now)
	p.groupWheel = type(p.groupWheel) == "table" and p.groupWheel or {}
	local gw = p.groupWheel
	local st = Wheel.state(p, now, GroupWheelService.isMember(plr))

	local usedPaid = false
	if st.freeLeft > 0 then
		if gw.day ~= day then
			gw.day = day
			gw.used = 0
		end
		gw.used = math.max(0, math.floor(tonumber(gw.used) or 0)) + 1
		gw.last = now
	elseif st.paid > 0 and plr:GetAttribute("PolicyNoRandom") ~= true then
		gw.paid = st.paid - 1
		usedPaid = true
	else
		if net then
			net:FireClient(plr, "groupWheel", {
				ok = false,
				reason = (st.paid > 0) and "region" or "used",
				payload = GroupWheelService.payload(p, plr),
			})
			local h = math.floor(st.resetIn / 3600)
			local m = math.floor((st.resetIn % 3600) / 60)
			net:FireClient(plr, "toast", (st.paid > 0)
				and "Paid spins aren't available in your region"
				or string.format("Next free spin in %dh %dm", h, m))
		end
		return
	end

	local rng = Random.new()
	local seg, index = Wheel.roll(rng)
	deps.rng = rng
	local lines = GroupWheelService.applyReward(plr, p, seg.reward, deps)
	if deps.markDirty then deps.markDirty(plr) end
	-- Saved now, not at the next autosave: a prize lost to a crash inside the
	-- 45 s window is the thing a daily reward must never do.
	if deps.save then pcall(deps.save, plr) end
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
			oneIn = Wheel.oneIn(seg),
			hype = seg.hype == true,
			payload = GroupWheelService.payload(p, plr),
			-- Only after a real chase: asking on every common prize is nagging.
			promptFavorite = seg.hype == true,
		})
		net:FireClient(plr, "toast", "Daily Wheel: " .. tostring(seg.label) .. "!")
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

-- A WedgePart is full height at +Z and tapers to nothing at -Z, with the solid
-- corner toward -Y. Mapping wedge (X, Y, Z) onto the spinning face as
-- (normal, tangent, radial) puts the tip at the hub and the flat edge at the
-- rim. The mirrored half flips the tangent -- and the thickness with it, so the
-- matrix stays right-handed -- and the two halves meet on the slice bisector.
local SECTOR_HALVES = {
	{ side = 1, rot = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0)) },
	{ side = -1, rot = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0)) },
}

local function fmtLeft(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
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
	--[[
		WHERE IT STANDS.

		It used to sit at bearing 293 from the fountain -- and REBIRTH / CLOUD
		GATE is at 295. The wheel was planted squarely in that sight line, which
		is why the plaza read as "big yellow thing in front of the building I
		was walking to".

		The lobby's landmarks sit at 40 (Depot), 62 (Blacksmith), 237
		(Enchanter), 295 (Rebirth) and 325 (Jobs). Bearing 88 is the middle of
		the widest gap -- it was 26 degrees clear of Blacksmith and of the fossil
		bench that used to stand at 114, and with that slot now empty it has more
		room, not less -- and 40 studs out, close enough to read from spawn. It
		faces the fountain so you meet its face, not its back.
	]]
	local foot = Vector3.new(40, 6.2, 0)
	local center = foot + Vector3.new(0, 7.2, 0)
	local faceToward = Vector3.new(0, center.Y, 0)
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
		-- Turned so its UP axis is the wheel's axle: the client spinner in
		-- MineGroupWheelView turns the model about its pivot's up axis.
		CFrame = faceCF * CFrame.Angles(math.rad(90), 0, 0),
		Transparency = 1,
		CanCollide = false,
	}, wheel)
	wheel.PrimaryPart = pivot

	-- Backing disc: deliberately THIN and set back behind the wedges. It used to
	-- be (depth + 0.12) thick and centred on the face, which put its front face
	-- 0.03 studs AHEAD of the slice fronts -- a solid neon disc swallowing all 14
	-- coloured wedges, so the wheel read as a blank yellow circle with the labels
	-- floating on it. Sitting behind them, its extra radius becomes the glowing
	-- rim ring instead of a lid.
	local rim = part({
		Name = "Rim",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.18, radius * 2 + 0.55, radius * 2 + 0.55),
		CFrame = faceCF * CFrame.new(0, 0, 0.14) * CFrame.Angles(0, math.rad(90), 0),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 196, 70),
		CanCollide = false,
	}, wheel)

	for i, seg in ipairs(segs) do
		local ang = ((i - 0.5) / n) * math.pi * 2
		local arc = (2 * math.pi * radius / n) * 0.9
		local isMystery = seg.mystery == true or seg.id == "exotic"
		local col = isMystery and Color3.fromRGB(8, 6, 10) or (seg.color or Color3.fromRGB(255, 196, 70))
		-- One true pie sector, built from two mirrored right triangles. These
		-- used to be rectangles fanned around the hub, which cannot tile a
		-- circle: they left wedge gaps at the rim and piled up on each other at
		-- the centre, so the face read as a stack of cards rather than a wheel.
		local reach = radius * 0.95
		local wide = reach * math.tan(math.pi / n)
		for _, m in ipairs(SECTOR_HALVES) do
			local w = Instance.new("WedgePart")
			w.Name = "Slice_" .. tostring(seg.id or i)
			w.Size = Vector3.new(depth + 0.02, wide, reach)
			w.CFrame = faceCF
				* CFrame.Angles(0, 0, ang)
				* CFrame.new(m.side * wide * 0.5, reach * 0.5, -0.02)
				* m.rot
			w.Anchored = true
			w.CanCollide = false
			w.Material = Enum.Material.SmoothPlastic
			w.Color = col
			w.Parent = wheel
		end
		--[[
			A CHASE SLICE HAS TO LOOK LIKE ONE.

			Every wedge was flat colour, so a wheel carrying a 1-in-400 pet read
			exactly like a wheel of stardust. Three neon rays down the spoke,
			set just in front of the wedge face and behind the label, so the
			slices worth wanting catch the light as the wheel turns.
		]]
		if seg.hype then
			for k = -1, 1 do
				part({
					Name = "Ray_" .. tostring(seg.id or i) .. "_" .. tostring(k + 2),
					Size = Vector3.new(0.09, reach * 0.60, 0.05),
					CFrame = faceCF
						* CFrame.Angles(0, 0, ang + k * (math.pi / n) * 0.50)
						* CFrame.new(0, reach * 0.56, -0.21),
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(255, 255, 255),
					CanCollide = false,
				}, wheel)
			end
		end
		-- Peg between slices (carnival tick).
		part({
			Name = "Peg_" .. i,
			Size = Vector3.new(0.18, 0.18, 0.55),
			CFrame = faceCF * CFrame.Angles(0, 0, (i / n) * math.pi * 2) * CFrame.new(0, radius + 0.05, -0.2),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 230, 160),
			CanCollide = false,
		}, wheel)

		-- The odds go ON the world wheel too (owner, 2026-10-10: "odds printed
		-- on it"), from the same weights the server rolls.
		local labelText = (isMystery and "?" or tostring(seg.label or "?")) .. "\n" .. Wheel.oddsText(seg)
		--[[
			A label is only as wide as the arc AT ITS OWN RADIUS.

			The width came off `arc`, which is measured at the rim, while the
			label sits at 0.74 of the radius -- where only 74% of that arc
			exists. Every label was therefore about a quarter wider than its
			slice and ran into both neighbours, which is why the wheel read as
			one smeared ring of letters.
		]]
		local labR = radius * 0.74
		local labW = math.clamp(((2 * math.pi * labR) / n) * 0.82, 0.9, 2.6)
		local labPart = part({
			Name = "Label_" .. i,
			Size = Vector3.new(labW, 0.85, 0.08),
			CFrame = faceCF * CFrame.Angles(0, 0, ang) * CFrame.new(0, labR, -0.22),
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

	--[[
		IDLE SPIN, ON EACH CLIENT.

		This was a server Heartbeat PivotTo, which re-replicated about 100 part
		CFrames to every player every frame, forever. MineGroupWheelView now
		turns the wheel on each client about its pivot's up axis (the Pivot part
		above is turned so that axis is the axle). Same look, zero server work.
	]]
	--[[
		The client must know the wheel's real pose before it turns it, or it
		spins about the wrong axis (seen in Studio, 2026-10-10: the slices went
		edge-on). Three things guarantee that under StreamingEnabled:
		  * WorldPivot is set explicitly, so the pivot arrives WITH the model
		    instead of depending on the Pivot part having replicated
		  * Atomic streaming: the wheel and every part of it arrive together,
		    and leave together
		  * PartCount: the client spinner waits until that many parts are
		    present before it records the pose
	]]
	wheel.PrimaryPart = nil
	wheel.WorldPivot = pivot.CFrame
	wheel.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	do
		local count = 0
		for _, d in ipairs(wheel:GetDescendants()) do
			if d:IsA("BasePart") then
				count += 1
			end
		end
		wheel:SetAttribute("PartCount", count)
	end
	wheel:SetAttribute("SpinSpeed", 16) -- degrees per second, ~2.7 RPM

	-- Title + week timer sign above the wheel.
	local sign = part({
		Name = "TimerSign",
		Size = Vector3.new(8.5, 2.4, 0.35),
		-- Clear of the pointer (which tops out at 7.95): at 8.6 the pointer
		-- covered the middle of the countdown.
		CFrame = faceCF * CFrame.new(0, 9.3, 0.2),
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
	title.Text = "DAILY WHEEL"
	title.Parent = signGui
	local tag = Instance.new("TextLabel")
	tag.BackgroundTransparency = 1
	tag.Position = UDim2.new(0, 0, 0.4, 0)
	tag.Size = UDim2.new(1, 0, 0.28, 0)
	tag.Font = Enum.Font.GothamBold
	tag.TextScaled = true
	tag.TextColor3 = Color3.fromRGB(255, 120, 150)
	tag.Text = tostring(Wheel.TAGLINE)
	tag.Parent = signGui
	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.BackgroundTransparency = 1
	timer.Position = UDim2.new(0, 0, 0.68, 0)
	timer.Size = UDim2.new(1, 0, 0.3, 0)
	timer.Font = Enum.Font.GothamMedium
	timer.TextScaled = true
	timer.TextColor3 = Color3.fromRGB(200, 220, 255)
	timer.Text = "NEW SPINS IN —"
	timer.Parent = signGui

	-- Free spins refill at UTC midnight, the same moment for everyone, so a
	-- world sign can count it down.
	task.spawn(function()
		while folder.Parent do
			timer.Text = "NEW FREE SPINS IN  " .. fmtLeft(Wheel.resetIn())
			task.wait(1)
		end
	end)

	-- Prompt pad in front of the wheel. This is the spot players walk onto, so
	-- it has to READ as a platform: it was Transparency 1 / CanCollide false,
	-- which left a Spin prompt floating over the apron with nothing visible to
	-- step onto and nothing solid under your feet.
	local pad = part({
		Name = "Pad",
		Size = Vector3.new(7, 1, 5),
		CFrame = faceCF * CFrame.new(0, -6.7, -3.2),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(34, 26, 46),
		CanCollide = true,
	}, folder)
	-- Neon lip a shade wider than the pad: the glowing outline is what makes the
	-- step legible from across the lobby, where a flat dark slab would not be.
	part({
		Name = "PadTrim",
		Size = Vector3.new(7.6, 0.18, 5.6),
		CFrame = faceCF * CFrame.new(0, -6.3, -3.2),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 196, 70),
		CanCollide = false,
	}, folder)
	local padLabel = surfaceLabel(pad, "STAND HERE", {
		Face = Enum.NormalId.Top,
		pps = 26,
		color = Color3.fromRGB(255, 214, 120),
	})
	-- A Top-face SurfaceGui lands 180 degrees out for someone walking up to the
	-- wheel from the apron, and wrapped "STAND HERE" onto two flipped lines.
	padLabel.Rotation = 180
	pad:SetAttribute("Machine", "groupWheel")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Spin"
	prompt.ObjectText = "Daily Wheel"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 18
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = pad

	CollectionService:AddTag(folder, "MineGroupWheel")
	return folder
end

return GroupWheelService
