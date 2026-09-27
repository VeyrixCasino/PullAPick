-- MineAntiGear: block Roblox catalog / StarterGear tools in the Mine place.
-- Game-owned Tools must be marked with MineAntiGear.mark() BEFORE parenting.
-- Does NOT strip avatar clothes / accessories — players keep Roblox appearance.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local TAG = "MineOwnedTool"

local BANNED_NAME = {
	"btool", "btools", "building tools", "buildingtools", "f3x", "sfoth",
	"hammer", "clone tool", "grab tool", "move tool", "resize",
	"delete tool", "paint tool", "surface tool", "material tool",
	"newservertools", "server tools", "walleditor", "part maker",
}

local MineAntiGear = {}
MineAntiGear.TAG = TAG

function MineAntiGear.isAllowed(inst)
	if not inst then
		return false
	end
	if CollectionService:HasTag(inst, TAG) then
		return true
	end
	if inst:GetAttribute("MineOwned") == true then
		return true
	end
	return false
end

function MineAntiGear.mark(tool)
	if not tool or not (tool:IsA("Tool") or tool:IsA("HopperBin")) then
		return tool
	end
	tool:SetAttribute("MineOwned", true)
	CollectionService:AddTag(tool, TAG)
	return tool
end

local function isGear(inst)
	return inst:IsA("Tool") or inst:IsA("HopperBin")
end

local function nameLooksBanned(inst)
	local n = string.lower(inst.Name or "")
	for _, needle in ipairs(BANNED_NAME) do
		if string.find(n, needle, 1, true) then
			return true
		end
	end
	return false
end

local function looksLikeBtool(inst)
	if not isGear(inst) then
		return false
	end
	if MineAntiGear.isAllowed(inst) then
		return false
	end
	if inst:IsA("HopperBin") then
		return true
	end
	if nameLooksBanned(inst) then
		return true
	end
	if inst:FindFirstChild("SyncAPI", true) then
		return true
	end
	if inst:FindFirstChildWhichIsA("Handles", true) and inst:FindFirstChildWhichIsA("SelectionBox", true) then
		return true
	end
	return true
end

local function stripContainer(container)
	if not container then
		return
	end
	for _, child in ipairs(container:GetChildren()) do
		if isGear(child) and looksLikeBtool(child) then
			child:Destroy()
		end
	end
end

local function clearStarterGear(plr)
	local sg = plr:FindFirstChildOfClass("StarterGear") or plr:FindFirstChild("StarterGear")
	if not sg then
		return
	end
	for _, child in ipairs(sg:GetChildren()) do
		child:Destroy()
	end
end

local function destroyIfForeign(child)
	if not isGear(child) then
		return
	end
	task.defer(function()
		if child.Parent and looksLikeBtool(child) then
			child:Destroy()
		end
	end)
end

local function watchContainer(container, bucket)
	if not container then
		return
	end
	table.insert(bucket, container.ChildAdded:Connect(destroyIfForeign))
end

local function scrubPlayer(plr, char)
	clearStarterGear(plr)
	stripContainer(plr:FindFirstChildOfClass("StarterGear") or plr:FindFirstChild("StarterGear"))
	stripContainer(plr:FindFirstChildOfClass("Backpack") or plr:FindFirstChild("Backpack"))
	if char then
		stripContainer(char)
	end
end

function MineAntiGear.bindPlayer(plr)
	clearStarterGear(plr)

	local conns = {}

	local function onCharacter(char)
		scrubPlayer(plr, char)

		local backpack = plr:FindFirstChildOfClass("Backpack") or plr:FindFirstChild("Backpack")
		watchContainer(backpack, conns)
		watchContainer(char, conns)

		local sg = plr:FindFirstChildOfClass("StarterGear") or plr:FindFirstChild("StarterGear")
		watchContainer(sg, conns)

		-- Catalog Tools can arrive with appearance after CharacterAdded.
		table.insert(conns, plr.CharacterAppearanceLoaded:Connect(function()
			scrubPlayer(plr, char)
		end))
	end

	table.insert(conns, plr.CharacterAdded:Connect(onCharacter))
	if plr.Character then
		task.defer(onCharacter, plr.Character)
	end

	table.insert(conns, plr.ChildAdded:Connect(function(child)
		if child:IsA("StarterGear") or child.Name == "StarterGear" then
			clearStarterGear(plr)
			watchContainer(child, conns)
		elseif child:IsA("Backpack") or child.Name == "Backpack" then
			stripContainer(child)
			watchContainer(child, conns)
		end
	end))

	table.insert(conns, plr.AncestryChanged:Connect(function(_, parent)
		if parent then
			return
		end
		for _, c in ipairs(conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		table.clear(conns)
	end))
end

function MineAntiGear.start()
	Players.PlayerAdded:Connect(MineAntiGear.bindPlayer)
	for _, plr in ipairs(Players:GetPlayers()) do
		MineAntiGear.bindPlayer(plr)
	end
	workspace.ChildAdded:Connect(function(child)
		if isGear(child) then
			task.defer(function()
				if child.Parent and looksLikeBtool(child) then
					child:Destroy()
				end
			end)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(2.5)
			for _, plr in ipairs(Players:GetPlayers()) do
				pcall(scrubPlayer, plr, plr.Character)
			end
			for _, d in ipairs(workspace:GetChildren()) do
				if isGear(d) and looksLikeBtool(d) then
					d:Destroy()
				end
			end
		end
	end)
end

return MineAntiGear
