-- Procedural bake of all-tool-meshes kit (17 tools × 6 bodies) into RS.ToolKitMeshes
local AssetService = game:GetService("AssetService")
local RS = game:GetService("ReplicatedStorage")

local SOCKET_Z = 0.70
local SOCKET_R = 0.12

local BODIES = {
	{ "FieldScrap", Color3.fromRGB(115, 82, 46) },
	{ "TapedField", Color3.fromRGB(102, 77, 41) },
	{ "Riveted", Color3.fromRGB(128, 128, 122) },
	{ "MilSpec", Color3.fromRGB(89, 97, 92) },
	{ "Alloy", Color3.fromRGB(71, 77, 84) },
	{ "Composite", Color3.fromRGB(31, 31, 33) },
}

local Mesh = {}
Mesh.__index = Mesh

function Mesh.new(name)
	return setmetatable({ name = name, verts = {}, faces = {} }, Mesh)
end

function Mesh:add_v(x, y, z)
	table.insert(self.verts, Vector3.new(x, y, z))
	return #self.verts
end

function Mesh:tri(a, b, c)
	table.insert(self.faces, a)
	table.insert(self.faces, b)
	table.insert(self.faces, c)
end

function Mesh:quad(a, b, c, d)
	self:tri(a, b, c)
	self:tri(a, c, d)
end

function Mesh:merge(other)
	local base = #self.verts
	for _, v in ipairs(other.verts) do
		table.insert(self.verts, v)
	end
	for i = 1, #other.faces do
		table.insert(self.faces, other.faces[i] + base)
	end
end

local function box(m, cx, cy, cz, sx, sy, sz)
	local x0, x1 = cx - sx / 2, cx + sx / 2
	local y0, y1 = cy - sy / 2, cy + sy / 2
	local z0, z1 = cz - sz / 2, cz + sz / 2
	local v = {
		m:add_v(x0, y0, z0), m:add_v(x1, y0, z0), m:add_v(x1, y1, z0), m:add_v(x0, y1, z0),
		m:add_v(x0, y0, z1), m:add_v(x1, y0, z1), m:add_v(x1, y1, z1), m:add_v(x0, y1, z1),
	}
	m:quad(v[1], v[2], v[3], v[4])
	m:quad(v[5], v[8], v[7], v[6])
	m:quad(v[1], v[5], v[6], v[2])
	m:quad(v[2], v[6], v[7], v[3])
	m:quad(v[3], v[7], v[8], v[4])
	m:quad(v[4], v[8], v[5], v[1])
end

local function cyl(m, cx, cy, cz, r, h, segs, axis)
	segs = segs or 12
	axis = axis or "y"
	local top, bot = {}, {}
	for i = 0, segs - 1 do
		local a = 2 * math.pi * i / segs
		local c, s = math.cos(a) * r, math.sin(a) * r
		if axis == "y" then
			bot[i + 1] = m:add_v(cx + c, cy - h / 2, cz + s)
			top[i + 1] = m:add_v(cx + c, cy + h / 2, cz + s)
		elseif axis == "z" then
			bot[i + 1] = m:add_v(cx + c, cy + s, cz - h / 2)
			top[i + 1] = m:add_v(cx + c, cy + s, cz + h / 2)
		else
			bot[i + 1] = m:add_v(cx - h / 2, cy + c, cz + s)
			top[i + 1] = m:add_v(cx + h / 2, cy + c, cz + s)
		end
	end
	local tc, bc
	if axis == "y" then
		tc = m:add_v(cx, cy + h / 2, cz)
		bc = m:add_v(cx, cy - h / 2, cz)
	elseif axis == "z" then
		tc = m:add_v(cx, cy, cz + h / 2)
		bc = m:add_v(cx, cy, cz - h / 2)
	else
		tc = m:add_v(cx + h / 2, cy, cz)
		bc = m:add_v(cx - h / 2, cy, cz)
	end
	for i = 0, segs - 1 do
		local j = (i + 1) % segs
		m:quad(bot[i + 1], bot[j + 1], top[j + 1], top[i + 1])
		m:tri(top[i + 1], top[j + 1], tc)
		m:tri(bot[j + 1], bot[i + 1], bc)
	end
end

