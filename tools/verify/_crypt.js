// THE CANDY CRYPT'S LUAU HARNESS, shared by the checks that run the Crypt's
// real modules (tools/verify/crypt.js, crypt-v2.js, crypt-doc.js) and by the
// numbers generator (tools/gen/crypt-doc.js).
//
// One stub, so a check and the document cannot run the Crypt on two different
// pretend Robloxes. It is the stub crypt.js grew (2026-10-19), lifted out
// unchanged apart from three things:
//
//   * Optional modules. A module whose file is missing is simply not offered,
//     so `script.Parent:FindFirstChild(name)` answers nil exactly as Roblox
//     would. The Crypt calls three other agents' modules that way
//     (MineHalloweenPets, MineEnchants.rollHalloweenBook,
//     MineCharms.cryptChestCharm), and this lets the same check run before and
//     after they land.
//   * Folders. `HolidayPets/<name>` is offered as a child of a HolidayPets node
//     (the Trick-or-Treat case falls back to the Halloween 2026 Pack's list).
//   * A per-process script file in the OS temp folder. The old checks wrote to
//     .luau-bin/<name>.luau, one shared path, so two checkouts running the same
//     check at once (worktrees share .luau-bin) overwrote each other's script.
//
//   const H = require("./_crypt");
//   const out = H.run("crypt-v2", H.source(body), { stubs });
"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const SH = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared");
const SV = path.join(ROOT, "src/ServerScriptService/Mine");

// Every module the Crypt's require tree reaches, shared ones first. Order does
// not matter (requires are lazy); the server module is flagged by its folder.
const SHARED_MODULES = [
  "MineConfig", "MineDepth", "MineBags", "MineBagNames", "MineShopEconomy", "MineLaunch",
  "MineTools", "MineOreTools", "MineBreaking", "MineStats", "MineTemper", "MineCharms",
  "MineOrePouch", "MineSpaceMatter", "MineSkins", "MineToolSkins", "MineEnchants",
  "MineCandyTools", "MineTrickOrTreat", "MineCryptChests", "MineCryptRules", "MineCryptIcons",
  // Another agent's (V2-C); used only when it exists.
  "MineHalloweenPets",
];
const SERVER_MODULES = ["MineCrypt"];
const FOLDERS = { HolidayPets: ["Halloween2026"] };

const read = (p) => Luau.readSrc(p);
const exists = (p) => fs.existsSync(p);

function factories(root) {
  const sh = root ? path.join(root, "src/ReplicatedStorage/Mine/Shared") : SH;
  const sv = root ? path.join(root, "src/ServerScriptService/Mine") : SV;
  let out = "";
  const add = (name, file, parent) => {
    if (!exists(file)) return;
    out += `FACTORY[${JSON.stringify(name)}] = function()\n` +
      `\tlocal script = { Name = ${JSON.stringify(name)}, Parent = ${parent} }\n` +
      read(file) + "\nend\n";
  };
  for (const n of SHARED_MODULES) add(n, path.join(sh, n + ".luau"), "SHARED");
  for (const n of SERVER_MODULES) add(n, path.join(sv, n + ".luau"), "SERVERDIR");
  for (const [folder, kids] of Object.entries(FOLDERS)) {
    const dir = path.join(sh, folder);
    if (!exists(dir)) continue;
    out += `FACTORY[${JSON.stringify(folder)}] = function() return {} end\n`;
    for (const k of kids) add(k, path.join(dir, k + ".luau"), `inst(${JSON.stringify(folder)})`);
  }
  return out;
}

