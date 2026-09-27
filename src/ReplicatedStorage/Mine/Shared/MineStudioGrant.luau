-- Studio-only helpers. Never inflate currency / zones / HQ kits.
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local DSS = game:GetService("DataStoreService")

local MineStudioGrant = {}

--[[
	One-shot clean slate for peaceful playtests.
	Set ReplicatedStorage.Mine.ForcePlaytestReset = true in Edit, then Play once.
	Wipes to a normal starter (T1 pick, meadow, zero wallet).

	Play cannot persist attribute clears into the place file, so a stuck `true`
	in Edit used to wipe EVERY Studio join. A DataStore marker consumes each
	enable once; turning the attribute off clears the marker for a future wipe.
]]
function MineStudioGrant.playtestReset(plr, profiles, blankFn)
	if not RunService:IsStudio() or not (plr and profiles and blankFn) then
		return false
	end
	local mine = RS:FindFirstChild("Mine") or script.Parent.Parent
	local want = mine and mine:GetAttribute("ForcePlaytestReset")
	local markerStore = DSS:GetDataStore("Mine_StudioFlags")
	local markerKey = "force_reset_consumed_" .. tostring(plr.UserId)
	if not want then
		pcall(function()
			markerStore:RemoveAsync(markerKey)
		end)
		return false
	end
	local consumed = false
	pcall(function()
		consumed = markerStore:GetAsync(markerKey) and true or false
	end)
	if consumed then
		warn("[Mine] ForcePlaytestReset still true in Edit but already consumed — set it false in Edit")
		return false
	end
	local p = blankFn()
	p.tools = { pickaxe = 1, drill = 0, explosive = 0 }
	p.toolFamily = "pickaxe"
	p.toolEquipped = true
	p.shopToolId = nil
	p.ownedShopTools = {}
	p.chestTool = nil
	p.fossilTool = nil
	p.coins = 0
	p.gems = 0
	p.maxUnlockedZone = 1
	p.zoneId = "meadow"
	p.daily = { streak = 0, last = 0 }
	profiles[plr.UserId] = p
	pcall(function()
		markerStore:SetAsync(markerKey, os.time())
	end)
	pcall(function()
		mine:SetAttribute("ForcePlaytestReset", false)
	end)
	warn("[Mine] Studio playtest reset (clean starter) →", plr.Name)
	return true
end

return MineStudioGrant