local function torus_ring(m, cx, cy, cz, R, r, segs, pipes, axis)
	segs = segs or 16
	pipes = pipes or 8
	axis = axis or "z"
	for i = 0, segs - 1 do
		local a0, a1 = 2 * math.pi * i / segs, 2 * math.pi * (i + 1) / segs
		for j = 0, pipes - 1 do
			local b0, b1 = 2 * math.pi * j / pipes, 2 * math.pi * (j + 1) / pipes
			local function pt(a, b)
				if axis == "z" then
					return m:add_v(cx + (R + r * math.cos(b)) * math.cos(a), cy + (R + r * math.cos(b)) * math.sin(a), cz + r * math.sin(b))
				elseif axis == "y" then
					return m:add_v(cx + (R + r * math.cos(b)) * math.cos(a), cy + r * math.sin(b), cz + (R + r * math.cos(b)) * math.sin(a))
				else
					return m:add_v(cx + r * math.sin(b), cy + (R + r * math.cos(b)) * math.cos(a), cz + (R + r * math.cos(b)) * math.sin(a))
				end
			end
			local p00, p01, p10, p11 = pt(a0, b0), pt(a0, b1), pt(a1, b0), pt(a1, b1)
			m:quad(p00, p10, p11, p01)
		end
	end
end

local function socket_marker(m)
	torus_ring(m, 0, 0, SOCKET_Z, SOCKET_R, 0.008, 16, 6, "z")
end

local function haft(m, tier, length, radius)
	length = length or 0.70
	radius = radius or 0.045
	cyl(m, 0, 0, length / 2, radius, length, 10, "z")
	cyl(m, 0, 0, 0.08, radius * 1.25, 0.12, 10, "z")
	if tier >= 1 then
		for _, z in ipairs({ 0.18, 0.28, 0.38 }) do
			cyl(m, 0, 0, z, radius * 1.15, 0.04, 10, "z")
		end
	end
	if tier >= 2 then
		cyl(m, 0, 0, 0.02, radius * 1.35, 0.05, 10, "z")
		cyl(m, 0, 0, length - 0.04, radius * 1.35, 0.05, 10, "z")
	end
	if tier >= 4 then
		box(m, 0, 0, length * 0.45, radius * 0.5, radius * 2.2, length * 0.35)
	end
	if tier >= 5 then
		box(m, 0, 0, 0.01, radius * 2.4, radius * 2.4, 0.03)
	end
end

local function tip_pickaxe()
	local m = Mesh.new("Tip")
	box(m, 0, 0, 0.08, 0.08, 0.08, 0.22)
	box(m, 0, 0, 0.18, 0.55, 0.07, 0.10)
	for _, x in ipairs({ -0.28, 0.28 }) do
		box(m, x, 0, 0.18, 0.12, 0.06, 0.08)
	end
	return m
end

local function tip_sledgehammer()
	local m = Mesh.new("Tip")
	box(m, 0, 0, 0.14, 0.28, 0.22, 0.32)
	return m
end

local function tip_chisel()
	local m = Mesh.new("Tip")
	box(m, 0, 0, 0.10, 0.14, 0.04, 0.22)
	box(m, 0, 0, 0.22, 0.18, 0.02, 0.06)
	return m
end

local function tip_sledge()
	local m = Mesh.new("Tip")
	box(m, 0, 0, 0.18, 0.40, 0.28, 0.40)
	box(m, 0, 0, 0.02, 0.16, 0.16, 0.08)
	return m
end

local function tip_icepick()
	local m = Mesh.new("Tip")
	box(m, 0, 0, 0.06, 0.06, 0.06, 0.14)
	box(m, 0.16, 0, 0.10, 0.36, 0.05, 0.08)
	box(m, 0.32, 0, 0.04, 0.10, 0.04, 0.10)
	return m
end

local function tip_trenchshovel()
	local m = Mesh.new("Tip")
	box(m, 0, 0, 0.16, 0.28, 0.04, 0.36)
	box(m, 0, 0, 0.34, 0.18, 0.03, 0.08)
	return m
end

local function swing_body(tier)
	local m = Mesh.new("Body")
	haft(m, tier, SOCKET_Z, 0.045)
	socket_marker(m)
	return m
end

local function drill_body(tier, wide)
	local m = Mesh.new("Body")
	local r = if wide then 0.22 else 0.16
	cyl(m, 0, 0, 0.28, r, 0.48, 12, "z")
	box(m, 0, -0.22, 0.18, 0.10, 0.28, 0.18)
	box(m, 0, -0.10, 0.22, 0.08, 0.06, 0.10)
	if tier >= 1 then
		cyl(m, 0, 0, 0.10, r * 1.05, 0.08, 12, "z")
	end
	if tier >= 2 then
		for _, z in ipairs({ 0.20, 0.36 }) do
			cyl(m, 0, 0, z, r * 1.08, 0.03, 12, "z")
		end
	end
	if tier >= 5 then
		box(m, 0, 0.14, 0.28, 0.06, 0.04, 0.30)
	end
	socket_marker(m)
	return m
