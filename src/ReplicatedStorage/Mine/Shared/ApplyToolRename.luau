local Http = game:GetService("HttpService")
local Apply = {}
local byOld

local function loadMap()
	if byOld then return byOld end
	byOld = {}
	local folder = game.ServerStorage:FindFirstChild("_ToolRenameMap")
	if not folder then return byOld end
	local idx = folder:FindFirstChild("byOld")
	if idx then
		for _, sv in ipairs(idx:GetChildren()) do
			if sv:IsA("StringValue") then
				local ok, slice = pcall(Http.JSONDecode, Http, sv.Value)
				if ok and type(slice) == "table" then
					for k, e in pairs(slice) do byOld[k] = e end
				end
			end
		end
	else
		for _, sv in ipairs(folder:GetChildren()) do
			if sv:IsA("StringValue") and sv.Name:match("^c%d+") then
				local ok, slice = pcall(Http.JSONDecode, Http, sv.Value)
				if ok then
					for _, e in ipairs(slice) do byOld[e.o] = e end
				end
			end
		end
	end
	return byOld
end

local function remapTool(t)
	if type(t) ~= "table" or type(t.name) ~= "string" then return end
	local e = loadMap()[t.name]
	if not e then return end
	t.name = e.n
	if e.d and e.d ~= "" then t.id = e.d end
end

local function walk(node, depth, seen)
	if depth > 12 or type(node) ~= "table" then return end
	if seen[node] then return end
	seen[node] = true
	if node.family and node.name then remapTool(node) end
	for _, v in pairs(node) do
		if type(v) == "table" then walk(v, depth + 1, seen) end
	end
end

function Apply.apply(root)
	walk(root, 0, {})
	return root
end

function Apply.lookup(oldName)
	local e = loadMap()[oldName]
	return e
end

return Apply
