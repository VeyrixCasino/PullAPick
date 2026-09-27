local H = game:GetService("HttpService")
local S = game:GetService("SerializationService")
local CH = 900 * 1000
local targets = {
	{ "ReplicatedFirst", game.ReplicatedFirst },
	{ "ReplicatedStorage", game.ReplicatedStorage },
	{ "ServerScriptService", game.ServerScriptService },
	{ "ServerStorage", game.ServerStorage },
	{ "StarterPlayerScripts", game.StarterPlayer.StarterPlayerScripts },
}
local out = {}
for _, t in ipairs(targets) do
	local ok, err = pcall(function()
		local root = Instance.new("Folder")
		root.Name = t[1]
		local skipped = 0
		for _, c in ipairs(t[2]:GetChildren()) do
			local cl = c:Clone()
			if cl then cl.Parent = root else skipped += 1 end
		end
		local buf = S:SerializeInstancesAsync({ root })
		root:Destroy()
		local n = buffer.len(buf)
		local parts = math.ceil(n / CH)
		for i = 0, parts - 1 do
			local s = buffer.readstring(buf, i * CH, math.min(CH, n - i * CH))
			H:PostAsync(string.format("http://localhost:34999/?name=%s.rbxm.part%04d", t[1], i), s, Enum.HttpContentType.TextPlain)
		end
		return n .. " bytes, " .. parts .. " parts, skipped " .. skipped
	end)
	table.insert(out, t[1] .. ": " .. tostring(ok) .. " " .. tostring(err))
end
return table.concat(out, "\n")