// The Roblox stand-in. Seeded Random, so every roll is the same on every run.
const PRELUDE = `
local V3 = {}
V3.__index = V3
Vector3 = {}
function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
V3.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then return Vector3.new(b.X * a, b.Y * a, b.Z * a) end
	if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b) return Vector3.new(a.X / b, a.Y / b, a.Z / b) end
V3.__unm = function(a) return Vector3.new(-a.X, -a.Y, -a.Z) end
Vector3.zero = Vector3.new(0, 0, 0)
Vector3.one = Vector3.new(1, 1, 1)
Vector2 = { new = function(x, y) return { X = x or 0, Y = y or 0 } end }
local function c3(r, g, b) return { R = r or 0, G = g or 0, B = b or 0, Lerp = function(self) return self end } end
Color3 = {
	fromRGB = function(r, g, b) return c3((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end,
	new = function(r, g, b) return c3(r, g, b) end,
	fromHSV = function(h, s, v) return c3(v, v, v) end,
	fromHex = function() return c3(1, 1, 1) end,
}
local any = setmetatable({}, { __index = function() return function() return {} end end })
CFrame = setmetatable({ new = function() return {} end }, { __index = function() return function() return {} end end })
UDim2 = any
UDim = any
NumberRange = any
NumberSequence = any
NumberSequenceKeypoint = any
ColorSequence = any
ColorSequenceKeypoint = any
TweenInfo = any
Font = any
local enumCache = {}
Enum = setmetatable({}, { __index = function(_, k)
	local t = enumCache[k]
	if not t then
		t = setmetatable({}, { __index = function(_, k2) return { Name = k2, EnumType = k } end })
		enumCache[k] = t
	end
	return t
end })
Random = {}
Random.__index = Random
local seedCounter = 977
function Random.new(seed)
	seedCounter += 7919
	return setmetatable({ s = ((seed or seedCounter) % 2147483646) + 1 }, Random)
end
function Random:NextNumber(a, b)
	self.s = (self.s * 48271) % 2147483647
	local u = self.s / 2147483647
	if a and b then return a + (b - a) * u end
	return u
end
function Random:NextInteger(a, b)
	return a + math.floor(self:NextNumber() * (b - a + 1))
end
warn = function(...) end
task = { wait = function() end, spawn = function(f, ...) end, delay = function() end, defer = function() end }
typeof = typeof or function(v) return type(v) end

FACTORY, LOADED = {}, {}
function inst(name)
	return { Name = name, WaitForChild = function(_, n) return inst(n) end, FindFirstChild = function(_, n)
		if FACTORY[n] then return inst(n) end
		return nil
	end, Clone = function(self) return inst(self.Name) end, Destroy = function() end }
end
SHARED = inst("Shared")
SERVERDIR = inst("Mine")
local MINE = { Name = "Mine", WaitForChild = function() return SHARED end, FindFirstChild = function() return SHARED end }
local RS = { Name = "ReplicatedStorage", WaitForChild = function() return MINE end, FindFirstChild = function() return MINE end }
local guid = 0
PLAYERS = {}
local SERVICES = {
	ReplicatedStorage = RS,
	RunService = { IsStudio = function() return false end, IsServer = function() return true end, IsClient = function() return false end },
	ServerStorage = { FindFirstChild = function() return nil end, WaitForChild = function(_, n) return inst(n) end },
	HttpService = {
		GenerateGUID = function()
			guid += 1
			return string.format("%08x-0000-0000-0000-%012x", guid, guid)
		end,
		JSONEncode = function() return "{}" end,
	},
	Players = {
		GetPlayers = function() return PLAYERS end,
		GetPlayerByUserId = function(_, uid)
			for _, pl in ipairs(PLAYERS) do
				if pl.UserId == uid then return pl end
			end
			return nil
		end,
	},
}
game = { GetService = function(_, n) return SERVICES[n] or any end }
workspace = { FindFirstChild = function() return nil end, GetServerTimeNow = function() return os.time() end }

function require(t)
	local n = type(t) == "table" and t.Name or tostring(t)
	if LOADED[n] ~= nil then return LOADED[n] end
	local f = FACTORY[n]
	if not f then error("no module " .. tostring(n)) end
	local m = f()
	LOADED[n] = m
	return m
end
`;

// The whole script: stand-in, the real modules, then the caller's Luau.
// `stubs` is Luau that runs after the factories, so a caller can replace one
// (FACTORY.MinePackConfig = ...) before anything requires it.
function source(body, opts) {
  opts = opts || {};
  return PRELUDE + "\n" + factories(opts.root) + "\n" + (opts.stubs || "") + "\n" + body;
}

// Runs a script and returns its stdout. Throws with stdout + stderr attached.
function run(tag, lua) {
  const file = path.join(os.tmpdir(), `mfc-${tag}-${process.pid}.luau`);
  fs.writeFileSync(file, lua);
  try {
    return execFileSync(Luau.LUAU, [file], { encoding: "utf8", maxBuffer: 1 << 26 });
  } finally {
    try { fs.unlinkSync(file); } catch (e) { /* already gone */ }
  }
}

module.exports = { ROOT, SH, SV, PRELUDE, SHARED_MODULES, factories, source, run, Luau };
