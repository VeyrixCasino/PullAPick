local Factory = require(game.ReplicatedStorage.ToolModelFactory)
local gen = game:GetService('GenerationService')
local root = game.ReplicatedStorage.ToolModels_50
local FINISHES = {'Shiny','Shadow','Golden','Prism','Rainbow'}
local NEG = [[ HARD BANS: absolutely no people, humans, characters, humanoids, mannequins, faces, heads, limbs, hands, fingers, creatures, animals, dolls. Single tool prop ONLY. GRIP LAW (picks + drills): Exactly ONE straight grip/handle/haft shaft sized for a Roblox R15 hand (~3-4 studs long, comfortable thickness, natural Tool orientation). NEVER two handles, dual shafts, V-grip, forked twin poles, bifurcated handle, double stick, side stick + main shaft as second grip, T-bar that reads as two hands, pistol grip + vertical shaft combo, or any multi-hand stance. One business end + one grip. Not oversized, top-heavy, or unholdable. EXPLOSIVES: throwable / plantable charge ONLY — no long haft, no pick handle, no drill grip, no second stick. Compact palm-to-two-hand mass. Clear fuse / pull / strap. Not a weapon sword, not a missile, not a glowing fantasy orb. LOOK: industrial mining workshop — timber, iron, brass, soot, leather, canvas. Dig for Cards / Mine For Cards prestige props. Materials first, silhouette second, lore fluff last. BAN ALSO: text, letters, numbers, logos, UI, watermarks, neon purple wash, glowing orb cores, aether/magic spam, blood, gore, wounds, toy plastic, low-poly blob, photoreal photo clutter, cluttered background, base plate, identical twin of another tool in the set. ]]
local SIZES = {
	pick = Vector3.new(2.2, 3.9, 1),
	drill = Vector3.new(1.5, 3.3, 1.4),
	bomb = Vector3.new(1.3, 1.5, 1.3),
}
local M = {}
function M.scaleTo(model, target)
	local size = model:GetExtentsSize()
	local tMax = math.max(target.X, target.Y, target.Z)
	local sMax = math.max(size.X, size.Y, size.Z)
	if sMax <= 0 then return end
	model:ScaleTo(tMax / sMax)
end
function M.fileTool(name, model, kind)
	local targetSize = SIZES[kind]
	if root:FindFirstChild(name) then root[name]:Destroy() end
	M.scaleTo(model, targetSize)
	for _,d in ipairs(model:GetDescendants()) do
		if d:IsA('BasePart') then d.Anchored = true; d.CanCollide = false end
	end
	local folder = Instance.new('Folder')
	folder.Name = name
	folder:SetAttribute('ProposedRarity','Common')
	folder.Parent = root
	model.Name = 'Normal'
	model.Parent = folder
	for _,fin in ipairs(FINISHES) do
		local clone = Factory.cloneWithFinish(model, fin)
		clone.Name = fin
		clone.Parent = folder
	end
	return name..' filed children='..#folder:GetChildren()
end
function M.genOne(name, prompt, negExtra, kind)
	local existing = root:FindFirstChild(name)
	if existing and existing:FindFirstChild('Normal') then return name..' SKIP' end
	local full = prompt..NEG..' Negative extra: '..(negExtra or '')
	local ok, modelOrErr = pcall(function()
		return gen:GenerateModelAsync({ TextPrompt = full }, { PredefinedSchema = 'Body1' })
	end)
	if not ok or typeof(modelOrErr) ~= 'Instance' then
		local ok2, m2 = pcall(function()
			return gen:GenerateModelAsync({ TextPrompt = 'Workshop prop sculpt: '..full }, { PredefinedSchema = 'Body1' })
		end)
		if not ok2 or typeof(m2) ~= 'Instance' then
			return name..' FAIL: '..tostring(modelOrErr)..' | soft: '..tostring(m2)
		end
		return M.fileTool(name, m2, kind)..' (soft-retry)'
	end
	return M.fileTool(name, modelOrErr, kind)
end
function M.pair(aName, aPrompt, aNeg, aKind, bName, bPrompt, bNeg, bKind)
	local r1 = M.genOne(aName, aPrompt, aNeg, aKind)
	local r2 = M.genOne(bName, bPrompt, bNeg, bKind)
	return r1..'\n'..r2
end
return M
