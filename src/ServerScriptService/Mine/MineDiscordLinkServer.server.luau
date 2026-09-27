-- MineDiscordLinkServer: soft-redirect chat !link to Inventory > Account
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local function toast(plr, msg)
	local remotes = RS:FindFirstChild("Mine") and RS.Mine:FindFirstChild("Remotes")
	local net = remotes and remotes:FindFirstChild("MineNet")
	if net then
		net:FireClient(plr, "toast", tostring(msg))
	else
		warn("[Link]", plr.Name, msg)
	end
end
local function onChat(plr, msg)
	local text = tostring(msg or "")
	local lower = string.lower(text)
	if not (lower:match("^%s*!link") or lower:match("^%s*/link")) then
		return
	end
	toast(plr, "Open Inventory → Account, paste your Discord !link code there.")
end
local function hook(plr)
	plr.Chatted:Connect(function(msg)
		onChat(plr, msg)
	end)
end
Players.PlayerAdded:Connect(hook)
for _, plr in ipairs(Players:GetPlayers()) do
	hook(plr)
end