end

local function tip_drill()
	local m = Mesh.new("Tip")
	for _, pair in ipairs({ { 0.06, 0.07 }, { 0.16, 0.06 }, { 0.26, 0.05 }, { 0.36, 0.04 } }) do
		cyl(m, 0, 0, pair[1], pair[2], 0.10, 10, "z")
		box(m, 0.04, 0, pair[1], 0.03, 0.02, 0.08)
	end
	return m
end

local function tip_auger()
	local m = Mesh.new("Tip")
	for i = 0, 5 do
		local z = 0.06 + i * 0.08
		cyl(m, 0, 0, z, 0.08 - i * 0.008, 0.07, 10, "z")
		local a = i * 0.9
		box(m, math.cos(a) * 0.07, math.sin(a) * 0.07, z, 0.10, 0.03, 0.05)
	end
	return m
end

local function tip_bitarray()
	local m = Mesh.new("Tip")
	for ix = 0, 2 do
		for iy = 0, 2 do
			local x, y = (ix - 1) * 0.12, (iy - 1) * 0.12
			cyl(m, x, y, 0.16, 0.035, 0.28, 8, "z")
		end
	end
	box(m, 0, 0, 0.04, 0.38, 0.38, 0.06)
	return m
end

local function tip_bore()
	local m = Mesh.new("Tip")
	cyl(m, 0, 0, 0.14, 0.28, 0.22, 16, "z")
	for i = 0, 7 do
		local a = i * math.pi / 4
		box(m, math.cos(a) * 0.22, math.sin(a) * 0.22, 0.20, 0.08, 0.04, 0.12)
	end
	return m
end

local function tip_frack()
	local m = Mesh.new("Tip")
	cyl(m, 0, 0, 0.12, 0.09, 0.18, 10, "z")
	cyl(m, 0, 0, 0.28, 0.05, 0.20, 8, "z")
	box(m, 0, 0, 0.40, 0.04, 0.04, 0.10)
	box(m, 0.10, 0, 0.10, 0.08, 0.06, 0.10)
	return m
end

local function breacher_body(tier)
	local m = Mesh.new("Body")
	box(m, 0, 0, 0.35, 1.15, 0.62, 0.70)
	box(m, 0, 0.28, 0.35, 1.18, 0.08, 0.72)
	box(m, 0, -0.28, 0.35, 1.18, 0.08, 0.72)
	box(m, 0, 0.34, 0.32, 0.42, 0.04, 0.50)
	for row = 0, 3 do
		for col = 0, 2 do
			box(m, -0.12 + col * 0.12, 0.37, 0.48 - row * 0.10, 0.08, 0.03, 0.07)
		end
	end
	box(m, 0, 0.37, 0.55, 0.36, 0.025, 0.06)
	for i = 0, 9 do
		cyl(m, -0.22 + i * 0.048, 0.38, 0.62, 0.012, 0.02, 6, "y")
	end
	for _, p in ipairs({ { -0.18, 0.20 }, { 0.0, 0.28 }, { 0.18, 0.20 } }) do
		cyl(m, p[1], 0.40, p[2], 0.025, 0.35, 8, "y")
	end
	box(m, -0.45, 0.38, 0.55, 0.08, 0.06, 0.10)
	if tier >= 2 then
		for _, x in ipairs({ -0.5, 0.5 }) do
			for _, z in ipairs({ 0.1, 0.55 }) do
				cyl(m, x, 0.0, z, 0.03, 0.66, 6, "y")
			end
		end
	end
	if tier >= 5 then
		box(m, 0, 0.0, 0.02, 1.18, 0.66, 0.04)
	end
	socket_marker(m)
	return m
end

local function tip_breacher()
	local m = Mesh.new("Tip")
	for i, dx in ipairs({ -0.18, 0.0, 0.18 }) do
		cyl(m, dx, 0.55, 0.22 + (i - 1) * 0.02, 0.035, 0.08, 8, "y")
	end
	for i = 0, 9 do
		cyl(m, -0.22 + i * 0.048, 0.39, 0.62, 0.014, 0.015, 6, "y")
	end
	return m
end

