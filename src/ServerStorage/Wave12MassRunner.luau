local Factory = require(game.ReplicatedStorage.ToolModelFactory)
local gen = game:GetService('GenerationService')
local HttpService = game:GetService('HttpService')
local root = game.ReplicatedStorage.ToolModels_50
local FINISHES = {'Shiny','Shadow','Golden','Prism','Rainbow'}

local function softenMore(p)
	p = string.gsub(p, '[Gg]lowing', 'warm amber')
	p = string.gsub(p, '[Nn]eon', 'soft light')
	p = string.gsub(p, '[Ee]xplosive', 'mining charge')
	p = string.gsub(p, '[Bb]omb', 'charge pot')
	p = string.gsub(p, '[Ff]use', 'wick cord')
	p = string.gsub(p, '[Bb]lood', 'rust')
	p = string.gsub(p, '[Ww]eapon', 'tool')
	p = string.gsub(p, '[Vv]oid', 'dark hollow')
	p = string.gsub(p, '[Cc]orkscrew', 'helical twin')
	p = string.gsub(p, '[Tt]ar', 'dark resin')
	p = string.gsub(p, '[Ss]lurry', 'thick fill')
	return p .. ' Family-friendly workshop prop, toy-safe materials, no violence.'
end

return function(jobs)
	local results = {}
	for _, job in ipairs(jobs) do
		local folderExisting = root:FindFirstChild(job.name)
		if folderExisting and folderExisting:FindFirstChild('Normal') then
			table.insert(results, { name = job.name, status = 'SKIP_EXISTS' })
		else
			if folderExisting then folderExisting:Destroy() end
			local target = Vector3.new(job.size[1], job.size[2], job.size[3])
			local ok, model = pcall(function()
				return gen:GenerateModelAsync({ TextPrompt = job.prompt }, { PredefinedSchema = 'Body1' })
			end)
			local retried = false
			if not ok then
				retried = true
				ok, model = pcall(function()
					return gen:GenerateModelAsync({ TextPrompt = softenMore(job.prompt) }, { PredefinedSchema = 'Body1' })
				end)
			end
			if not ok then
				table.insert(results, { name = job.name, status = 'FAIL', err = tostring(model), retried = retried })
			elseif typeof(model) ~= 'Instance' then
				table.insert(results, { name = job.name, status = 'BAD_TYPE', err = typeof(model), retried = retried })
			else
				local size = model:GetExtentsSize()
				local tMax = math.max(target.X, target.Y, target.Z)
				local sMax = math.max(size.X, size.Y, size.Z)
				if sMax > 0 then model:ScaleTo(tMax / sMax) end
				for _, d in ipairs(model:GetDescendants()) do
					if d:IsA('BasePart') then
						d.Anchored = true
						d.CanCollide = false
					end
				end
				local folder = Instance.new('Folder')
				folder.Name = job.name
				if job.rarity then folder:SetAttribute('ProposedRarity', job.rarity) end
				folder.Parent = root
				model.Name = 'Normal'
				model.Parent = folder
				for _, fin in ipairs(FINISHES) do
					local clone = Factory.cloneWithFinish(model, fin)
					clone.Name = fin
					clone.Parent = folder
				end
				local ext = model:GetExtentsSize()
				table.insert(results, {
					name = job.name,
					status = 'OK',
					kind = job.category,
					rarity = job.rarity,
					retried = retried,
					extents = string.format('%.2f x %.2f x %.2f', ext.X, ext.Y, ext.Z),
				})
			end
		end
	end
	return HttpService:JSONEncode(results)
end
