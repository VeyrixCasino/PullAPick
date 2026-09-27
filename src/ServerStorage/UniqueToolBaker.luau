-- HQ UniqueToolBaker: ~18-20k tris EditableMesh per tool (pickaxe/drill/explosive)
local AssetService = game:GetService("AssetService")
local Http = game:GetService("HttpService")
local M = {}

local TRI_TARGET = 18500
local TRI_HARD_MAX = 19800

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
	if s <= 0 then
		s = 1
	end
	return function()
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
end

local function tri(em, a, b, c, counter)
	if counter and counter.n >= TRI_HARD_MAX then
		return
	end
	em:AddTriangle(a, b, c)
	if counter then
		counter.n += 1
	end
end

local function addCylinder(em, c, r, hh, radN, hN, counter)
	radN = radN or 36
	hN = hN or 10
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
			local n = i + 1
			local m2 = ((i + 1) % radN) + 1
			tri(em, a[n], a[m2], b[m2], counter)
			tri(em, a[n], b[m2], b[n], counter)
		end
	end
	local topRing, botRing = rings[hN + 1], rings[1]
	for i = 0, radN - 1 do
		local n = i + 1
		local m2 = ((i + 1) % radN) + 1
		tri(em, top, topRing[n], topRing[m2], counter)
		tri(em, bot, botRing[m2], botRing[n], counter)
	end
end

local function addSphere(em, c, r, lonN, latN, counter)
	lonN = lonN or 40
	latN = latN or 28
	local rings = {}
	for lat = 0, latN do
		local phi = (lat / latN) * math.pi
		local y = c.Y + r * math.cos(phi)
		local rr = r * math.sin(phi)
		local row = {}
		for lon = 0, lonN - 1 do
			local th = (lon / lonN) * math.pi * 2
			row[lon + 1] = em:AddVertex(Vector3.new(c.X + rr * math.cos(th), y, c.Z + rr * math.sin(th)))
		end
		rings[lat + 1] = row
	end
	for lat = 0, latN - 1 do
		local a, b = rings[lat + 1], rings[lat + 2]
		for lon = 0, lonN - 1 do
			local n = lon + 1
			local m = ((lon + 1) % lonN) + 1
			if lat ~= 0 then
				tri(em, a[n], a[m], b[m], counter)
			end
			if lat ~= latN - 1 then
				tri(em, a[n], b[m], b[n], counter)
			end
		end
	end
end

local function addTorus(em, c, R, r, segR, segT, counter)
	segR = segR or 36
	segT = segT or 16
	local grid = {}
	for i = 0, segR - 1 do
		grid[i + 1] = {}
		local th = (i / segR) * math.pi * 2
		local cx = c.X + R * math.cos(th)
		local cz = c.Z + R * math.sin(th)
		for j = 0, segT - 1 do
			local ph = (j / segT) * math.pi * 2
			local x = cx + r * math.cos(ph) * math.cos(th)
			local y = c.Y + r * math.sin(ph)
			local z = cz + r * math.cos(ph) * math.sin(th)
			grid[i + 1][j + 1] = em:AddVertex(Vector3.new(x, y, z))
		end
	end
	for i = 0, segR - 1 do
		local i2 = (i + 1) % segR
		for j = 0, segT - 1 do
			local j2 = (j + 1) % segT
			local a = grid[i + 1][j + 1]
			local b = grid[i2 + 1][j + 1]
			local c2 = grid[i2 + 1][j2 + 1]
			local d = grid[i + 1][j2 + 1]
			tri(em, a, b, c2, counter)
			tri(em, a, c2, d, counter)
		end
	end
end

local function addBox(em, cf, size, seg, counter)
	seg = math.max(1, seg or 4)
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	-- 6 faces, each an (seg x seg) grid in local space
	local faces = {
		{ 3, hx, hy, hz }, -- +Z: x,y fixed z
		{ 3, hx, hy, -hz },
		{ 1, hx, hy, hz }, -- +X: y,z fixed x
		{ 1, -hx, hy, hz },
		{ 2, hx, hy, hz }, -- +Y: x,z fixed y
		{ 2, hx, -hy, hz },
	}
	-- simpler: walk parametric quads
	local function emitFace(axis, sign)
		local grid = {}
		for iy = 0, seg do
			grid[iy + 1] = {}
			for ix = 0, seg do
				local u = (ix / seg) * 2 - 1
				local v = (iy / seg) * 2 - 1
				local lp
				if axis == "z" then
					lp = Vector3.new(u * hx, v * hy, sign * hz)
				elseif axis == "x" then
					lp = Vector3.new(sign * hx, v * hy, u * hz)
				else
					lp = Vector3.new(u * hx, sign * hy, v * hz)
				end
				grid[iy + 1][ix + 1] = em:AddVertex(cf:PointToWorldSpace(lp))
			end
		end
		for iy = 0, seg - 1 do
			for ix = 0, seg - 1 do
				local a = grid[iy + 1][ix + 1]
				local b = grid[iy + 1][ix + 2]
				local c2 = grid[iy + 2][ix + 2]
				local d = grid[iy + 2][ix + 1]
				if sign > 0 then
					tri(em, a, b, c2, counter)
					tri(em, a, c2, d, counter)
				else
					tri(em, a, c2, b, counter)
					tri(em, a, d, c2, counter)
				end
			end
		end
	end
	emitFace("z", 1)
	emitFace("z", -1)
	emitFace("x", 1)
	emitFace("x", -1)
	emitFace("y", 1)
	emitFace("y", -1)
