-- HQ explosive mesh baker: EditableMesh ~15-20k tris into ToolModels_50
local AssetService = game:GetService("AssetService")

local M = {}

local function C3(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function hash32(s)
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (h * 16777619) % 4294967296
	end
	return h
end

local function rng(seed)
	local s = seed % 2147483647
	if s <= 0 then s = 1 end
	return function()
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
end

local function addV(em, p, verts)
	local id = em:AddVertex(p)
	verts[#verts + 1] = id
	return id
end

local function tri(em, a, b, c, counter)
	em:AddTriangle(a, b, c)
	if counter then counter.n += 1 end
end

-- UV sphere centered at `c`, radius `r`
local function addSphere(em, c, r, lonN, latN)
	local rings = {}
	for lat = 0, latN do
		local v = lat / latN
		local phi = v * math.pi
		local y = c.Y + r * math.cos(phi)
		local rr = r * math.sin(phi)
		local row = {}
		for lon = 0, lonN - 1 do
			local u = lon / lonN
			local th = u * math.pi * 2
			row[lon + 1] = em:AddVertex(Vector3.new(c.X + rr * math.cos(th), y, c.Z + rr * math.sin(th)))
		end
		rings[lat + 1] = row
	end
	for lat = 0, latN - 1 do
		local a, b = rings[lat + 1], rings[lat + 2]
		for lon = 0, lonN - 1 do
			local n = (lon % lonN) + 1
			local m = ((lon + 1) % lonN) + 1
			if lat ~= 0 then tri(em, a[n], a[m], b[m]) end
			if lat ~= latN - 1 then tri(em, a[n], b[m], b[n]) end
		end
	end
end

-- Cylinder along Y, center c, radius r, half-height hh
local function addCylinder(em, c, r, hh, radN, hN)
	local rings = {}
	for hi = 0, hN do
		local y = c.Y - hh + (2 * hh) * (hi / hN)
		local row = {}
		for i = 0, radN - 1 do
			local th = (i / radN) * math.pi * 2
			row[i + 1] = em:AddVertex(Vector3.new(c.X + r * math.cos(th), y, c.Z + r * math.sin(th)))
		end
		rings[hi + 1] = row
	end
	local top = em:AddVertex(Vector3.new(c.X, c.Y + hh, c.Z))
	local bot = em:AddVertex(Vector3.new(c.X, c.Y - hh, c.Z))
	for hi = 0, hN - 1 do
		local a, b = rings[hi + 1], rings[hi + 2]
		for i = 0, radN - 1 do
			local n, m = i + 1, ((i + 1) % radN) + 1
			tri(em, a[n], a[m], b[m])
			tri(em, a[n], b[m], b[n])
		end
	end
	local topR, botR = rings[hN + 1], rings[1]
	for i = 0, radN - 1 do
		local n, m = i + 1, ((i + 1) % radN) + 1
		tri(em, top, topR[m], topR[n])
		tri(em, bot, botR[n], botR[m])
	end
end

-- Torus / band around Y
local function addTorus(em, c, R, tube, segR, segT)
	local grid = {}
	for i = 0, segR - 1 do
		grid[i + 1] = {}
		local th = (i / segR) * math.pi * 2
		local cx = c.X + R * math.cos(th)
		local cz = c.Z + R * math.sin(th)
		for j = 0, segT - 1 do
			local ph = (j / segT) * math.pi * 2
			local nx = math.cos(th) * math.cos(ph)
			local ny = math.sin(ph)
			local nz = math.sin(th) * math.cos(ph)
			grid[i + 1][j + 1] = em:AddVertex(Vector3.new(cx + tube * nx, c.Y + tube * ny, cz + tube * nz))
		end
	end
	for i = 0, segR - 1 do
		local i2 = (i + 1) % segR
		for j = 0, segT - 1 do
			local j2 = (j + 1) % segT
			local a = grid[i + 1][j + 1]
			local b = grid[i2 + 1][j + 1]
			local c1 = grid[i2 + 1][j2 + 1]
			local d = grid[i + 1][j2 + 1]
			tri(em, a, b, c1)
			tri(em, a, c1, d)
		end
	end
end

-- Helix fuse (compact spheres — keep segs low for tri budget)
local function addHelix(em, origin, turns, height, radius, tube, segs)
	for i = 0, segs do
		local t = i / segs
		local ang = t * turns * math.pi * 2
		local y = origin.Y + t * height
		local p = Vector3.new(origin.X + radius * math.cos(ang), y, origin.Z + radius * math.sin(ang))
		addSphere(em, p, tube, 6, 4)
	end
end

local function addBox(em, cf, size, div)
	div = div or 2
	local sx, sy, sz = size.X, size.Y, size.Z
	local function corner(x, y, z)
		return cf:PointToWorldSpace(Vector3.new(x * sx * 0.5, y * sy * 0.5, z * sz * 0.5))
	end
	-- subdivided faces for density
	local function face(u0, v0, u1, v1, u2, v2, u3, v3)
		local grid = {}
		for i = 0, div do
			grid[i + 1] = {}
			local ti = i / div
			for j = 0, div do
				local tj = j / div
				local p = corner(u0, v0, u0) -- placeholder overwritten
				local a = Vector3.new(u0, v0, u0)
			end
		end
	end
	-- simpler: 6 faces with mid subdivision via spheres skipped — use flat quads as 2 tris * density
	local function quad(p1, p2, p3, p4)
		local function lerp2(a, b, t) return a:Lerp(b, t) end
		local g = {}
		for i = 0, div do
			g[i + 1] = {}
			local ti = i / div
			local left = lerp2(p1, p4, ti)
			local right = lerp2(p2, p3, ti)
			for j = 0, div do
				local tj = j / div
				g[i + 1][j + 1] = em:AddVertex(lerp2(left, right, tj))
			end
		end
		for i = 0, div - 1 do
			for j = 0, div - 1 do
				local a, b = g[i + 1][j + 1], g[i + 1][j + 2]
				local c, d = g[i + 2][j + 2], g[i + 2][j + 1]
				tri(em, a, b, c)
				tri(em, a, c, d)
			end
		end
	end
	local p = {
		corner(-1, -1, -1), corner(1, -1, -1), corner(1, -1, 1), corner(-1, -1, 1),
		corner(-1, 1, -1), corner(1, 1, -1), corner(1, 1, 1), corner(-1, 1, 1),
	}
	quad(p[1], p[2], p[3], p[4]) -- bottom
	quad(p[5], p[8], p[7], p[6]) -- top
	quad(p[1], p[5], p[6], p[2]) -- -z
	quad(p[4], p[3], p[7], p[8]) -- +z
	quad(p[1], p[4], p[8], p[5]) -- -x
	quad(p[2], p[6], p[7], p[3]) -- +x
end

function M.buildMesh(spec)
	local em = AssetService:CreateEditableMesh()
	local shape = spec.shape or "classic"
	local r = spec.radius or 0.55
	local cy = spec.cy or 0.55

	if shape == "classic" or shape == "nuke" or shape == "fossil" or shape == "kiln" or shape == "abyss" or shape == "event" then
		local lon = spec.lon or 72
		local lat = spec.lat or 48
		addSphere(em, Vector3.new(0, cy, 0), r, lon, lat)
		-- equator + latitude bands
		local bands = spec.bands or 3
		for i = 1, bands do
			local offsetY = cy + (i - (bands + 1) / 2) * r * 0.28
			addTorus(em, Vector3.new(0, offsetY, 0), r * 0.92, r * 0.045, 48, 12)
		end
		-- rivets
		local rivets = spec.rivets or 10
		for i = 0, rivets - 1 do
			local th = (i / rivets) * math.pi * 2
			local p = Vector3.new(math.cos(th) * r * 0.98, cy, math.sin(th) * r * 0.98)
			addSphere(em, p, r * 0.055, 10, 8)
		end
		-- collar + handle
		addCylinder(em, Vector3.new(0, cy - r * 0.55, 0), r * 0.28, r * 0.12, 24, 4)
		addCylinder(em, Vector3.new(0, -0.15, 0), 0.09, 0.55, 20, 6)
		addCylinder(em, Vector3.new(0, -0.55, 0), 0.12, 0.08, 16, 3)

		if shape == "nuke" then
			-- geothermal vents + antenna
			for i = 0, 7 do
				local th = (i / 8) * math.pi * 2
				local p = Vector3.new(math.cos(th) * r * 0.7, cy + r * 0.35, math.sin(th) * r * 0.7)
				addCylinder(em, p, r * 0.08, r * 0.2, 12, 4)
			end
			addCylinder(em, Vector3.new(0, cy + r * 0.85, 0), 0.04, 0.35, 10, 4)
			addSphere(em, Vector3.new(0, cy + r * 1.15, 0), 0.12, 16, 12)
			addSphere(em, Vector3.new(0, cy, 0), r * 0.35, 32, 24) -- inner core hint
		elseif shape == "event" then
			addCylinder(em, Vector3.new(0, cy - r * 0.85, 0), r * 0.65, 0.08, 32, 3) -- sink flange
		elseif spec.fuse ~= false then
			addHelix(em, Vector3.new(0, cy + r * 0.55, 0), 2.2, 0.55, 0.12, 0.035, 18)
			addSphere(em, Vector3.new(0.12, cy + r * 0.55 + 0.55, 0), 0.08, 12, 10)
		end

	elseif shape == "prototype" then
		-- angular lab chassis
		addBox(em, CFrame.new(0, cy, 0), Vector3.new(r * 1.6, r * 1.5, r * 1.6), 6)
		addBox(em, CFrame.new(0, cy + r * 0.55, 0), Vector3.new(r * 0.9, r * 0.4, r * 0.9), 4)
		addCylinder(em, Vector3.new(0.35, cy + 0.1, 0), 0.08, 0.4, 12, 4)
		addCylinder(em, Vector3.new(-0.35, cy + 0.1, 0), 0.08, 0.4, 12, 4)
		addSphere(em, Vector3.new(0, cy + r * 0.85, 0), 0.18, 20, 16)
		addCylinder(em, Vector3.new(0, -0.1, 0), 0.1, 0.5, 16, 5)
		for i = 0, 5 do
			local th = (i / 6) * math.pi * 2
			addBox(em, CFrame.new(math.cos(th) * r * 0.85, cy, math.sin(th) * r * 0.85), Vector3.new(0.12, r * 1.2, 0.12), 3)
		end

	elseif shape == "carpet" then
		addCylinder(em, Vector3.new(0, cy, 0), r * 1.1, r * 0.35, 48, 6)
		for ix = -1, 1 do
			for iz = -1, 1 do
				if not (ix == 0 and iz == 0) or true then
					addSphere(em, Vector3.new(ix * r * 0.45, cy + r * 0.35, iz * r * 0.45), r * 0.22, 20, 14)
				end
			end
		end
		addCylinder(em, Vector3.new(0, -0.05, 0), 0.1, 0.45, 16, 4)

	elseif shape == "spike" then -- tectonic
		addCylinder(em, Vector3.new(0, cy, 0), r * 0.35, r * 1.1, 28, 10)
		for i = 1, 5 do
			addTorus(em, Vector3.new(0, cy - r + i * r * 0.4, 0), r * (0.5 - i * 0.04), 0.04, 36, 10)
		end
		addSphere(em, Vector3.new(0, cy + r * 1.1, 0), r * 0.2, 20, 14)
		addCylinder(em, Vector3.new(0, -0.2, 0), 0.1, 0.4, 14, 4)

	elseif shape == "prism" then
		-- faceted crystal via stacked rotated boxes
		for i = 0, 5 do
			local ang = i * 30
			addBox(em, CFrame.new(0, cy + (i - 2.5) * r * 0.18, 0) * CFrame.Angles(0, math.rad(ang), math.rad(12)), Vector3.new(r * 1.1, r * 0.35, r * 1.1), 4)
		end
		addCylinder(em, Vector3.new(0, -0.1, 0), 0.1, 0.45, 14, 4)

	elseif shape == "wide" then -- sinkhole funnel approx
		for i = 0, 8 do
			local t = i / 8
			addCylinder(em, Vector3.new(0, cy + t * r * 0.8, 0), r * (1.1 - t * 0.7), 0.06, 36, 2)
		end
		addCylinder(em, Vector3.new(0, -0.05, 0), 0.1, 0.4, 14, 4)

	else
		addSphere(em, Vector3.new(0, cy, 0), r, 64, 40)
		addCylinder(em, Vector3.new(0, -0.15, 0), 0.09, 0.5, 18, 5)
	end

	local mp = AssetService:CreateMeshPartAsync(Content.fromObject(em))
	pcall(function() em:Destroy() end)
	mp.Name = "body_geom"
	mp.Anchored = false
	mp.CanCollide = false
	mp.Massless = true
	mp.Material = spec.material or Enum.Material.Metal
	mp.Color = spec.color or C3(90, 90, 100)
	if spec.neon then
		mp.Material = Enum.Material.Metal
	end
	-- fit size like existing bombs (~1.5 tall)
	local targetH = spec.height or 1.55
	local sz = mp.Size
	local scale = targetH / math.max(sz.Y, 0.01)
	mp.Size = sz * scale
	return mp
end

function M.install(name, meshPart)
	local root = game.ReplicatedStorage:FindFirstChild("ToolModels_50")
	if not root then return false, "no ToolModels_50" end
	local old = root:FindFirstChild(name)
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = root
	local normal = Instance.new("Model")
	normal.Name = "Normal"
	normal.Parent = folder
	local world = Instance.new("Model")
	world.Name = "world"
	world.Parent = normal
	local body = Instance.new("Model")
	body.Name = "body"
	body.Parent = world
	meshPart.Parent = body
	folder:SetAttribute("HQExplosive", true)
	folder:SetAttribute("BakedTris", true)
	return true
end

return M
