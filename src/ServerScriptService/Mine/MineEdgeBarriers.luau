-- Invisible walls on true map edges only.
-- Lobby keeps a road gap on +Z toward Dirt Meadow; meadow rim opens toward lobby.
-- Super-high roof so fly-outs still bounce back without touching normal play.
local CollectionService = game:GetService("CollectionService")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))

local MineEdgeBarriers = {}
local FOLDER_NAME = "EdgeBarriers"
local TAG = "MineEdgeBarrier"

-- Path from fountain to meadow: pathBetween(0,0,0) -> (0,0,280), width 18.
local LOBBY_PATH_HALF = 16
-- Clearance between the island's outermost solid prop and the rim wall, so the
-- wall is never the thing you meet while standing on visible ground.
local RIM_MARGIN = 26
-- Ceiling far above clouds / dig camera; never a gameplay obstacle.
local ROOF_Y = 2000
local ROOF_THICK = 8

local function folder()
	local world = workspace:FindFirstChild("MineWorld")
	if not world then
		return nil
	end
	local f = world:FindFirstChild(FOLDER_NAME)
	if not f then
		f = Instance.new("Folder")
		f.Name = FOLDER_NAME
		f.Parent = world
	end
	return f
end

local function wall(parent, name, size, cf)
	local p = parent:FindFirstChild(name)
	if not p then
		p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = true
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		CollectionService:AddTag(p, TAG)
	end
	p.Size = size
	p.CFrame = cf
	return p
end

local function clearChild(parent, name)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

function MineEdgeBarriers.buildLobby()
	local f = folder()
	if not f then
		return
	end
	local a, b = C.LOBBY_MIN, C.LOBBY_MAX
	if not a or not b then
		return
	end
	local pad = 1
	local minX, maxX = a.X - pad, b.X + pad
	local minZ, maxZ = a.Z - pad, b.Z + pad
	local minY = a.Y - 4
	local maxY = ROOF_Y
	local h = maxY - minY
	local midY = (minY + maxY) * 0.5
	local thick = 3
	local spanX = maxX - minX
	local spanZ = maxZ - minZ
	local root = f:FindFirstChild("Lobby") or Instance.new("Folder")
	root.Name = "Lobby"
	root.Parent = f

	-- Solid edges that are NOT the meadow road. Walls climb to the roof.
	wall(root, "S", Vector3.new(spanX + thick * 2, h, thick), CFrame.new((minX + maxX) * 0.5, midY, minZ))
	wall(root, "E", Vector3.new(thick, h, spanZ), CFrame.new(maxX, midY, (minZ + maxZ) * 0.5))
	wall(root, "W", Vector3.new(thick, h, spanZ), CFrame.new(minX, midY, (minZ + maxZ) * 0.5))

	-- +Z face: fully open toward Dirt Meadow.
	--
	-- This used to be two stubs pinching the road down to a 32-stud slot, and
	-- players kept walking into the invisible half of it from either side.
	-- The floor plate below (551x551) already carries anyone who steps off the
	-- lobby proper, so there is nothing here to fall into and nothing to guard.
	clearChild(root, "N")
	clearChild(root, "N_L")
	clearChild(root, "N_R")

	-- Invisible ceiling (path gap does not matter overhead).
	wall(root, "Roof", Vector3.new(spanX + thick * 2, ROOF_THICK, spanZ + thick * 2),
		CFrame.new((minX + maxX) * 0.5, ROOF_Y + ROOF_THICK * 0.5, (minZ + maxZ) * 0.5))
end

--[[
	How far the zone's own solid, visible content actually reaches.

	The rim used to sit at a flat ISLAND + 8 = 188 studs. Measured against what
	is really built, every single zone overruns that: meadow's props reach 298,
	mistreef 267, and the other eight run 30 to 37 past it. The result is an
	invisible wall standing in the middle of ground you can see and walk on --
	which is exactly what it feels like, and what players quit over.

	So measure the island and put the wall beyond it. Falls back to the caller's
	number when a biome folder has not been built yet, so first boot is safe.
]]
function MineEdgeBarriers.contentRadius(zone, fallback)
	local world = workspace:FindFirstChild("MineWorld")
	local folder = world and world:FindFirstChild("Biome_" .. tostring(zone.id))
	if not folder then
		return fallback
	end
	local origin = C.zoneOrigin(zone)
	local o = Vector2.new(origin.X, origin.Z)
	local reach = 0
	for _, d in ipairs(folder:GetDescendants()) do
		-- Solid and visible: decoration you can stand on decides the edge.
		if d:IsA("BasePart") and d.CanCollide and d.Transparency < 0.9 then
			local r = (Vector2.new(d.Position.X, d.Position.Z) - o).Magnitude
				+ math.max(d.Size.X, d.Size.Z) * 0.5
			if r > reach then
				reach = r
			end
		end
	end
	if reach <= 0 then
		return fallback
	end
	return math.max(fallback, reach + RIM_MARGIN)
end

function MineEdgeBarriers.buildZone(zone)
	if not zone or not zone.id then
		return
	end
	local f = folder()
	if not f then
		return
	end
	local origin = C.zoneOrigin(zone)
	local radius = MineEdgeBarriers.contentRadius(zone, (C.ISLAND or 180) + 8)
	local segments = 20
	local thick = 4
	local wallH = ROOF_Y - (origin.Y - 4)
	if wallH < 64 then
		wallH = 64
	end
	local midY = (origin.Y - 4) + wallH * 0.5
	local chord = 2 * radius * math.sin(math.pi / segments) + 2
	local root = f:FindFirstChild("Zone_" .. zone.id) or Instance.new("Folder")
	root.Name = "Zone_" .. zone.id
	root.Parent = f

	-- Open the rim toward the approach path (lobby → meadow on -Z of meadow).
	local gapDir = Vector3.new(-origin.X, 0, -origin.Z)
	if gapDir.Magnitude < 1 then
		gapDir = Vector3.new(0, 0, -1)
	else
		gapDir = gapDir.Unit
	end
	-- Wider mouth for meadow so the stone road is never clipped by a rim panel.
	local isGate = zone.id == "meadow" or (C.zoneIndex and C.zoneIndex(zone.id) == 1)
	local gapDot = isGate and 0.35 or 2
	for i = 0, segments - 1 do
		local a0 = (i / segments) * math.pi * 2
		local mid = a0 + (math.pi / segments)
		local dir = Vector3.new(math.sin(mid), 0, math.cos(mid))
		if gapDot < 1.5 and dir:Dot(gapDir) > gapDot then
			clearChild(root, "Seg" .. i)
		else
			local pos = Vector3.new(origin.X + dir.X * radius, midY, origin.Z + dir.Z * radius)
			local look = CFrame.lookAt(pos, Vector3.new(origin.X, midY, origin.Z))
			wall(root, "Seg" .. i, Vector3.new(chord, wallH, thick), look)
		end
	end

	-- Flat roof over the island (diameter covers rim).
	local roofSpan = radius * 2 + thick * 2
	wall(root, "Roof", Vector3.new(roofSpan, ROOF_THICK, roofSpan),
		CFrame.new(origin.X, ROOF_Y + ROOF_THICK * 0.5, origin.Z))
end

function MineEdgeBarriers.buildAll()
	MineEdgeBarriers.buildLobby()
	for _, zone in ipairs(C.ZONES or {}) do
		pcall(MineEdgeBarriers.buildZone, zone)
	end
end

return MineEdgeBarriers