local function precision_body(tier)
	local m = Mesh.new("Body")
	for _, p in ipairs({ { -0.12, 0.06 }, { 0.12, 0.06 }, { 0.0, -0.10 } }) do
		cyl(m, p[1], p[2], 0.32, 0.09, 0.55, 12, "z")
	end
	box(m, 0, 0, 0.18, 0.42, 0.32, 0.06)
	box(m, 0, 0, 0.48, 0.42, 0.32, 0.06)
	box(m, 0, 0.18, 0.35, 0.18, 0.04, 0.22)
	box(m, -0.04, 0.21, 0.38, 0.05, 0.03, 0.05)
	if tier >= 2 then
		box(m, 0, -0.18, 0.35, 0.40, 0.03, 0.50)
	end
	socket_marker(m)
	return m
end

local function tip_precision()
	local m = Mesh.new("Tip")
	for _, p in ipairs({ { -0.12, 0.06 }, { 0.12, 0.06 }, { 0.0, -0.10 } }) do
		cyl(m, p[1], p[2], 0.58, 0.092, 0.06, 10, "z")
		cyl(m, p[1], p[2], 0.62, 0.02, 0.10, 6, "z")
	end
	cyl(m, 0, 0, SOCKET_Z, 0.04, 0.08, 8, "z")
	return m
end

local function cluster_body(tier)
	local m = Mesh.new("Body")
	for i = 0, 5 do
		local a = i * math.pi / 3
		cyl(m, math.cos(a) * 0.22, math.sin(a) * 0.22, 0.35, 0.11, 0.65, 10, "z")
	end
	box(m, 0, 0, 0.15, 0.70, 0.70, 0.08)
	box(m, 0, 0, 0.55, 0.70, 0.70, 0.08)
	box(m, 0, 0.38, 0.35, 0.36, 0.05, 0.40)
	box(m, -0.08, 0.42, 0.40, 0.08, 0.04, 0.08)
	box(m, 0.08, 0.42, 0.40, 0.16, 0.03, 0.10)
	box(m, -0.38, 0, 0.35, 0.08, 0.45, 0.50)
	if tier >= 4 then
		box(m, 0.38, 0, 0.35, 0.06, 0.50, 0.55)
	end
	socket_marker(m)
	return m
end

local function tip_cluster()
	local m = Mesh.new("Tip")
	for _, z in ipairs({ 0.18, 0.30, 0.42, 0.54 }) do
		for _, y in ipairs({ -0.12, 0.0, 0.12 }) do
			cyl(m, -0.42, y, z, 0.035, 0.08, 8, "x")
		end
	end
	return m
end

local function quickcharge_body(tier)
	local m = Mesh.new("Body")
	cyl(m, 0, 0, 0.28, 0.18, 0.50, 14, "z")
	cyl(m, 0, 0, 0.55, 0.16, 0.08, 12, "z")
	torus_ring(m, 0.12, 0.12, 0.58, 0.06, 0.012, 12, 6, "z")
	if tier >= 3 then
		box(m, 0, 0, 0.28, 0.38, 0.06, 0.35)
	end
	socket_marker(m)
	return m
end

local function tip_quickcharge()
	local m = Mesh.new("Tip")
	torus_ring(m, 0, 0, 0.28, 0.185, 0.035, 16, 8, "z")
	return m
end

local function grenade_body(tier)
	local m = Mesh.new("Body")
	cyl(m, 0, 0, 0.28, 0.22, 0.42, 12, "z")
	for _, z in ipairs({ 0.14, 0.22, 0.30, 0.38, 0.46 }) do
		cyl(m, 0, 0, z, 0.235, 0.03, 12, "z")
	end
	box(m, 0.18, 0, 0.48, 0.06, 0.16, 0.28)
	cyl(m, 0.22, 0.12, 0.58, 0.02, 0.14, 6, "x")
	if tier >= 2 then
		box(m, 0, 0, 0.08, 0.30, 0.30, 0.06)
	end
	socket_marker(m)
	return m
end

local function tip_grenade()
	local m = Mesh.new("Tip")
	cyl(m, 0, 0, 0.06, 0.16, 0.05, 12, "z")
	return m
end

local function proximity_body(tier)
	local m = Mesh.new("Body")
	cyl(m, 0, 0, 0.12, 0.42, 0.16, 16, "y")
	cyl(m, 0, 0.10, 0.12, 0.38, 0.06, 16, "y")
	for _, a in ipairs({ 0, 2.1, 4.2 }) do
		cyl(m, math.cos(a) * 0.28, -0.12, math.sin(a) * 0.28, 0.03, 0.14, 6, "y")
	end
	if tier >= 3 then
		box(m, 0, 0.02, 0.12, 0.70, 0.04, 0.70)
	end
	socket_marker(m)
	return m
