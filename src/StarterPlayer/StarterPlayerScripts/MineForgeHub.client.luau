--[[
	MineForgeHub.client -- mounts THE FORGE (MineForgeHub) and opens it.

	Owner, 2026-10-11: Forge A is the design; the inventory brief is the
	feature list. The hub mounts inside the main HUD ScreenGui ("MineUI") as
	a frame named ForgeHub, so MineClient's HUD hiders hide the right-hand dock
	and the wallet while it is open, the same as the Blacksmith.

	How it opens: MineClient's Forge (anvil) dock button fires the client-only
	BindableEvent Mine.ForgeHubOpen made here. A level-up (server event
	"playerLevel") celebrates. Its own copy of the snapshot comes off the same
	"snapshot" event MineClient reads, and opening asks for a fresh one
	("snapNow") so the numbers are true even if you have been standing still.
]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mine = RS:WaitForChild("Mine")
local shared = mine:WaitForChild("Shared")
local net = mine:WaitForChild("Remotes"):WaitForChild("MineNet")
local Hub = require(shared:WaitForChild("MineForgeHub"))
local okCel, Celebrate = pcall(function()
	return require(shared:WaitForChild("MineCelebrate", 5))
end)

local snap
local hudGui = player:WaitForChild("PlayerGui"):WaitForChild("MineUI", 60)
if not hudGui then
	-- No HUD yet (or renamed): a ScreenGui of its own, so the Forge still works.
	hudGui = Instance.new("ScreenGui")
	hudGui.Name = "MineForgeHubUI"
	hudGui.ResetOnSpawn = false
	hudGui.IgnoreGuiInset = true
	hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	hudGui.Parent = player:WaitForChild("PlayerGui")
end

local hub = Hub.mount(hudGui, {
	getSnap = function()
		return snap
	end,
	send = function(verb, payload)
		net:FireServer(verb, payload)
	end,
	isStudio = RunService:IsStudio(),
	-- BAGS / COIN SHOP: the old shop's shelves, through MineClient.
	onShop = function(tab)
		local ev = mine:FindFirstChild("OpenPanel")
		if ev then
			ev:Fire("shop", tab)
		end
	end,
})

-- The way in: MineClient's Forge button fires this.
local openEv = mine:FindFirstChild("ForgeHubOpen") or Instance.new("BindableEvent")
openEv.Name = "ForgeHubOpen"
openEv.Parent = mine
openEv.Event:Connect(function(tab)
	-- A counter only ever opens (walking up twice must not close it); the
	-- Forge button toggles.
	if tab == "counter" then
		if hub.isOpen() then
			return
		end
		tab = nil
	elseif hub.isOpen() then
		hub.close()
		return
	end
	pcall(function()
		net:FireServer("snapNow")
	end)
	hub.open(tab)
end)

net.OnClientEvent:Connect(function(action, payload)
	if action == "snapshot" and type(payload) == "table" then
		snap = payload
		if hub.isOpen() then
			pcall(hub.refresh)
		end
	elseif action == "bookBundle" and type(payload) == "table" then
		-- A bundle bought here (or a chest's, while the Forge is open).
		if hub.showBundle then
			pcall(hub.showBundle, payload.books)
		end
	elseif action == "playerLevel" and type(payload) == "table" then
		if okCel and Celebrate and Celebrate.burst then
			pcall(Celebrate.burst, (#(payload.unlocks or {}) > 0) and 3 or 1)
		end
	end
end)