end

local function colorFromHash(h)
	return Color3.fromHSV((h % 1000) / 1000, 0.42 + (math.floor(h / 1000) % 40) / 100, 0.55 + (math.floor(h / 45000) % 35) / 100)
end

local function finishMesh(em, name, color, mat, counter)
	local mp = AssetService:CreateMeshPartAsync(Content.fromObject(em))
	mp.Name = "body_geom"
	mp.Color = color
	mp.Material = mat or Enum.Material.Metal
	mp.Anchored = true
	mp.CanCollide = false
	mp.Massless = true
	mp:SetAttribute("BakedTris", counter and counter.n or 0)
	mp:SetAttribute("ToolName", name)
	return mp
end

function M.buildPickaxe(name)
	local h = hash32(name .. "|pick|hq")
	local rand = rng(h)
	local em = AssetService:CreateEditableMesh()
	local counter = { n = 0 }
	local shaftLen = 1.35 + rand() * 0.45
	local shaftR = 0.055 + rand() * 0.025
	local headW = 0.55 + rand() * 0.55
	local headH = 0.16 + rand() * 0.14
	local headD = 0.12 + rand() * 0.1
	local style = math.floor(rand() * 5)

	addCylinder(em, Vector3.new(0, shaftLen * 0.4, 0), shaftR, shaftLen * 0.5, 28, 12, counter)
	addSphere(em, Vector3.new(0, -0.08, 0), shaftR * 1.7, 24, 18, counter)
	-- leather wraps
	local wraps = 3 + math.floor(rand() * 3)
	for i = 1, wraps do
		addTorus(em, Vector3.new(0, 0.2 + i * 0.14, 0), shaftR * 1.05, shaftR * 0.22, 24, 10, counter)
	end
	-- head block dense
	addBox(em, CFrame.new(0, shaftLen * 0.92, 0), Vector3.new(headW, headH, headD), 5, counter)
	if style == 0 then
		addBox(
			em,
			CFrame.new(headW * 0.42, shaftLen * 0.92, 0) * CFrame.Angles(0, 0, math.rad(-28)),
			Vector3.new(headW * 0.55, headH * 0.75, headD * 0.85),
			5,
			counter
		)
		addSphere(em, Vector3.new(-headW * 0.4, shaftLen * 0.92, 0), headH * 0.55, 24, 18, counter)
	elseif style == 1 then
		addCylinder(em, Vector3.new(0, shaftLen * 0.92, 0), headW * 0.28, headH * 0.55, 28, 8, counter)
		addBox(
			em,
			CFrame.new(headW * 0.4, shaftLen * 0.92, 0) * CFrame.Angles(0, 0, math.rad(18)),
			Vector3.new(headW * 0.5, headH * 0.5, headD),
			5,
			counter
		)
	elseif style == 2 then
		for i = -3, 3 do
			addBox(
				em,
				CFrame.new(i * headW * 0.12, shaftLen * 0.92 + math.abs(i) * 0.015, 0),
				Vector3.new(headW * 0.16, headH, headD),
				3,
				counter
			)
		end
	elseif style == 3 then
		addSphere(em, Vector3.new(0, shaftLen * 0.95, 0), headW * 0.28, 32, 24, counter)
		addBox(em, CFrame.new(headW * 0.4, shaftLen * 0.92, 0), Vector3.new(headW * 0.55, headH * 0.45, headD * 0.7), 5, counter)
	else
		addBox(
			em,
			CFrame.new(0, shaftLen * 0.9, 0) * CFrame.Angles(0, 0, math.rad(rand() * 24 - 12)),
			Vector3.new(headW, headH, headD),
			6,
			counter
		)
		addBox(em, CFrame.new(0, shaftLen * 1.02, 0), Vector3.new(headW * 0.28, headH * 1.35, headD * 0.55), 4, counter)
	end
	-- rivets
	local rivets = 8 + math.floor(rand() * 8)
	for i = 0, rivets - 1 do
		local t = i / rivets
		addSphere(
			em,
			Vector3.new((t - 0.5) * headW * 0.9, shaftLen * 0.92 + headH * 0.35, headD * 0.45),
			0.025 + rand() * 0.02,
			12,
			10,
			counter
		)
	end
	-- pad detail toward target without blowing the hard cap
	local guard = 0
	while counter.n < TRI_TARGET - 1200 and guard < 200 do
		guard += 1
		local y = 0.15 + rand() * shaftLen * 0.7
		addSphere(em, Vector3.new((rand() - 0.5) * shaftR * 0.3, y, (rand() - 0.5) * shaftR * 0.3), shaftR * 0.16, 12, 10, counter)
	end

	return finishMesh(em, name, colorFromHash(h), (rand() > 0.45) and Enum.Material.Metal or Enum.Material.Plastic, counter), counter.n