end

local function tip_proximity()
	local m = Mesh.new("Tip")
	cyl(m, 0, 0.16, 0.12, 0.14, 0.10, 12, "y")
	torus_ring(m, 0, 0.14, 0.12, 0.20, 0.02, 16, 6, "y")
	return m
end

local TOOLS = {
	{ "Pickaxe", "Swing", swing_body, tip_pickaxe },
	{ "Sledgehammer", "Swing", swing_body, tip_sledgehammer },
	{ "Chisel", "Swing", swing_body, tip_chisel },
	{ "Sledge", "Swing", swing_body, tip_sledge },
	{ "IcePick", "Swing", swing_body, tip_icepick },
	{ "TrenchShovel", "Swing", swing_body, tip_trenchshovel },
	{ "Drill", "Drill", function(t) return drill_body(t, false) end, tip_drill },
	{ "Auger", "Drill", function(t) return drill_body(t, false) end, tip_auger },
	{ "BitArrayCutter", "Drill", function(t) return drill_body(t, true) end, tip_bitarray },
	{ "Bore", "Drill", function(t) return drill_body(t, true) end, tip_bore },
	{ "Frack", "Drill", function(t) return drill_body(t, false) end, tip_frack },
	{ "Breacher", "Explosive", breacher_body, tip_breacher },
	{ "Precision", "Explosive", precision_body, tip_precision },
	{ "Cluster", "Explosive", cluster_body, tip_cluster },
	{ "Quickcharge", "Explosive", quickcharge_body, tip_quickcharge },
	{ "Grenade", "Explosive", grenade_body, tip_grenade },
	{ "Proximity", "Explosive", proximity_body, tip_proximity },
}

local function ensure(parent, className, name)
	local x = parent:FindFirstChild(name)
	if x then
		return x
	end
	x = Instance.new(className)
	x.Name = name
	x.Parent = parent
	return x
end

local function bakeMesh(meshData, color)
	local em = AssetService:CreateEditableMesh()
	local vids = table.create(#meshData.verts)
	for i, v in ipairs(meshData.verts) do
		vids[i] = em:AddVertex(v)
	end
	for i = 1, #meshData.faces, 3 do
		em:AddTriangle(vids[meshData.faces[i]], vids[meshData.faces[i + 1]], vids[meshData.faces[i + 2]])
	end
	local mp = AssetService:CreateMeshPartAsync(Content.fromObject(em))
	mp.Anchored = true
	mp.CanCollide = false
	mp.Massless = true
	mp.Color = color
	mp.Material = Enum.Material.Metal
	_G.ToolKitEM = _G.ToolKitEM or {}
	return mp, em
end

local M = {}

function M.run(startIndex, endIndex)
	startIndex = startIndex or 1
	endIndex = endIndex or (#TOOLS * #BODIES)
	local root = ensure(RS, "Folder", "ToolKitMeshes")
	local smoke = root:FindFirstChild("_Smoke")
	if smoke then
		smoke:Destroy()
	end
	local done = {}
	local idx = 0
	for _, toolDef in ipairs(TOOLS) do
		local tname, family, bodyFn, tipFn = toolDef[1], toolDef[2], toolDef[3], toolDef[4]
		local tip = tipFn()
		for tier = 0, #BODIES - 1 do
			idx += 1
			if idx >= startIndex and idx <= endIndex then
				local bname = BODIES[tier + 1][1]
				local color = BODIES[tier + 1][2]
				local body = bodyFn(tier)
				local assembled = Mesh.new(tname .. "_" .. bname)
				assembled:merge(body)
				assembled:merge(tip)
				local fam = ensure(root, "Folder", family)
				local tool = ensure(fam, "Folder", tname)
				local old = tool:FindFirstChild(bname)
				if old then
					old:Destroy()
				end
				local mp, em = bakeMesh(assembled, color)
				mp.Name = bname
				mp:SetAttribute("ToolType", tname)
				mp:SetAttribute("Family", family)
				mp:SetAttribute("BodyTier", tier)
				mp:SetAttribute("Tris", #assembled.faces // 3)
				mp.Parent = tool
				_G.ToolKitEM[family .. "/" .. tname .. "/" .. bname] = em
				table.insert(done, tname .. "_" .. bname)
			end
		end
	end
	return table.concat(done, ",") .. " | totalIdx=" .. tostring(idx)
end

return M