local M = {}
function M.run(jobsJson)
  local HttpService = game:GetService('HttpService')
  local Factory = require(game.ReplicatedStorage.ToolModelFactory)
  local gen = game:GetService('GenerationService')
  local root = game.ReplicatedStorage.ToolModels_50
  local FINISHES = {'Shiny','Shadow','Golden','Prism','Rainbow'}
  local jobs = HttpService:JSONDecode(jobsJson)
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
    return p .. ' Family-friendly workshop prop, toy-safe materials, no violence.'
  end
  local function generate(prompt)
    return gen:GenerateModelAsync({ TextPrompt = prompt }, { PredefinedSchema = 'Body1' })
  end
  local results = {}
  for _,job in ipairs(jobs) do
    local target = Vector3.new(job.target[1], job.target[2], job.target[3])
    if root:FindFirstChild(job.name) then
      table.insert(results, {name=job.name, status='SKIP_EXISTS'})
    else
      local ok, model = pcall(function() return generate(job.prompt) end)
      local retried = false
      if not ok then
        retried = true
        ok, model = pcall(function() return generate(softenMore(job.prompt)) end)
      end
      if not ok then
        table.insert(results, {name=job.name, status='FAIL', err=tostring(model), retried=retried})
      elseif typeof(model) ~= 'Instance' then
        table.insert(results, {name=job.name, status='BAD_TYPE', err=typeof(model), retried=retried})
      else
        local size = model:GetExtentsSize()
        local tMax = math.max(target.X, target.Y, target.Z)
        local sMax = math.max(size.X, size.Y, size.Z)
        if sMax > 0 then model:ScaleTo(tMax / sMax) end
        for _,d in ipairs(model:GetDescendants()) do
          if d:IsA('BasePart') then d.Anchored = true; d.CanCollide = false end
        end
        local folder = Instance.new('Folder')
        folder.Name = job.name
        folder.Parent = root
        model.Name = 'Normal'
        model.Parent = folder
        for _,fin in ipairs(FINISHES) do
          local clone = Factory.cloneWithFinish(model, fin)
          clone.Name = fin
          clone.Parent = folder
        end
        local ext = model:GetExtentsSize()
        table.insert(results, {
          name=job.name, status='OK', kind=job.kind, retried=retried,
          extents=string.format('%.2f x %.2f x %.2f', ext.X, ext.Y, ext.Z)
        })
      end
    end
  end
  return HttpService:JSONEncode(results)
end
return M
