--[[
	MineThemeKit: the shared toolbox for zones with a look of their own.

	ThemeKit.new(kit, origin, axis) hands back helpers bound to one zone's frame.
	H(l, y, b) and HP(l, y, b) place things `l` studs to the side, `y` above
	GROUND and `b` back from the pit centre toward where you arrive -- the same
	coordinates WorldBuilder.buildOutpost uses, so a theme's shops, stand and
	portals land where the server expects them.

	Parts go through WorldBuilder's own `part`, so its coplanar guard applies.
	`deco = true` makes a part pure dressing: no collision, no raycasts, no touch
	events. Anything that hangs over a pit must be dressing, or it eats clicks.

	MineHarbor predates this and carries its own copies; the zones after it use
	this one.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MineConfig = require(ReplicatedStorage:WaitForChild("Mine"):WaitForChild("Shared"):WaitForChild("MineConfig"))

local ThemeKit = {}
local M = Enum.Material

function ThemeKit.C3(r, g, b)
	return Color3.fromRGB(r, g, b)
end

function ThemeKit.smoothstep(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function ThemeKit.new(kit, origin, axis)
	local T = { kit = kit, G = kit.GROUND, M = M, origin = origin, axis = axis }
	local side = Vector3.new(-axis.Z, 0, axis.X)
	local HF = CFrame.fromMatrix(Vector3.new(origin.X, kit.GROUND, origin.Z), side, Vector3.yAxis, -axis)
	T.HF, T.side, T.backV = HF, side, -axis
	T.hole = MineConfig.GRID * MineConfig.BLOCK * 0.5

	function T.H(l, y, b)
		return HF * CFrame.new(l, y, b)
	end
	function T.HP(l, y, b)
		return (HF * CFrame.new(l, y, b)).Position
	end

	function T.folder(parent, name)
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
		return f
	end

	function T.mk(props)
		local p
		if props.Class then
			p = Instance.new(props.Class)
			p.Anchored = true
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			p.Size = props.Size
			p.CFrame = props.CFrame
			p.Color = props.Color or Color3.new(0.5, 0.5, 0.5)
			p.Material = props.Material or M.SmoothPlastic
			p.Name = props.Name or props.Class
			p.Parent = props.Parent
		else
			p = kit.part(props)
		end
		if props.deco then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		elseif props.noQuery then
			p.CanQuery = false
		end
		if props.Reflectance then
			p.Reflectance = props.Reflectance
		end
		if props.Transparency then
			p.Transparency = props.Transparency
		end
		if props.shadow == false then
			p.CastShadow = false
		end
		return p
	end

	function T.rod(parent, name, a, b, d, color, material, deco)
		local v = b - a
		local cf
		if math.abs(v.Unit.Y) > 0.999 then
			cf = CFrame.new((a + b) * 0.5) * CFrame.Angles(0, 0, math.rad(90))
		else
			cf = CFrame.lookAt((a + b) * 0.5, b) * CFrame.Angles(0, math.rad(90), 0)
		end
		return T.mk({ Name = name, Parent = parent, Size = Vector3.new(v.Magnitude, d, d), CFrame = cf,
			Color = color, Material = material or M.SmoothPlastic, Shape = Enum.PartType.Cylinder, deco = deco })
	end

	function T.beam(parent, name, a, b, w, h, color, material, deco)
		local v = b - a
		local up = (math.abs(v.Unit.Y) > 0.999) and Vector3.xAxis or Vector3.yAxis
		return T.mk({ Name = name, Parent = parent, Size = Vector3.new(w, h, v.Magnitude),
			CFrame = CFrame.lookAt((a + b) * 0.5, b, up), Color = color, Material = material or M.SmoothPlastic, deco = deco })
	end

	function T.ball(parent, name, pos, d, color, material, deco)
		return T.mk({ Name = name, Parent = parent, Size = Vector3.new(d, d, d), CFrame = CFrame.new(pos),
			Color = color, Material = material or M.SmoothPlastic, Shape = Enum.PartType.Ball, deco = deco })
	end

	function T.blob(parent, name, cf, size, color, material, deco)
		local p = T.mk({ Name = name, Parent = parent, Size = size, CFrame = cf, Color = color,
			Material = material or M.SmoothPlastic, deco = deco })
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		return p
	end

	function T.wedge(parent, name, cf, size, color, material, deco)
		return T.mk({ Class = "WedgePart", Name = name, Parent = parent, Size = size, CFrame = cf,
			Color = color, Material = material, deco = deco })
	end

	-- A sagging line between two hosts. Beam handles run along each
	-- attachment's X axis, pointed straight down.
	function T.rope(host0, p0, host1, p1, sag, width, color, emission)
		local down = Vector3.new(0, -1, 0)
		local a0 = Instance.new("Attachment")
		a0.Parent = host0
		a0.WorldCFrame = CFrame.fromMatrix(p0, down, Vector3.xAxis)
		local a1 = Instance.new("Attachment")
		a1.Parent = host1
		a1.WorldCFrame = CFrame.fromMatrix(p1, down, Vector3.xAxis)
		local b = Instance.new("Beam")
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Width0 = width or 0.17
		b.Width1 = width or 0.17
		b.Color = ColorSequence.new(color or Color3.fromRGB(178, 148, 102))
		b.LightInfluence = emission and 0 or 1
		b.LightEmission = emission or 0
		b.FaceCamera = true
		b.Segments = 14
		local s = (sag or 0) / 0.75
		b.CurveSize0 = s
		b.CurveSize1 = -s
		b.Parent = host0
		return b
	end

	function T.model(parent, name)
		local m = Instance.new("Model")
		m.Name = name
		m.Parent = parent
		return m
	end

	function T.tag(inst, name, attrs)
		for k, v in pairs(attrs or {}) do
			inst:SetAttribute(k, v)
		end
		if inst:IsA("Model") and inst.ModelStreamingMode == Enum.ModelStreamingMode.Default then
			inst.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		end
		CollectionService:AddTag(inst, name)
		return inst
	end

	function T.writeOn(p, text, opts)
		opts = opts or {}
		local gui = Instance.new("SurfaceGui")
		gui.Face = opts.face or Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = opts.pps or 36
		gui.LightInfluence = opts.glow and 0 or 1
		gui.Brightness = opts.glow or 1
		gui.MaxDistance = opts.maxDistance or 160
		gui.Parent = p
		local t = Instance.new("TextLabel")
		t.Name = "Text"
		t.BackgroundTransparency = 1
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Position = UDim2.fromScale(0.5, 0.5)
		t.Size = UDim2.fromScale(opts.w or 0.88, opts.h or 0.84)
		t.Font = opts.font or Enum.Font.BuilderSansBold
		t.TextColor3 = opts.color or Color3.fromRGB(238, 236, 226)
		t.TextScaled = true
		t.TextWrapped = true
		t.TextXAlignment = opts.align or Enum.TextXAlignment.Center
		t.Text = text
		t.Parent = gui
		return gui, t
	end

	function T.light(parent, class, props)
		local l = Instance.new(class or "PointLight")
		for k, v in pairs(props or {}) do
			l[k] = v
		end
		l.Parent = parent
		return l
	end

	function T.emitter(parent, props)
		local e = Instance.new("ParticleEmitter")
		for k, v in pairs(props or {}) do
			e[k] = v
		end
		e.Parent = parent
		return e
	end

	-- An invisible anchor for particles or lights.
	function T.source(parent, name, pos, size)
		return T.mk({ Name = name, Parent = parent, Size = size or Vector3.new(1, 1, 1), CFrame = CFrame.new(pos),
			Transparency = 1, deco = true, shadow = false })
	end

	-- The marker MineAmbience reads for this zone's sky, water and light.
	function T.skyMarker(parent, attrs)
		local holder = Instance.new("Model")
		holder.Name = "Atmosphere"
		holder.Parent = parent
		local marker = T.source(holder, "AmbZone", T.HP(0, 30, 0))
		for k, v in pairs(attrs) do
			marker:SetAttribute(k, v)
		end
		CollectionService:AddTag(marker, "AmbZone")
		holder.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		return marker
	end

	--[[
		Write a heightfield into the voxels around the zone in one pass.
		sample(l, b) returns: solid surface height (world y), its material, and
		optionally a liquid surface height (world y) for water above it. The shaft
		is always carved, exactly as on every other island. Measured: a solid
		voxel [y0, y0+4) at occupancy o draws its surface at y0 + 2 + 4o, a liquid
		one at y0 + 4o.
	]]
	function T.writeTerrain(terrain, radius, Y0, Y1, sample)
		terrain:FillBlock(CFrame.new(origin.X, (Y0 + Y1) / 2, origin.Z), Vector3.new(radius * 2 + 40, Y1 - Y0 + 20, radius * 2 + 40), M.Air)
		local nY = (Y1 - Y0) // 4
		local pitHalf = T.hole + 5
		local minX = math.floor((origin.X - radius) / 4) * 4
		local minZ = math.floor((origin.Z - radius) / 4) * 4
		local cells = math.ceil(radius * 2 / 4) + 2
		local half = math.ceil(cells / 2)
		for qx = 0, 1 do
			for qz = 0, 1 do
				local cx0, cz0 = qx * half, qz * half
				local nx, nz = math.min(half, cells - cx0), math.min(half, cells - cz0)
				if nx > 0 and nz > 0 then
					local mats, occ, liq = table.create(nx), table.create(nx), table.create(nx)
					for i = 1, nx do
						local mi, oi, li = table.create(nY), table.create(nY), table.create(nY)
						mats[i], occ[i], liq[i] = mi, oi, li
						for j = 1, nY do
							mi[j], oi[j], li[j] = table.create(nz), table.create(nz), table.create(nz)
						end
						local wx = minX + (cx0 + i - 1) * 4 + 2
						for k = 1, nz do
							local wz = minZ + (cz0 + k - 1) * 4 + 2
							local dx, dz = wx - origin.X, wz - origin.Z
							local l = dx * side.X + dz * side.Z
							local b = dx * -axis.X + dz * -axis.Z
							local inPit = math.abs(l) <= pitHalf and math.abs(b) <= pitHalf
							local h, mat, wet, deep = sample(l, b)
							for j = 1, nY do
								local y0 = Y0 + (j - 1) * 4
								local o = 0
								if not inPit and h then
									o = math.clamp((h - 2 - y0) / 4, 0, 1)
									if deep and y0 + 4 <= deep then
										o = 0 -- a floating rock has an underside
									end
								end
								local w = 0
								if wet and not inPit then
									w = math.max(0, math.clamp((wet - y0) / 4, 0, 1) - o)
								end
								mi[j][k] = (o > 0) and ((y0 + 4 < (h or 0) - 7) and (T.fill or M.Rock) or mat) or M.Air
								oi[j][k] = o
								li[j][k] = w
							end
						end
					end
					terrain:WriteVoxelChannels(
						Region3.new(Vector3.new(minX + cx0 * 4, Y0, minZ + cz0 * 4),
							Vector3.new(minX + (cx0 + nx) * 4, Y1, minZ + (cz0 + nz) * 4)),
						4, { SolidMaterial = mats, SolidOccupancy = occ, LiquidOccupancy = liq })
				end
			end
		end
	end

	return T
end

return ThemeKit
