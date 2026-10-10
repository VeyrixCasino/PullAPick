--[[
	MineProcFx -- what a proc looks and sounds like, on the client.

	Owner, 2026-10-10: Tidal Wave "needs a little sfx ... on top of an
	animation (while your at it a blast and zap and whatever else we got needs
	an animation too)". Before this a proc was a floating word and nothing
	else, so a proc that chipped blocks without breaking them read as a proc
	that did nothing. Candy rule: what pays out always moves.

	The server already sends one "loot" event per proc hit, with the block's
	position (Dig.procsAt in MineServer): BLAST once, TIDAL WAVE once, ZAP once
	per hop, SHATTER once per shatter (up to 3 in a chain), QUAKE when a block
	starts shaking. This
	turns each into an animation and a sound. It draws nothing the server did
	not report, so the picture never promises damage that did not land.

	MineProcFx.play(text, pos) -> true when it knew the proc.
]]

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local M = {}

M.BLOCK = 5 -- one mine block, in studs

local NEON = Enum.Material.Neon
local folder
local function fxFolder()
	if not (folder and folder.Parent) then
		folder = workspace:FindFirstChild("MineProcFx")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "MineProcFx"
			folder.Parent = workspace
		end
	end
	return folder
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = NEON
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = fxFolder()
	return p
end

