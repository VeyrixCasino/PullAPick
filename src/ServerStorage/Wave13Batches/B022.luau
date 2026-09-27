return function()
local Factory = require(game.ReplicatedStorage.ToolModelFactory)
local gen = game:GetService('GenerationService')
local root = game.ReplicatedStorage.ToolModels_50
local FINISHES = {'Shiny','Shadow','Golden','Prism','Rainbow'}
local jobs = {{name='CoalWingnut',kind='Pick',rarity='Common',target=Vector3.new(2.2,3.9,1),prompt='Ultra high-detail AAA Roblox handheld mining pickaxe, ~20k tris, clean 3/4. Silhouette: **coal-dusted oversized wingnut as the cheek with short spike, rubber grip**. Materials: steel wingnut, iron spike, oak, rubber. Key details: wing flanges, spike, grip. R15. Soft workshop light. NO people, text, logos, UI. HARD BANS: absolutely no people, humans, characters, humanoids, mannequins, faces, heads, limbs, hands, fingers, creatures, animals, dolls. Single tool prop ONLY.  GRIP LAW (picks + drills): Exactly ONE straight grip/handle/haft shaft sized for a Roblox R15 hand (~3–4 studs long, comfortable thickness, natural Tool orientation). NEVER two handles, dual shafts, V-grip, forked twin poles, bifurcated handle, double stick, side stick + main shaft as second grip, T-bar that reads as two hands, pistol grip + vertical shaft combo, or any multi-hand stance. One business end + one grip. Not oversized, top-heavy, or unholdable.  EXPLOSIVES: throwable / plantable charge ONLY — no long haft, no pick handle, no drill grip, no second stick. Compact palm-to-two-hand mass. Clear fuse / pull / strap. Not a weapon sword, not a missile, not a glowing fantasy orb.  LOOK: industrial mining workshop — timber, iron, brass, soot, leather, canvas. Dig for Cards / Mine For Cards prestige props. Materials first, silhouette second, lore fluff last.  BAN ALSO: text, letters, numbers, logos, UI, watermarks, neon purple wash, glowing orb cores, aether/magic spam, blood, gore, wounds, toy plastic, low-poly blob, photoreal photo clutter, cluttered background, base plate, identical twin of another tool in the set. Also avoid: Boltcheek, Rivetwall, neon'},
{name='CoalWrenchjaw',kind='Pick',rarity='Common',target=Vector3.new(2.2,3.9,1),prompt='Ultra high-detail AAA Roblox handheld mining pickaxe, ~20k tris, clean 3/4. Silhouette: **coal-dusted adjustable wrench jaw as the head, wood haft stub, rubber**. Materials: steel wrench, oak, rubber, brass. Key details: jaw opening, adjust screw, grip. R15. Soft workshop light. NO people, text, logos, UI. HARD BANS: absolutely no people, humans, characters, humanoids, mannequins, faces, heads, limbs, hands, fingers, creatures, animals, dolls. Single tool prop ONLY.  GRIP LAW (picks + drills): Exactly ONE straight grip/handle/haft shaft sized for a Roblox R15 hand (~3–4 studs long, comfortable thickness, natural Tool orientation). NEVER two handles, dual shafts, V-grip, forked twin poles, bifurcated handle, double stick, side stick + main shaft as second grip, T-bar that reads as two hands, pistol grip + vertical shaft combo, or any multi-hand stance. One business end + one grip. Not oversized, top-heavy, or unholdable.  EXPLOSIVES: throwable / plantable charge ONLY — no long haft, no pick handle, no drill grip, no second stick. Compact palm-to-two-hand mass. Clear fuse / pull / strap. Not a weapon sword, not a missile, not a glowing fantasy orb.  LOOK: industrial mining workshop — timber, iron, brass, soot, leather, canvas. Dig for Cards / Mine For Cards prestige props. Materials first, silhouette second, lore fluff last.  BAN ALSO: text, letters, numbers, logos, UI, watermarks, neon purple wash, glowing orb cores, aether/magic spam, blood, gore, wounds, toy plastic, low-poly blob, photoreal photo clutter, cluttered background, base plate, identical twin of another tool in the set. Also avoid: Railclamp, neon, void'},
{name='CopperBallpeen',kind='Pick',rarity='Common',target=Vector3.new(2.2,3.9,1),prompt='Ultra high-detail AAA Roblox handheld mining pickaxe, ~20k tris, clean 3/4. Silhouette: **copper-banded spike opposite a ball-peen poll, wood haft, leather**. Materials: steel peen, iron spike, oak, leather. Key details: ball peen, spike, wrap. R15. Soft workshop light. NO people, text, logos, UI. HARD BANS: absolutely no people, humans, characters, humanoids, mannequins, faces, heads, limbs, hands, fingers, creatures, animals, dolls. Single tool prop ONLY.  GRIP LAW (picks + drills): Exactly ONE straight grip/handle/haft shaft sized for a Roblox R15 hand (~3–4 studs long, comfortable thickness, natural Tool orientation). NEVER two handles, dual shafts, V-grip, forked twin poles, bifurcated handle, double stick, side stick + main shaft as second grip, T-bar that reads as two hands, pistol grip + vertical shaft combo, or any multi-hand stance. One business end + one grip. Not oversized, top-heavy, or unholdable.  EXPLOSIVES: throwable / plantable charge ONLY — no long haft, no pick handle, no drill grip, no second stick. Compact palm-to-two-hand mass. Clear fuse / pull / strap. Not a weapon sword, not a missile, not a glowing fantasy orb.  LOOK: industrial mining workshop — timber, iron, brass, soot, leather, canvas. Dig for Cards / Mine For Cards prestige props. Materials first, silhouette second, lore fluff last.  BAN ALSO: text, letters, numbers, logos, UI, watermarks, neon purple wash, glowing orb cores, aether/magic spam, blood, gore, wounds, toy plastic, low-poly blob, photoreal photo clutter, cluttered background, base plate, identical twin of another tool in the set. Also avoid: Wantorbpick, Brickpick, neon'}}
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
local function generate(prompt)
  return gen:GenerateModelAsync({ TextPrompt = prompt }, { PredefinedSchema = 'Body1' })
end
local results = {}
for _,job in ipairs(jobs) do
  local folderExisting = root:FindFirstChild(job.name)
  if folderExisting and folderExisting:FindFirstChild('Normal') then
    table.insert(results, {name=job.name, status='SKIP_EXISTS'})
  else
    if folderExisting then folderExisting:Destroy() end
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
      local tMax = math.max(job.target.X, job.target.Y, job.target.Z)
      local sMax = math.max(size.X, size.Y, size.Z)
      if sMax > 0 then model:ScaleTo(tMax / sMax) end
      for _,d in ipairs(model:GetDescendants()) do
        if d:IsA('BasePart') then d.Anchored = true; d.CanCollide = false end
      end
      local folder = Instance.new('Folder')
      folder.Name = job.name
      folder:SetAttribute('ProposedRarity', job.rarity)
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
        name=job.name, status='OK', kind=job.kind, rarity=job.rarity, retried=retried,
        extents=string.format('%.2f x %.2f x %.2f', ext.X, ext.Y, ext.Z)
      })
    end
  end
end
return game:GetService('HttpService'):JSONEncode(results)

end

