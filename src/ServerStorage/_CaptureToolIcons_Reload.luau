-- Capture unique ToolModels_50 icons (Normal only). Green booth + ICON_POSE + 1.5s load.
local CaptureToolIcons = {}

local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Selection = game:GetService("Selection")
local AssetService = game:GetService("AssetService")
local CaptureService = game:GetService("CaptureService")
local ContentProvider = game:GetService("ContentProvider")
local Factory = require(RS:WaitForChild("ToolModelFactory"))

local ORIGIN = Vector3.new(0, 9200, 0)
local GREEN = Color3.fromRGB(0, 255, 0)
local INGEST = "http://127.0.0.1:8766/icon"

local ICON_POSE = {
	drill = CFrame.Angles(math.rad(90), math.rad(-90), 0),
	pickaxe = CFrame.Angles(0, 0, math.rad(90)),
	explosive = CFrame.identity,
}

local function wall(parent, pos, size)
	local p = Instance.new("Part")
	p.Name = "Green"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = GREEN
	p.Size = size
	p.CFrame = CFrame.new(pos)
	p.Parent = parent
	return p
end

function CaptureToolIcons.ensureBooth()
	local booth = workspace:FindFirstChild("IconBooth")
	if booth then
		booth:Destroy()
	end
	booth = Instance.new("Folder")
	booth.Name = "IconBooth"
	booth.Parent = workspace
	local s = 64
	local h = s / 2
	wall(booth, ORIGIN + Vector3.new(0, -h, 0), Vector3.new(s, 2, s))
	wall(booth, ORIGIN + Vector3.new(0, h, 0), Vector3.new(s, 2, s))
	wall(booth, ORIGIN + Vector3.new(-h, 0, 0), Vector3.new(2, s, s))
	wall(booth, ORIGIN + Vector3.new(h, 0, 0), Vector3.new(2, s, s))
	wall(booth, ORIGIN + Vector3.new(0, 0, -h), Vector3.new(s, s, 2))
	wall(booth, ORIGIN + Vector3.new(0, 0, h), Vector3.new(s, s, 2))
	return booth
end

local function upright(model, family)
	family = family or "pickaxe"
	local pose = ICON_POSE[family] or ICON_POSE.pickaxe
	model:PivotTo(CFrame.new(ORIGIN) * pose)
end

local function frameCam(cam, model)
	-- Pull back + slight downward look so pick/drill tops are never clipped.
	local cf, size = model:GetBoundingBox()
	local reach = math.max(size.X, size.Y, size.Z, 0.6)
	local pad = reach * 5.4 + 2.8
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = 42
	local lookAt = cf.Position + Vector3.new(0, size.Y * 0.05, 0)
	local camPos = lookAt + Vector3.new(0, reach * 0.35, pad)
	cam.CFrame = CFrame.new(camPos, lookAt)
end