end

function M.buildDrill(name)
	local h = hash32(name .. "|drill|hq")
	local rand = rng(h)
	local em = AssetService:CreateEditableMesh()
	local counter = { n = 0 }
	local len = 1.5 + rand() * 0.55
	local r0 = 0.1 + rand() * 0.07
	local style = math.floor(rand() * 4)

	addCylinder(em, Vector3.new(0, len * 0.35, 0), r0, len * 0.38, 32, 12, counter)
	-- tip taper rings
	for i = 0, 8 do
		local t = i / 8
		addCylinder(em, Vector3.new(0, len * 0.72 + t * 0.45, 0), r0 * (1 - t * 0.88), 0.035, 24, 3, counter)
	end
	-- spiral flutes
	local flutes = 4 + math.floor(rand() * 3)
	for i = 0, flutes - 1 do
		local th0 = (i / flutes) * math.pi * 2
		for k = 0, 14 do
			local y = 0.15 + k * (len * 0.05)
			local ang = th0 + k * 0.38
			addSphere(em, Vector3.new(math.cos(ang) * r0 * 1.08, y, math.sin(ang) * r0 * 1.08), r0 * 0.18, 12, 10, counter)
		end
	end
	addTorus(em, Vector3.new(0, 0.08, 0), r0 * 1.15, r0 * 0.2, 28, 12, counter)
	if style >= 2 then
		addBox(em, CFrame.new(0, len * 0.22, 0), Vector3.new(r0 * 2.4, 0.18, r0 * 2.4), 4, counter)
	end
	if style == 3 then
		addSphere(em, Vector3.new(0, len * 0.55, 0), r0 * 0.85, 24, 18, counter)
	end
	local guard = 0
	while counter.n < TRI_TARGET - 1200 and guard < 200 do
		guard += 1
		local y = 0.2 + rand() * len * 0.6
		local ang = rand() * math.pi * 2
		addSphere(em, Vector3.new(math.cos(ang) * r0 * 0.9, y, math.sin(ang) * r0 * 0.9), r0 * 0.11, 10, 8, counter)
	end
	return finishMesh(em, name, colorFromHash(h), Enum.Material.Metal, counter), counter.n
end

function M.buildExplosive(name)
	local h = hash32(name .. "|bomb|hq")
	local rand = rng(h)
	local em = AssetService:CreateEditableMesh()
	local counter = { n = 0 }
	local r = 0.42 + rand() * 0.32
	local cy = 0.5 + rand() * 0.2
	local shape = math.floor(rand() * 6)

	if shape == 0 then
		addSphere(em, Vector3.new(0, cy, 0), r, 40, 30, counter)
	elseif shape == 1 then
		addCylinder(em, Vector3.new(0, cy, 0), r * 0.78, r * 0.75, 36, 12, counter)
		addSphere(em, Vector3.new(0, cy + r * 0.55, 0), r * 0.42, 28, 20, counter)
	elseif shape == 2 then
		addBox(em, CFrame.new(0, cy, 0), Vector3.new(r * 1.45, r * 1.35, r * 1.45), 6, counter)
		addCylinder(em, Vector3.new(0, cy + r * 0.75, 0), r * 0.32, 0.1, 24, 4, counter)
	elseif shape == 3 then
		for i = 0, 8 do
			local t = i / 8
			addCylinder(em, Vector3.new(0, cy - r * 0.5 + t * r * 1.1, 0), r * (1.0 - t * 0.55), 0.05, 32, 3, counter)
		end
	elseif shape == 4 then
		addSphere(em, Vector3.new(0, cy, 0), r * 0.9, 40, 28, counter)
		addTorus(em, Vector3.new(0, cy, 0), r * 0.95, r * 0.12, 36, 14, counter)
	else
		addCylinder(em, Vector3.new(0, cy, 0), r * 0.7, r * 0.9, 36, 14, counter)
		addSphere(em, Vector3.new(0, cy + r * 0.7, 0), r * 0.35, 24, 18, counter)
		addSphere(em, Vector3.new(0, cy - r * 0.55, 0), r * 0.28, 22, 16, counter)
	end
	-- bands + rivets + handle
	local bands = 2 + math.floor(rand() * 3)
	for i = 1, bands do
		addTorus(em, Vector3.new(0, cy + (i - bands * 0.5) * r * 0.28, 0), r * 0.92, r * 0.05, 36, 12, counter)
	end
	local rivets = 10 + math.floor(rand() * 8)
	for i = 0, rivets - 1 do
		local th = (i / rivets) * math.pi * 2
		addSphere(em, Vector3.new(math.cos(th) * r * 0.95, cy, math.sin(th) * r * 0.95), r * 0.055, 12, 10, counter)
	end
	addCylinder(em, Vector3.new(0, -0.05, 0), 0.085, 0.4, 24, 8, counter)
	if rand() > 0.25 then
		for i = 0, 18 do
			local t = i / 18
			local th = t * 4.5
			addSphere(
				em,
				Vector3.new(math.cos(th) * 0.1, cy + r * 0.55 + t * 0.55, math.sin(th) * 0.1),
				0.032,
				8,
				6,
				counter
			)
		end
		addSphere(em, Vector3.new(0.1, cy + r * 0.55 + 0.55, 0), 0.07, 14, 10, counter)
	end
	local guard = 0
	while counter.n < TRI_TARGET - 1200 and guard < 200 do
		guard += 1
		local th = rand() * math.pi * 2
		local ph = rand() * math.pi
		addSphere(
			em,
			Vector3.new(math.sin(ph) * math.cos(th) * r * 0.7, cy + math.cos(ph) * r * 0.5, math.sin(ph) * math.sin(th) * r * 0.7),
			r * 0.045,
			10,
			8,
			counter
		)
	end
	return finishMesh(em, name, colorFromHash(h), (rand() > 0.4) and Enum.Material.Metal or Enum.Material.Plastic, counter), counter.n
