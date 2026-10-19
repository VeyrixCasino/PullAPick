// A small Roblox stand-in for running ReplicatedStorage.Mine.Shared modules,
// for real, in the standalone luau binary.
//
// Several checks re-derive a module's maths in JS, and a re-derivation agrees
// with itself whatever the module does. This loads the actual files instead:
// every named module and folder becomes a node under one fake `Shared`, and
// `require(node)` runs that file's source with `script` pointing at it. A
// module's own lazy requires (`script.Parent:FindFirstChild("MineStats")`)
// therefore resolve to the real files, and a module that was not loaded gives
// FindFirstChild nil, which the codebase's pcall(require, ...) pattern already
// treats as "not here".
//
//   const Shared = require("./_shared");
//   const lua = Shared.prelude(ROOT, ["MineCards", ...], ["SetPets"]) + test;
//
// Inside the test, `SHARED:FindFirstChild("MineCards")` is the module node.
const fs = require("fs");
const path = require("path");
const Luau = require("./_luau");

function prelude(root, names, folders) {
  const SH = path.join(root, "src/ReplicatedStorage/Mine/Shared");
  const read = (p) => Luau.readSrc(p);
  let s = `
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end, new = function(r, g, b) return { r, g, b } end }
Enum = setmetatable({}, { __index = function(_, k)
	return setmetatable({}, { __index = function(_, j) return { Name = j, EnumType = k } end })
end })
Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = (seed or 48611) % 2147483647 }, Random) end
function Random:NextNumber() self.s = (self.s * 48271) % 2147483647 return self.s / 2147483647 end
function Random:NextInteger(a, b) return a + math.floor(self:NextNumber() * (b - a + 1)) end
warn = function() end
local SOURCES, FOLDERS, CACHE = {}, {}, {}
local SHARED
local function moduleNode(name, parent)
	return { Name = name, Parent = parent, IsA = function(_, c) return c == "ModuleScript" end }
end
local function folderNode(name)
	local f = { Name = name }
	f.Parent = SHARED
	f.IsA = function(_, c) return c == "Folder" end
	f.GetChildren = function()
		local out = {}
		for _, n in ipairs(FOLDERS[name] or {}) do
			table.insert(out, moduleNode(n, f))
		end
		return out
	end
	f.FindFirstChild = function(_, n)
		for _, m in ipairs(FOLDERS[name] or {}) do
			if m == n then return moduleNode(n, f) end
		end
		return nil
	end
	f.WaitForChild = f.FindFirstChild
	return f
end
SHARED = { Name = "Shared" }
SHARED.FindFirstChild = function(_, n)
	if SOURCES["Shared/" .. n] then return moduleNode(n, SHARED) end
	if FOLDERS[n] then return folderNode(n) end
	return nil
end
SHARED.WaitForChild = function(self, n)
	return SHARED.FindFirstChild(self, n) or error("no stub for Shared." .. tostring(n))
end
local function anyNode(name)
	return { Name = name, WaitForChild = function(_, n)
		if n == "Shared" then return SHARED end
		return anyNode(n)
	end, FindFirstChild = function(_, n)
		if n == "Shared" then return SHARED end
		return anyNode(n)
	end }
end
game = { GetService = function(_, n) return anyNode(n) end }
script = { Name = "harness", Parent = SHARED }
function require(node)
	if type(node) ~= "table" or not node.Name then
		error("require of something that is not a module")
	end
	local key = ((node.Parent and node.Parent.Name) or "?") .. "/" .. node.Name
	if CACHE[key] ~= nil then return CACHE[key] end
	local src = SOURCES[key]
	if not src then error("no module " .. key) end
	local saved = script
	script = node
	local ok, result = pcall(src)
	script = saved
	if not ok then error(key .. ": " .. tostring(result)) end
	CACHE[key] = result
	return result
end
`;
  for (const n of names) {
    s += `SOURCES["Shared/${n}"] = function()\n${read(path.join(SH, n + ".luau"))}\nend\n`;
  }
  for (const folder of folders || []) {
    const dir = path.join(SH, folder);
    const files = fs.readdirSync(dir).filter((f) => f.endsWith(".luau")).sort();
    const list = files.map((f) => f.replace(/\.luau$/, ""));
    s += `FOLDERS["${folder}"] = { ${list.map((x) => `"${x}"`).join(", ")} }\n`;
    for (const f of files) {
      s += `SOURCES["${folder}/${f.replace(/\.luau$/, "")}"] = function()\n${read(path.join(dir, f))}\nend\n`;
    }
  }
  return s;
}

module.exports = { prelude };
