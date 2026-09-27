-- Players never collide with each other (mining / lobby crowding).
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local GROUP = "MinePlayers"

local MinePlayerCollision = {}

local function ensureGroup()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP)
	end)
	PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)
end

local function tagPart(part)
	if part:IsA("BasePart") then
		pcall(function()
			part.CollisionGroup = GROUP
		end)
	end
end

local function tagCharacter(char)
	if not char then
		return
	end
	for _, d in ipairs(char:GetDescendants()) do
		tagPart(d)
	end
	char.DescendantAdded:Connect(tagPart)
end

local function hookPlayer(plr)
	if plr.Character then
		tagCharacter(plr.Character)
	end
	plr.CharacterAdded:Connect(tagCharacter)
end

function MinePlayerCollision.start()
	ensureGroup()
	for _, plr in ipairs(Players:GetPlayers()) do
		hookPlayer(plr)
	end
	Players.PlayerAdded:Connect(hookPlayer)
end

return MinePlayerCollision
