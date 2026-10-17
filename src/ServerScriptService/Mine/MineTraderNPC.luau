--[[
	MineTraderNPC: the five wandering traders, in the world.

	MineTrader decides WHERE they are and WHAT they sell; this puts a body at each
	spot and takes it away again when the rotation turns. The split is deliberate
	-- the rules are a pure function of the rotation number and are harnessed in
	tools/verify/trader.js, and nothing here is allowed to make a decision that
	the harness cannot see.

	STATIC NPCs, built from parts (owner's choice, 2026-10-07). No Humanoid and no
	rig: five humanoids would replicate to every client and need a state machine
	each, for a figure that stands still behind a stall. Anchored parts with one
	ProximityPrompt is what every other interactable in the mine already is.

	REBUILT, NOT MOVED, when the rotation turns. Tweening five NPCs across the map
	would mean a trader is briefly nowhere and briefly in two places; destroying
	and rebuilding is both simpler and honest about what happened.
]]
local Players = game:GetService("Players")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local Depth = require(shared:WaitForChild("MineDepth"))
local Trader = require(shared:WaitForChild("MineTrader"))

local MineTraderNPC = {}

local FOLDER = "WanderingTraders"
local started = false
local liveRotation = nil

-- Where a trader may stand: every depth plaza that has actually been built.
-- Asked of the world rather than of the seam ladder, so a trader is never placed
-- at a plaza this server never made.
function MineTraderNPC.spots()
	local out = {}
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	if not pits then
		return out
	end
	for _, folder in ipairs(pits:GetChildren()) do
		local zoneId, seam = string.match(folder.Name, "^DepthPlaza_(.-)_(%d+)$")
		-- Only a DRESSED outpost can host one. standingCFrame stands the trader on
		-- SurfaceClone.Square -- the pad the elevator lands on -- so a plaza
		-- without one has nowhere to put a stall. Filtering here rather than
		-- letting the build skip it means all five placements land somewhere,
		-- instead of silently spawning three.
		local clone = folder:FindFirstChild("SurfaceClone")
		if zoneId and seam and clone and clone:FindFirstChild("Square") then
			local zi = (C.zoneIndex and C.zoneIndex(zoneId)) or 1
			table.insert(out, {
				zoneId = zoneId,
				zoneIndex = zi,
				seam = tonumber(seam),
				folder = folder,
			})
		end
	end
	-- Sorted, because GetChildren order is not guaranteed and placement draws
	-- from this list by index. An unsorted list would make the "every server
	-- agrees" property quietly false.
	table.sort(out, function(a, b)
		if a.zoneId ~= b.zoneId then
			return a.zoneId < b.zoneId
		end
		return a.seam < b.seam
	end)
	return out
end

local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	-- Not query-able and not shadow-casting, like every other decorative part in
	-- the mine: five of these per server add up.
	p.CanQuery = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

--[[
	One trader: a stall, a hooded figure behind it, and a prompt.

	The figure is deliberately simple and a bit tall -- it reads at a distance
	down a mineshaft, which is the only place anyone will see it.
]]
local function buildTrader(parent, placement, cf)
	local m = Instance.new("Model")
	m.Name = ("Trader_%s_%d"):format(placement.zoneId, placement.seam)
	m:SetAttribute("ZoneId", placement.zoneId)
	m:SetAttribute("Seam", placement.seam)
	m:SetAttribute("Slot", placement.slot)
	m.Parent = parent

	local cloth = Color3.fromRGB(62, 48, 84)
	local trim = Color3.fromRGB(196, 162, 92)
	local skin = Color3.fromRGB(44, 40, 52)

	-- Stall: a counter with an awning, so it reads as a shop and not as a person
	-- standing in a hole.
	local counter = part(m, "Counter", Vector3.new(7, 3.2, 2.4), cf * CFrame.new(0, 1.6, 0),
		Color3.fromRGB(74, 56, 40), Enum.Material.Wood)
	counter.CanCollide = true
	part(m, "CounterTop", Vector3.new(7.6, 0.3, 3), cf * CFrame.new(0, 3.3, 0), trim, Enum.Material.WoodPlanks)
	part(m, "PostL", Vector3.new(0.3, 5, 0.3), cf * CFrame.new(-3.5, 2.5, -1.2), trim)
	part(m, "PostR", Vector3.new(0.3, 5, 0.3), cf * CFrame.new(3.5, 2.5, -1.2), trim)
	part(m, "Awning", Vector3.new(8.4, 0.3, 3.4), cf * CFrame.new(0, 5.1, -0.4), cloth, Enum.Material.Fabric)

	-- The trader: torso, hooded head, two arms resting on the counter.
	part(m, "Torso", Vector3.new(2.2, 2.8, 1.2), cf * CFrame.new(0, 3.1, -1.9), cloth, Enum.Material.Fabric)
	part(m, "Head", Vector3.new(1.3, 1.3, 1.3), cf * CFrame.new(0, 5.1, -1.9), skin)
	part(m, "Hood", Vector3.new(1.7, 1.1, 1.7), cf * CFrame.new(0, 5.5, -2.0), cloth, Enum.Material.Fabric)
	part(m, "ArmL", Vector3.new(0.6, 0.6, 2.2), cf * CFrame.new(-1.3, 3.4, -1.0), cloth, Enum.Material.Fabric)
	part(m, "ArmR", Vector3.new(0.6, 0.6, 2.2), cf * CFrame.new(1.3, 3.4, -1.0), cloth, Enum.Material.Fabric)

	-- A lantern, because a plaza at 3,000 layers down is dark.
	local lamp = part(m, "Lantern", Vector3.new(0.6, 0.8, 0.6), cf * CFrame.new(3.2, 4.2, -0.6),
		Color3.fromRGB(255, 214, 140), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 18
	light.Color = Color3.fromRGB(255, 206, 140)
	-- Shadows off: GlobalShadows is off game-wide and a shadow-casting light here
	-- would be the only one in the mine paying for it.
	light.Shadows = false
	light.Parent = lamp

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Trade"
	prompt.ObjectText = "Wandering Trader"
	prompt.MaxActivationDistance = 16
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter
	return m, prompt
end

--[[
	Where on the plaza a trader stands.

	THE SAME PART THE ELEVATOR LANDS ON. MineDepthPlazas.ride puts a player at
	`SurfaceClone.Square`, which is by definition the dressed, walled floor of the
	outpost -- so a trader standing on it is standing where players arrive.

	Three geometric guesses came before this, and each was wrong in a way only a
	sweep over many rotations exposed:

	  Casting down from above the bounding box hit the Ceiling, a 198x4x128 slab,
	  and stood the trader on the roof.

	  Casting from under the TOPMOST part assumed that part is the roof. In
	  bigbang and bloodmoon the tallest thing is a crane or a hanging chain whose
	  bottom is below the deck, so the ray began underground and found nothing --
	  65 of 300 placements had no floor under them.

	  Taking the widest flat slab picked the Ceiling again, because it is wider
	  than any floor: 269 of 300 placements ended up on the roof.

	The lesson is in the commit message, but briefly: the layout already had an
	authoritative answer and I kept inferring one instead.
]]
local function standingCFrame(folder, seam)
	local clone = folder:FindFirstChild("SurfaceClone")
	local square = clone and clone:FindFirstChild("Square")
	if not (square and square:IsA("BasePart")) then
		return nil
	end
	--[[
		Off to one side of the square so the middle stays clear -- that is where
		the elevator puts people down -- but well inside its own footprint, and
		facing back toward the centre so the stall front greets an arrival.
	]]
	local halfX = square.Size.X * 0.5
	local offX = math.max(0, math.min(halfX - 4, halfX * 0.62))
	local at = Vector3.new(
		square.Position.X - offX,
		square.Position.Y + square.Size.Y * 0.5,
		square.Position.Z)
	return CFrame.lookAt(at, Vector3.new(square.Position.X, at.Y, square.Position.Z))
end

function MineTraderNPC.clear()
	local world = workspace:FindFirstChild("MineWorld")
	local f = world and world:FindFirstChild(FOLDER)
	if f then
		f:Destroy()
	end
	liveRotation = nil
end

--[[
	Build the roster for `rotation`. Returns how many were actually placed, which
	can be fewer than five early on: a fresh server has only the plazas it has
	built, and placing a trader at a plaza that does not exist would be a prompt
	floating in rock.
]]
function MineTraderNPC.build(rotation, onTrade)
	local world = workspace:FindFirstChild("MineWorld")
	if not world then
		return 0
	end
	local old = world:FindFirstChild(FOLDER)
	if old then
		old:Destroy()
	end
	local spots = MineTraderNPC.spots()
	if #spots == 0 then
		return 0
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	folder.Parent = world

	local made = 0
	for _, placement in ipairs(Trader.placements(rotation, spots)) do
		local spot
		for _, s in ipairs(spots) do
			if s.zoneId == placement.zoneId and s.seam == placement.seam then
				spot = s
				break
			end
		end
		local cf = spot and standingCFrame(spot.folder, placement.seam)
		if cf then
			local model, prompt = buildTrader(folder, placement, cf)
			made += 1
			prompt.Triggered:Connect(function(plr)
				if onTrade then
					onTrade(plr, placement)
				end
			end)
			model:SetAttribute("Rotation", rotation)
		end
	end
	liveRotation = rotation
	return made
end

--[[
	Start the rotation loop.

	Checks once a minute rather than sleeping until the boundary: a server that
	slept through a rotation would show a stale roster, and `os.time()` is the
	only authority on which rotation it is.
]]
function MineTraderNPC.start(onTrade)
	if started then
		return
	end
	started = true
	task.spawn(function()
		while true do
			local rot = Trader.rotationFor(os.time())
			if rot ~= liveRotation then
				local ok, err = pcall(MineTraderNPC.build, rot, onTrade)
				if not ok then
					warn("[Trader] build failed: " .. tostring(err))
				end
			end
			task.wait(60)
		end
	end)
end

-- What this rotation's trader at a spot is selling, for the shop panel.
function MineTraderNPC.offer(zoneId, seam)
	local zi = (C.zoneIndex and C.zoneIndex(zoneId)) or 1
	local rot = Trader.rotationFor(os.time())
	return {
		rotation = rot,
		zoneId = zoneId,
		zoneIndex = zi,
		seam = seam,
		secondsLeft = Trader.secondsLeft(os.time()),
		stock = Trader.stockFor(rot, zi, seam),
	}
end

--[[
	Is this player allowed to buy from the trader at this spot?

	The prompt is in the world, so anyone standing there can fire it, and a client
	can fire the buy verb without ever walking to one. Both are checked against
	the same thing: the trader has to BE there this rotation, and the player has
	to have earned the depth. Without the first check a client could name any
	outpost and buy the deep stock from the surface.
]]
function MineTraderNPC.canTrade(p, zoneId, seam, auth)
	local rot = Trader.rotationFor(os.time())
	local here = false
	for _, placement in ipairs(Trader.placements(rot, MineTraderNPC.spots())) do
		if placement.zoneId == zoneId and placement.seam == seam then
			here = true
			break
		end
	end
	if not here then
		return false, "no_trader"
	end
	if auth and auth.canAccessSeam and not auth.canAccessSeam(p, zoneId, seam) then
		return false, "need_seam"
	end
	return true, nil
end

return MineTraderNPC