local function waitForRender(model)
	local assets = { model }
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("MeshPart") or d:IsA("SpecialMesh") then
			assets[#assets + 1] = d
		end
	end
	pcall(function()
		ContentProvider:PreloadAsync(assets)
	end)
	task.wait(1.5)
end

local function capturePixels()
	local got
	CaptureService:CaptureScreenshot(function(id)
		got = id
	end)
	local t0 = os.clock()
	while not got and os.clock() - t0 < 4 do
		task.wait()
	end
	if not got then
		return nil, "no capture"
	end
	local img = AssetService:CreateEditableImageAsync(got)
	local size = img.Size
	local buf = img:ReadPixelsBuffer(Vector2.zero, size)
	img:Destroy()
	return buf, size
end

local function downsampleSquare(src, sw, sh, tw)
	local side = math.min(sw, sh)
	local x0 = math.floor((sw - side) / 2)
	local y0 = math.floor((sh - side) / 2)
	local out = buffer.create(tw * tw * 4)
	for y = 0, tw - 1 do
		local sy = y0 + math.clamp(math.floor((y + 0.5) * side / tw), 0, sh - 1)
		for x = 0, tw - 1 do
			local sx = x0 + math.clamp(math.floor((x + 0.5) * side / tw), 0, sw - 1)
			local si = (sy * sw + sx) * 4
			local di = (y * tw + x) * 4
			buffer.writeu8(out, di, buffer.readu8(src, si))
			buffer.writeu8(out, di + 1, buffer.readu8(src, si + 1))
			buffer.writeu8(out, di + 2, buffer.readu8(src, si + 2))
			buffer.writeu8(out, di + 3, buffer.readu8(src, si + 3))
		end
	end
	return out
end

local function postIcon(name, rgba)
	local url = INGEST .. "?name=" .. Http:UrlEncode(name) .. "&w=256&h=256"
	local res = Http:RequestAsync({
		Url = url,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/octet-stream" },
		Body = buffer.tostring(rgba),
	})
	return res.StatusCode, res.Body
end

local function makeModel(job)
	local name = job.named or job.name
	local family = job.family or "pickaxe"
	if name then
		-- Prefer raw folder clone for UniqueTool (skip fitNamedModel distortion)
		local root = RS:FindFirstChild("ToolModels_50")
		local folder = root and root:FindFirstChild(name)
		if folder and folder:FindFirstChild("Normal") then
			local model = folder.Normal:Clone()
			model.Name = name
			local wrap = model:FindFirstChild("world")
			if wrap then
				for _, d in ipairs(wrap:GetDescendants()) do
					if d:IsA("BasePart") then
						d.Parent = model
					end
				end
				wrap:Destroy()
			end
			-- Invisible grip handle if missing
			if not model:FindFirstChild("Handle") then
				local h = Instance.new("Part")
				h.Name = "Handle"
				h.Size = Vector3.new(0.2, 1, 0.2)
				h.Transparency = 1
				h.Anchored = true
				h.CanCollide = false
				h.CFrame = model:GetBoundingBox()
				h.Parent = model
				model.PrimaryPart = h
			end
			return model
		end
		local ok, model = pcall(Factory.fromNamed, name, "Normal", family)
		if ok and model then
			return model
		end
	end
	return nil
end

function CaptureToolIcons.jobs()
	local out = {}
	local root = RS:FindFirstChild("ToolModels_50")
	if root then
		for _, folder in ipairs(root:GetChildren()) do
			if folder:IsA("Folder") and folder:FindFirstChild("Normal") then
				local fam = folder:GetAttribute("PrototypeFamily") or "pickaxe"
				if fam ~= "drill" and fam ~= "explosive" and fam ~= "pickaxe" then
					fam = "pickaxe"
				end
				out[#out + 1] = { name = folder.Name, named = folder.Name, family = fam }
			end
		end
	end
	table.sort(out, function(a, b)
		return a.name < b.name
	end)
	return out
end

local function prepLighting()
	local parked = {}
	for _, ch in ipairs(Lighting:GetChildren()) do
		if ch:IsA("Atmosphere") or ch:IsA("BloomEffect") or ch:IsA("SunRaysEffect")
			or ch:IsA("ColorCorrectionEffect") or ch:IsA("DepthOfFieldEffect") then
			parked[#parked + 1] = { inst = ch, parent = ch.Parent }
			ch.Parent = nil
		end
	end
	local saved = {
		ambient = Lighting.Ambient,
		outdoor = Lighting.OutdoorAmbient,
		bright = Lighting.Brightness,
		shadows = Lighting.GlobalShadows,
		exposure = Lighting.ExposureCompensation,
	}
	Lighting.Ambient = Color3.fromRGB(210, 214, 224)
	Lighting.OutdoorAmbient = Color3.fromRGB(210, 214, 224)
	Lighting.Brightness = 2.2
	Lighting.GlobalShadows = false
	Lighting.ExposureCompensation = 0.15
	return saved, parked
end

local function restoreLighting(saved, parked)
	Lighting.Ambient = saved.ambient
	Lighting.OutdoorAmbient = saved.outdoor
	Lighting.Brightness = saved.bright
	Lighting.GlobalShadows = saved.shadows
	Lighting.ExposureCompensation = saved.exposure
	for _, rec in ipairs(parked) do
		rec.inst.Parent = rec.parent
	end
end

function CaptureToolIcons.runJob(job)
	Http.HttpEnabled = true
	local booth = CaptureToolIcons.ensureBooth()
	local cam = workspace.CurrentCamera
	local model = makeModel(job)
	if not model then
		return { ok = 0, fail = 1, fails = { (job.name or "?") .. ":no-model" } }
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CastShadow = false
		elseif d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Beam") or d:IsA("Trail") then
			d:Destroy()
		end
	end
	model.Parent = booth
	upright(model, job.family or "pickaxe")
	frameCam(cam, model)
	waitForRender(model)
	local buf, size = capturePixels()
	model:Destroy()
	if not buf then
		return { ok = 0, fail = 1, fails = { (job.name or "?") .. ":capture" } }
	end
	local small = downsampleSquare(buf, size.X, size.Y, 256)
	local pok, codeOrErr = pcall(postIcon, job.name, small)
	if pok and tonumber(codeOrErr) == 200 then
		return { ok = 1, fail = 0, fails = {} }
	end
	return { ok = 0, fail = 1, fails = { (job.name or "?") .. ":" .. tostring(codeOrErr) } }
end

function CaptureToolIcons.run(startAt, count)
	Http.HttpEnabled = true
	pcall(function()
		Selection:Set({})
	end)
	local jobs = CaptureToolIcons.jobs()
	startAt = math.max(1, tonumber(startAt) or 1)
	count = math.max(1, tonumber(count) or 15)
	local last = math.min(#jobs, startAt + count - 1)
	local booth = CaptureToolIcons.ensureBooth()
	local cam = workspace.CurrentCamera
	local savedCam = { cf = cam.CFrame, fov = cam.FieldOfView, kind = cam.CameraType }
	local saved, parked = prepLighting()
	local okN, failN, fails = 0, 0, {}
	for i = startAt, last do
		local stop = game.ServerStorage:FindFirstChild("_IconStop")
		if stop and stop.Value == true then
			fails[#fails + 1] = "STOPPED"
			break
		end
		local r = CaptureToolIcons.runJob(jobs[i])
		if r.ok > 0 then
			okN += 1
		else
			failN += 1
			for _, f in ipairs(r.fails or {}) do
				fails[#fails + 1] = f
			end
		end
	end
	cam.CameraType = savedCam.kind
	cam.FieldOfView = savedCam.fov
	cam.CFrame = savedCam.cf
	restoreLighting(saved, parked)
	return {
		total = #jobs,
		from = startAt,
		to = last,
		ok = okN,
		fail = failN,
		fails = fails,
		done = last >= #jobs,
	}
end

function CaptureToolIcons.runQueue(queue, startAt, count)
	startAt = math.max(1, tonumber(startAt) or 1)
	count = math.max(1, tonumber(count) or 25)
	local last = math.min(#queue, startAt + count - 1)
	local okN, failN, fails = 0, 0, {}
	CaptureToolIcons.ensureBooth()
	local cam = workspace.CurrentCamera
	local savedCam = { cf = cam.CFrame, fov = cam.FieldOfView, kind = cam.CameraType }
	local saved, parked = prepLighting()
	for i = startAt, last do
		local stop = game.ServerStorage:FindFirstChild("_IconStop")
		if stop and stop.Value == true then
			fails[#fails + 1] = "STOPPED"
			break
		end
		local job = queue[i]
		job.named = job.named or job.name
		local r = CaptureToolIcons.runJob(job)
		if r.ok > 0 then
			okN += 1
		else
			failN += 1
			for _, f in ipairs(r.fails or {}) do
				fails[#fails + 1] = f
			end
		end
	end
	cam.CameraType = savedCam.kind
	cam.FieldOfView = savedCam.fov
	cam.CFrame = savedCam.cf
	restoreLighting(saved, parked)
	return { total = #queue, from = startAt, to = last, ok = okN, fail = failN, fails = fails, done = last >= #queue }
end

function CaptureToolIcons.cleanup()
	local booth = workspace:FindFirstChild("IconBooth")
	if booth then
		booth:Destroy()
	end
end

return CaptureToolIcons