local function tween(inst, secs, props, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(secs, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local Audio
local function sound(name, pos, pitch)
	if Audio == nil then
		local ok, mod = pcall(function()
			return require(script.Parent:WaitForChild("MineAudio"))
		end)
		Audio = ok and mod or false
	end
	if Audio then
		pcall(Audio.play, name, nil, pitch, pos)
	end
end

-- Effects sit on a block's TOP face, not its centre. The server reports block
-- centres, and a zap arc or ricochet between two blocks that still stand would
-- otherwise run hidden inside the rock.
local function top(pos)
	return pos + Vector3.new(0, M.BLOCK / 2 + 0.5, 0)
end

local function rand(lo, hi)
	return lo + math.random() * (hi - lo)
end

-- A flat disc on the floor of the block at `pos`, rolling out to `reach`.
local function floorRing(pos, colour, reach, secs, delay)
	task.delay(delay or 0, function()
		local ring = part({
			Name = "Ring",
			Shape = Enum.PartType.Cylinder,
			Color = colour,
			Transparency = 0.25,
			-- A cylinder's axis is X: turn it upright so the disc lies flat.
			CFrame = CFrame.new(pos.X, pos.Y + M.BLOCK / 2 + 0.06, pos.Z) * CFrame.Angles(0, 0, math.rad(90)),
			Size = Vector3.new(0.12, 2, 2),
		})
		tween(ring, secs, { Size = Vector3.new(0.12, reach, reach), Transparency = 1 })
		Debris:AddItem(ring, secs + 0.05)
	end)
end

-- Little blobs thrown up and out of `pos`, falling back down as they fade.
local function spray(pos, colour, count, spread, height, size, secs, shape)
	for _ = 1, count do
		local a = rand(0, math.pi * 2)
		local r = rand(spread * 0.4, spread)
		local blob = part({
			Name = "Blob",
			Shape = shape or Enum.PartType.Ball,
			Color = colour,
			Size = Vector3.one * size,
			CFrame = CFrame.new(pos + Vector3.new(0, M.BLOCK / 2, 0)),
		})
		local peak = pos + Vector3.new(math.cos(a) * r * 0.5, M.BLOCK / 2 + height * rand(0.7, 1.1), math.sin(a) * r * 0.5)
		local land = pos + Vector3.new(math.cos(a) * r, M.BLOCK / 2, math.sin(a) * r)
		tween(blob, secs * 0.45, { CFrame = CFrame.new(peak) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(secs * 0.45, function()
			if blob.Parent then
				tween(blob, secs * 0.55, { CFrame = CFrame.new(land), Size = Vector3.one * (size * 0.3), Transparency = 1 },
					Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end)
		Debris:AddItem(blob, secs + 0.1)
	end
end

-- A jagged bolt from a to b: a few neon segments with sideways jitter.
local function bolt(a, b, colour, secs)
	local pts = { a }
	local steps = 4
	local dir = b - a
	local side = dir:Cross(Vector3.yAxis)
	if side.Magnitude < 1e-3 then
		side = Vector3.xAxis
	end
	side = side.Unit
	local up = dir:Cross(side)
	up = up.Magnitude > 1e-3 and up.Unit or Vector3.yAxis
	for i = 1, steps - 1 do
		local t = i / steps
		table.insert(pts, a + dir * t + side * rand(-0.9, 0.9) + up * rand(-0.6, 0.6))
	end
	table.insert(pts, b)
	for i = 1, #pts - 1 do
		local p0, p1 = pts[i], pts[i + 1]
		local len = (p1 - p0).Magnitude
		if len > 0.05 then
			local seg = part({
				Name = "Bolt",
				Color = colour,
				Size = Vector3.new(0.22, 0.22, len),
				CFrame = CFrame.lookAt((p0 + p1) / 2, p1),
			})
			tween(seg, secs, { Transparency = 1, Size = Vector3.new(0.05, 0.05, len) })
			Debris:AddItem(seg, secs + 0.05)
		end
	end
end

local function flash(pos, colour, size, secs)
	local f = part({
		Name = "Flash",
		Shape = Enum.PartType.Ball,
		Color = colour,
		Transparency = 0.1,
		Size = Vector3.one * 1,
		CFrame = CFrame.new(pos),
	})
	tween(f, secs, { Size = Vector3.one * size, Transparency = 1 })
	Debris:AddItem(f, secs + 0.05)
end

--------------------------------------------------------------------------------
-- The procs
--------------------------------------------------------------------------------

-- BLAST: the broken block bursts into its six neighbours.
function M.blast(pos)
	flash(top(pos), Color3.fromRGB(255, 150, 60), M.BLOCK * 2.6, 0.32)
	flash(top(pos), Color3.fromRGB(255, 235, 150), M.BLOCK * 1.4, 0.18)
	spray(pos, Color3.fromRGB(255, 120, 50), 10, M.BLOCK * 1.6, 4, 0.6, 0.55, Enum.PartType.Block)
	sound("proc_blast", pos)
end

-- TIDAL WAVE: two rings roll across the floor to the edge of the diamond the
-- wave hit (two blocks each way), with a splash thrown up in the middle.
function M.tide(pos)
	local reach = M.BLOCK * 2 * 2 + 2
	floorRing(pos, Color3.fromRGB(70, 170, 255), reach, 0.55, 0)
	floorRing(pos, Color3.fromRGB(170, 230, 255), reach * 0.8, 0.5, 0.14)
	spray(pos, Color3.fromRGB(110, 200, 255), 12, M.BLOCK * 1.8, 5, 0.5, 0.7)
	sound("proc_tide", pos)
end
-- The old name, kept for any caller that still uses it.
M.tideRipple = M.tide

-- ZAP: one event per hop, all in the same frame. Each hop arcs from the last,
-- staggered a beat apart so the chain reads as travelling.
local lastZap
function M.zap(pos)
	local now = os.clock()
	local chained = lastZap and (now - lastZap.t) < 0.25 and (lastZap.pos - pos).Magnitude < 40
	local from = chained and lastZap.pos or nil
	local n = chained and (lastZap.n + 1) or 1
	lastZap = { pos = pos, t = now, n = n }
	task.delay((n - 1) * 0.045, function()
		if from then
			bolt(top(from), top(pos), Color3.fromRGB(255, 240, 120), 0.25)
		end
		flash(top(pos), Color3.fromRGB(255, 230, 90), M.BLOCK * 1.1, 0.2)
		-- Each hop a little higher: the chain climbs.
		sound("proc_zap", pos, 1 + math.min(n - 1, 10) * 0.05)
	end)
end

-- SHATTER (replaced Ricochet, 2026-10-10): the block bursts into crystal shards
-- that fly to its 6 sides. The server sends one SHATTER per shatter, so a
-- chain (up to 3 per block you broke) shows as bursts hopping block to block.
function M.shatter(pos)
	local origin = top(pos)
	flash(origin, Color3.fromRGB(200, 170, 255), M.BLOCK * 1.2, 0.22)
	local dirs = {
		Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
		Vector3.new(0, 1, 0), Vector3.new(0.7, 0.7, 0), Vector3.new(-0.7, 0.7, 0), Vector3.new(0, 0.7, 0.7),
	}
	for _, d in ipairs(dirs) do
		local shard = part({
			Name = "Shard",
			Color = Color3.fromRGB(205, 180, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.15,
			Size = Vector3.new(0.35, 0.35, 1.1),
			CFrame = CFrame.lookAt(origin, origin + d) * CFrame.Angles(0, 0, rand(0, math.pi)),
		})
		local reach = M.BLOCK * rand(0.9, 1.2)
		tween(shard, 0.32, {
			CFrame = CFrame.lookAt(origin + d * reach, origin + d * (reach + 1)) * CFrame.Angles(0, 0, rand(0, math.pi)),
			Size = Vector3.new(0.12, 0.12, 0.5),
			Transparency = 1,
		})
		Debris:AddItem(shard, 0.36)
	end
	sound("proc_shatter", pos)
end
-- The old proc's name, kept so a stray RICOCHET event still shows something.
M.ricochet = M.shatter

-- EARTHQUAKE: the block itself already shakes (the client reads its Quaking
-- attribute). This adds a dust ring, stones hopping off it, a rumble, and a
-- small camera jolt when you are close enough to feel it.
function M.quake(pos)
	floorRing(pos, Color3.fromRGB(196, 150, 96), M.BLOCK * 3, 0.6, 0)
	spray(pos, Color3.fromRGB(150, 120, 90), 7, M.BLOCK * 1.2, 2.5, 0.55, 0.6, Enum.PartType.Block)
	sound("proc_quake", pos)
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and char.PrimaryPart and (char.PrimaryPart.Position - pos).Magnitude < 40 then
		task.spawn(function()
			for i = 1, 6 do
				hum.CameraOffset = Vector3.new(rand(-0.25, 0.25), rand(-0.2, 0.2), 0) * (1 - i / 7)
				task.wait(0.04)
			end
			hum.CameraOffset = Vector3.zero
		end)
	end
end

local BY_TEXT = {
	BLAST = M.blast,
	["TIDAL WAVE"] = M.tide,
	ZAP = M.zap,
	SHATTER = M.shatter,
	RICOCHET = M.shatter,
	QUAKE = M.quake,
}

function M.play(text, pos)
	local fn = BY_TEXT[text]
	if not fn or typeof(pos) ~= "Vector3" then
		return false
	end
	local ok, err = pcall(fn, pos)
	if not ok then
		warn("[MineProcFx] " .. tostring(text) .. ": " .. tostring(err))
	end
	return true
end

return M
