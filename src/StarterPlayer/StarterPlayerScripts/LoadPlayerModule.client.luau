-- Roblox injects PlayerModule under StarterPlayer at play, not StarterPlayerScripts.
-- Require it from here so WASD/camera boot. Do not clone: a second copy fights
-- the engine module and the server snaps you back to spawn.
local StarterPlayer = game:GetService("StarterPlayer")

local booted = false
local function boot(pm)
	if booted or not pm or not pm:IsA("ModuleScript") then
		return
	end
	booted = true
	require(pm)
end

local existing = StarterPlayer:FindFirstChild("PlayerModule")
if existing then
	boot(existing)
else
	StarterPlayer.ChildAdded:Connect(function(child)
		if child.Name == "PlayerModule" then
			boot(child)
		end
	end)
	task.defer(function()
		boot(StarterPlayer:WaitForChild("PlayerModule", 15))
	end)
end