end

function M.install(name, family)
	local root = game.ReplicatedStorage:FindFirstChild("ToolModels_50")
	if not root then
		return false, "no ToolModels_50"
	end
	family = family or "pickaxe"
	local mp, tris
	if family == "drill" then
		mp, tris = M.buildDrill(name)
	elseif family == "explosive" then
		mp, tris = M.buildExplosive(name)
	else
		mp, tris = M.buildPickaxe(name)
		family = "pickaxe"
	end
	local old = root:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("UniqueTool", true)
	folder:SetAttribute("HQUnique", true)
	folder:SetAttribute("PrototypeFamily", family)
	folder:SetAttribute("BakedTris", tris or 0)
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
	mp.Parent = body
	return true, tris
end

function M.loadRenameList()
	local folder = game.ServerStorage:FindFirstChild("_ToolRenameMap")
	if not folder then
		return {}
	end
	local list = {}
	for _, sv in ipairs(folder:GetChildren()) do
		if sv:IsA("StringValue") and sv.Name:match("^c%d+") then
			local ok, slice = pcall(Http.JSONDecode, Http, sv.Value)
			if ok and type(slice) == "table" then
				for _, e in ipairs(slice) do
					list[#list + 1] = e
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.n < b.n
	end)
	return list
end

function M.installBatch(startAt, count)
	local list = M.loadRenameList()
	startAt = math.max(1, tonumber(startAt) or 1)
	count = math.max(1, tonumber(count) or 10)
	local last = math.min(#list, startAt + count - 1)
	local okN, failN, fails, triSum = 0, 0, {}, 0
	for i = startAt, last do
		local e = list[i]
		local ok, err = pcall(function()
			local success, tris = M.install(e.n, e.f)
			if not success then
				error(tris or "install failed")
			end
			triSum += tonumber(tris) or 0
		end)
		if ok then
			okN += 1
		else
			failN += 1
			fails[#fails + 1] = e.n .. ":" .. tostring(err)
		end
	end
	return {
		total = #list,
		from = startAt,
		to = last,
		ok = okN,
		fail = failN,
		fails = fails,
		avgTris = okN > 0 and math.floor(triSum / okN) or 0,
		done = last >= #list,
	}
end

function M.deleteTintSkins()
	local root = game.ReplicatedStorage.ToolModels_50
	local n = 0
	for _, c in ipairs(root:GetChildren()) do
		if c:GetAttribute("SkinnedExplosive") then
			c:Destroy()
			n += 1
		end
	end
	return n
end

function M.deleteOrphanOldFolders()
	local root = game.ReplicatedStorage.ToolModels_50
	local keep = { ["Gem-N-Eye"] = true }
	for _, e in ipairs(M.loadRenameList()) do
		keep[e.n] = true
	end
	local removed = 0
	for _, c in ipairs(root:GetChildren()) do
		if c:IsA("Folder") and not keep[c.Name] then
			c:Destroy()
			removed += 1
		end
	end
	return removed
end

return M
