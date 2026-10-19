// THE ENCHANTS' REAL CODE PATHS, for enchant-audit.js and enchant-balance.js.
//
// Owner, 2026-10-19: "make sure all enchants works, Do balancing checks to make
// sure good enough, but not too overpowered stacked with enchants too". Both
// checks have to measure what the SERVER does, not a re-derivation that agrees
// with itself whatever the server does. So this loads, for real:
//
//   * the shared modules (MineEnchants, MineConfig, MineOreTools, MineCards and
//     the whole pet roster, MineBoostLayers, MineBreaking, ...);
//   * two server modules, MineEnchantService (every enchant's streaks, hits,
//     casts and reveals) and MinePatterns (which cells a tool touches);
//   * MineServer's own proc code, SLICED out of the script in file order:
//     Dig.PROC_SKIP .. Dig.procsAt, Dig.QUAKE .. Dig.startQuake, the quake
//     tick loop (its body made a callable Dig.__quakeTick), and the Equip Best
//     scorers Dig.petShares / Dig.petWorth / Dig.heldProcFamily.
//
// and gives them a small voxel world to act on: blocks with HP, a sim clock
// that os.clock() reads, a net that records what the client would be told,
// and swingNeighbour landing hits the way the server's does (with the breaking
// gate open). SIM.swing mirrors swingBlock from the damage roll on; the audit
// check pins that mirror to swingBlock's text so the two cannot drift.
//
// A helper: suite.sh skips files that start with "_".
"use strict";
const fs = require("fs");
const path = require("path");
const os = require("os");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const SH = "src/ReplicatedStorage/Mine/Shared";
const SV = "src/ServerScriptService/Mine";

const SHARED_MODULES = [
  "MineConfig", "MineDepth", "MineBags", "MineBagNames", "MineShopEconomy", "MineLaunch",
  "MineTools", "MineOreTools", "MineBreaking", "MineStats", "MineCards", "MinePetBoosts",
  "MinePetRoster", "MineZonePets", "MineSetPets", "MineEHPets", "MineBoostLayers", "MineEnchants",
];
const SHARED_FOLDERS = ["SetPets", "HolidayPets"];
const SERVER_MODULES = ["MineEnchantService", "MinePatterns"];

// ------------------------------------------------------------ the slices --
function serverLines(root) {
  return Luau.readSrc(path.join(root, SV, "MineServer.server.luau")).split("\n");
}

// The first line starting with `head`, at or after `from`.
function find(L, head, from = 0) {
  for (let i = from; i < L.length; i++) {
    if (L[i].startsWith(head)) return i;
  }
  throw new Error("MineServer: could not find a line starting " + JSON.stringify(head));
}
// From that line to the first line exactly `close` after it, inclusive.
function blockAt(L, i, close) {
  for (let j = i; j < L.length; j++) {
    if (L[j] === close) return { i, j, text: L.slice(i, j + 1).join("\n") };
  }
  throw new Error("MineServer: unterminated block at line " + (i + 1));
}

function serverSlices(root) {
  const L = serverLines(root);
  const parts = [];
  // 1. The proc tables and Dig.procsAt, as one run of lines.
  const a = find(L, "Dig.PROC_SKIP = {");
  const p = find(L, "function Dig.procsAt(", a);
  const procs = blockAt(L, p, "end");
  parts.push({ i: a, text: L.slice(a, procs.j + 1).join("\n") });
  // 2. The quake registries and Dig.startQuake.
  const q = find(L, "Dig.QUAKE = {}", procs.j);
  const qs = find(L, "Dig.QUAKE_STACK = {}", q);
  const sq = blockAt(L, find(L, "function Dig.startQuake(", qs), "end");
  parts.push({ i: q, text: L[q] });
  parts.push({ i: qs, text: L[qs] });
  parts.push({ i: sq.i, text: sq.text });
  // 3. The quake tick: the loop's body, made callable once per sim second.
  const t = find(L, "task.spawn(function()", sq.j);
  const loop = blockAt(L, t, "end)");
  const want = ["task.spawn(function()", "\twhile true do", "\t\ttask.wait(1)"];
  for (let k = 0; k < want.length; k++) {
    if (L[t + k] !== want[k]) throw new Error("MineServer: the quake tick loop changed shape at line " + (t + k + 1));
  }
  if (L[loop.j - 1] !== "\tend") throw new Error("MineServer: the quake tick loop's end changed shape");
  parts.push({ i: t, text: ["Dig.__quakeTick = function()", "\tdo", ...L.slice(t + 3, loop.j)].join("\n") + "\nend" });
  // 4. Equip Best's scorers (the team a player would actually seat).
  for (const head of ["function Dig.petShares(", "function Dig.petWorth(", "function Dig.heldProcFamily("]) {
    const b = blockAt(L, find(L, head), "end");
    parts.push({ i: b.i, text: b.text });
  }
  parts.sort((x, y) => x.i - y.i);
  return parts.map((x) => x.text).join("\n\n");
}

// The text of swingBlock, for the audit's mirror check.
function swingBlockText(root) {
  const L = serverLines(root);
  return blockAt(L, find(L, "local function swingBlock("), "end").text;
}
function finishBreakText(root) {
  const L = serverLines(root);
  return blockAt(L, find(L, "local function finishBreak("), "end").text;
}

// ------------------------------------------------------------ the prelude --
function prelude(root) {
  const read = (p) => Luau.readSrc(path.join(root, p));
  let s = `
-- ---------------------------------------------------- roblox stand-in --
local REAL_OS, REAL_TYPEOF = os, typeof
SIM = { t = 0, events = {}, log = {} }
-- os.clock is the sim clock, so streaks, graces and cooldowns run on sim time.
os = setmetatable({ clock = function() return SIM.t end }, { __index = REAL_OS })
typeof = function(v)
	if type(v) == "table" and rawget(v, "__inst") then return "Instance" end
	if type(v) == "table" and rawget(v, "__c3") then return "Color3" end
	return REAL_TYPEOF(v)
end
local V3 = {}
V3.__index = function(t, k)
	if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z) end
	return nil
end
Vector3 = {}
function Vector3.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3) end
V3.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then a, b = b, a end
	return Vector3.new(a.X * b, a.Y * b, a.Z * b)
end
Vector3.zero = Vector3.new(0, 0, 0)
Vector3.one = Vector3.new(1, 1, 1)
local function c3(r, g, b) return { __c3 = true, R = r or 0, G = g or 0, B = b or 0 } end
Color3 = {
	fromRGB = function(r, g, b) return c3((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end,
	new = function(r, g, b) return c3(r, g, b) end,
	fromHSV = function(h, s, v) return c3(v, v, v) end,
	fromHex = function() return c3(1, 1, 1) end,
}
local any = setmetatable({}, { __index = function() return function() return {} end end })
CFrame, UDim2, UDim, TweenInfo, NumberRange, NumberSequence, ColorSequence = any, any, any, any, any, any, any
local enumCache = {}
Enum = setmetatable({}, { __index = function(_, k)
	local t = enumCache[k]
	if not t then
		t = setmetatable({}, { __index = function(_, k2) return { Name = k2, EnumType = k } end })
		enumCache[k] = t
	end
	return t
end })
-- Seeded, but a Random.new() with no seed gets a fresh one each time, as the
-- engine's does: Dig.procsAt makes one per call and must not replay the
-- same rolls every swing.
math.randomseed(20261019)
Random = {}
Random.__index = Random
function Random.new(seed)
	return setmetatable({ s = ((seed or math.random(1, 2147483000)) % 2147483646) + 1 }, Random)
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
warn = function() end
task = { wait = function() end, spawn = function() end, delay = function() end, defer = function() end }

local FACTORY, FOLDERS, LOADED = {}, {}, {}
local function inst(name, parent)
	local n = { Name = name, Parent = parent }
	function n.WaitForChild(self, c) return self:FindFirstChild(c) or inst(c, self) end
	function n.FindFirstChild(self, c)
		if FOLDERS[c] then return inst(c, self) end
		if FACTORY[c] then return inst(c, self) end
		if FOLDERS[self.Name] and FACTORY[self.Name .. "/" .. c] then return inst(c, self) end
		return nil
	end
	function n.GetChildren(self)
		local out = {}
		for _, m in ipairs(FOLDERS[self.Name] or {}) do table.insert(out, inst(m, self)) end
		return out
	end
	function n.IsA(self, c)
		if FOLDERS[self.Name] then return c == "Folder" end
		return c == "ModuleScript"
	end
	function n.Clone(self) return inst(self.Name, self.Parent) end
	function n.Destroy() end
	return n
end
SHARED = inst("Shared")
SERVERDIR = inst("Mine")
local MINE = { Name = "Mine", WaitForChild = function() return SHARED end, FindFirstChild = function() return SHARED end }
local RS = { Name = "ReplicatedStorage", WaitForChild = function() return MINE end, FindFirstChild = function() return MINE end }
local SERVICES = {
	ReplicatedStorage = RS,
	RunService = { IsStudio = function() return true end, IsServer = function() return true end, IsClient = function() return false end },
	ServerStorage = { FindFirstChild = function() return nil end, WaitForChild = function(_, n) return inst(n) end },
}
game = { GetService = function(_, n) return SERVICES[n] or any end }
workspace = { FindFirstChild = function() return nil end, GetServerTimeNow = function() return 0 end }

function require(t)
	local n = type(t) == "table" and t.Name or tostring(t)
	local key = n
	if type(t) == "table" and t.Parent and FOLDERS[t.Parent.Name] then key = t.Parent.Name .. "/" .. n end
	if LOADED[key] ~= nil then return LOADED[key] end
	local f = FACTORY[key]
	if not f then error("no module " .. tostring(key)) end
	local m = f()
	LOADED[key] = m
	return m
end
`;
  const add = (key, file, parentExpr) => {
    s += `FACTORY[${JSON.stringify(key)}] = function()\n\tlocal script = { Name = ${JSON.stringify(key.split("/").pop())}, Parent = ${parentExpr} }\n${read(file)}\nend\n`;
  };
  for (const m of SHARED_MODULES) add(m, path.join(SH, m + ".luau"), "SHARED");
  for (const folder of SHARED_FOLDERS) {
    const dir = path.join(root, SH, folder);
    const files = fs.readdirSync(dir).filter((f) => f.endsWith(".luau")).sort();
    s += `FOLDERS[${JSON.stringify(folder)}] = { ${files.map((f) => JSON.stringify(f.replace(/\.luau$/, ""))).join(", ")} }\n`;
    for (const f of files) {
      add(folder + "/" + f.replace(/\.luau$/, ""), path.join(SH, folder, f), `inst(${JSON.stringify(folder)}, SHARED)`);
    }
  }
  for (const m of SERVER_MODULES) add(m, path.join(SV, m + ".luau"), "SERVERDIR");
  return s;
}

// --------------------------------------------------------------- the world --
// Lua that needs the modules: the world, the server's proc slices, SIM.swing.
function world(root) {
  return `
-- --------------------------------------------------------------- the world --
C = require("MineConfig")
E = require("MineEnchants")
Cards = require("MineCards")
Stats = require("MineStats")
EnchSvc = require("MineEnchantService")
Patterns = require("MinePatterns")
OreTools = require("MineOreTools")
Layers = require("MineBoostLayers")
Breaking = require("MineBreaking")

WORLD = { cells = {}, players = {} }
local Block = {}
Block.__index = Block
function Block:GetAttribute(k) return self.attrs[k] end
function Block:SetAttribute(k, v) self.attrs[k] = v end
function Block:IsA(c) return c == "BasePart" or c == "Part" end
function Block:Destroy() self.Parent = nil end
function keyOf(z, x, y, zz) return string.format("%s:%d:%d:%d", z, x, y, zz) end
local LIVE = { Name = "Mine" }
function WORLD.block(zoneId, x, y, z, hp, attrs)
	local b = setmetatable({ __inst = true, Name = "MineBlock", Parent = LIVE, attrs = {},
		Position = Vector3.new(x * 5, -y * 5, z * 5), Color = Color3.fromRGB(120, 100, 80) }, Block)
	b.attrs.ZoneId, b.attrs.CX, b.attrs.CY, b.attrs.CZ = zoneId, x, y, z
	b.attrs.Kind = "dirt"
	b.attrs.MaxHP = hp
	for k, v in pairs(attrs or {}) do b.attrs[k] = v end
	WORLD.cells[zoneId] = WORLD.cells[zoneId] or {}
	WORLD.cells[zoneId][keyOf(zoneId, x, y, z)] = b
	return b
end
function WORLD.remove(part)
	local a = part.attrs
	local cells = WORLD.cells[a.ZoneId]
	if cells then cells[keyOf(a.ZoneId, a.CX, a.CY, a.CZ)] = nil end
	part.Parent = nil
end
function WORLD.reset()
	WORLD.cells = {}
	SIM.events = {}
	Dig.QUAKE, Dig.QUAKE_STACK = {}, {}
end

-- What the client would be told.
net = { FireClient = function(_, plr, action, payload)
	table.insert(SIM.events, { action = action, payload = payload, t = SIM.t })
	if SIM.onEvent then SIM.onEvent(action, payload) end
end }
SIM.stats = { hits = 0, dmg = 0, broken = 0 }
-- One hit, as MineServer's swingNeighbour lands it once the gates pass:
-- Matter.chip's HP arithmetic, then the break.
function swingNeighbour(plr, part, dmg, p)
	if not part or not part.Parent or part.Name ~= "MineBlock" then return end
	local maxHp = tonumber(part.attrs.MaxHP) or 1
	local before = tonumber(part.attrs.HP) or maxHp
	local landed = math.min(dmg, math.max(0, before))
	local after = before - dmg
	part.attrs.HP = after
	SIM.stats.hits += 1
	SIM.stats.dmg += landed
	if SIM.onHit then SIM.onHit(part, landed) end
	if after <= 0 then
		WORLD.remove(part)
		SIM.stats.broken += 1
		if SIM.onBreak then SIM.onBreak(part) end
		return true
	end
	return false
end

-- The server's own proc code, in file order (tools/verify/_enchant-sim.js).
-- Inside it \`Svc\` is MineServer's services table (the quake tick asks it for
-- the player); everywhere else in these checks the enchant service is EnchSvc.
Dig = { Enchants = E, EnchSvc = EnchSvc }
profiles = {}
do
	local Svc = { Players = { GetPlayerByUserId = function(_, uid) return WORLD.players[uid] end } }
	${serverSlices(root).split("\n").join("\n\t")}
end

EnchSvc.init({ net = net, profiles = profiles, snap = function() end, markDirty = function() end })

--[[
	ONE SWING, as MineServer's swingBlock lands it from the damage roll on (the
	refusals, reach, budget and gate before it are the server's to keep). The
	audit check pins each step below to swingBlock's text.
]]
SIM.aim = Vector3.new(0, -0.8, -0.6)
function SIM.swing(plr, p, b, tool, zone, part)
	local cells = WORLD.cells[zone.id]
	local maxHp = tonumber(part.attrs.MaxHP) or 1
	local raw = (tool.power or 1) * (b.mineSpeed or 1) * (b.dirtBreak or 1)
	local dmg = math.floor(raw)
	if math.random() < (raw - dmg) then dmg += 1 end
	dmg = math.max(1, dmg)
	dmg = EnchSvc.hitDamage(plr, p, part, dmg, maxHp)
	local cx, cy, cz = part.attrs.CX, part.attrs.CY, part.attrs.CZ
	local touched = Patterns.resolve(tool, cx, cy, cz, SIM.aim, b)
	local oneShots = 0
	for _, c in ipairs(touched) do
		if not (c.cx == cx and c.cy == cy and c.cz == cz) then
			local other = cells[keyOf(zone.id, c.cx, c.cy, c.cz)]
			if other and other.Parent then
				local share = math.max(1, math.floor(dmg * (c.factor or 1)))
				local whole = (tonumber(other.attrs.HP) or math.huge) >= (tonumber(other.attrs.MaxHP) or 0)
				local broke = swingNeighbour(plr, other, share, p)
				if broke and whole then oneShots += 1 end
			end
		end
	end
	local wasWhole = (tonumber(part.attrs.HP) or maxHp) >= maxHp
	local aimPos = part.Position
	local centreBroken = swingNeighbour(plr, part, dmg, p) == true
	EnchSvc.afterSwing(plr, p, centreBroken and wasWhole, aimPos, oneShots + 1)
	Dig.procsAt(plr, p, b, zone, cells, part, cx, cy, cz, dmg, part.attrs.Kind, centreBroken, nil)
	local cast = EnchSvc.spellCast(plr, p, b, centreBroken, aimPos)
	if cast then
		Dig.procsAt(plr, p, cast.b, zone, cells, part, cx, cy, cz,
			math.max(1, math.floor(dmg * cast.power + 0.5)), part.attrs.Kind, cast.broke, false)
	end
	return centreBroken, dmg
end

--[[
	THE BOOSTS A SWING READS, in MineServer boosts()'s order for the sources
	these checks use: Layer 1 (the held tool's enchants through the real
	EnchSvc.layerStats, a skin's kit), Layer 2 (pets through the real
	Cards.applyKit, delta'd as Dig.petRows does; gear), combined by the real
	MineBoostLayers; swing rate folded; the one charm (MineCharms.applyEquipped's
	arithmetic); echo paid as swing rate; then the Special's gate (the real
	E.gateProcs on EnchSvc.special) and the clamp.
]]
function SIM.boosts(p, opts)
	opts = opts or {}
	local b = Cards.emptyBoosts()
	local T1, T2 = {}, {}
	for _, st in ipairs(EnchSvc.layerStats(p)) do
		Layers.add(T1, st.stat, st.value)
	end
	for stat, amount in pairs(opts.skin or {}) do
		Layers.add(T1, stat, amount)
	end
	local n = #(opts.pets or {})
	for _, card in ipairs(opts.pets or {}) do
		local one, zero = Cards.emptyBoosts(), Cards.emptyBoosts()
		Cards.applyKit(one, card, C.cardPower(card), n)
		for k, v in pairs(one) do
			if type(v) == "number" then
				local floorV = zero[k]
				if floorV == nil then floorV = (k == "swingRate") and 1 or 0 end
				if v ~= floorV then Layers.add(T2, k, v - floorV) end
			end
		end
	end
	for stat, amount in pairs(opts.gear or {}) do
		Layers.add(T2, stat, amount)
	end
	Layers.apply(b, T1, T2, Cards.ADDITIVE_STATS)
	Cards.foldSwingRate(b)
	for stat, amount in pairs(opts.charm or {}) do
		if stat == "swingRate" then
			b.swingSec = (b.swingSec or 1) / math.max(0.05, 1 + amount)
		elseif Cards.ADDITIVE_STATS[stat] then
			b[stat] = math.max(0, (b[stat] or 0) + amount)
		else
			b[stat] = math.max(0.05, (b[stat] or 1) + amount)
		end
	end
	-- Echo pays as swing rate in boosts() -- onto b.swingRate, after the fold,
	-- so (as on the server today) it never reaches swingSec. Mirrored as is.
	local echoLeft = tonumber(b.echo) or 0
	if echoLeft ~= 0 then
		b.swingRate = (tonumber(b.swingRate) or 1) + echoLeft * ((Stats and Stats.ECHO_TO_SWING) or (1.5 / 1.4))
		b.echo = 0
	end
	b = E.gateProcs(b, EnchSvc.special(p))
	return Cards.clampBoosts(b)
end

-- Advance the sim clock, ticking the quake loop once a second like the server.
function SIM.advance(dt)
	local before = SIM.t
	SIM.t += dt
	for _ = math.floor(before) + 1, math.floor(SIM.t) do
		Dig.__quakeTick()
	end
end
`;
}

// Run a Luau program; returns stdout (throws with the output on failure).
function run(lua, tag) {
  const file = path.join(os.tmpdir(), `mfc-${tag}-${process.pid}.luau`);
  fs.writeFileSync(file, lua);
  try {
    return execFileSync(Luau.LUAU, [file], { encoding: "utf8", maxBuffer: 1 << 28 });
  } catch (e) {
    const out = String(e.stdout || "") + String(e.stderr || "");
    const err = new Error("luau failed:\n" + out.split("\n").slice(-25).join("\n"));
    err.output = out;
    throw err;
  } finally {
    try { fs.unlinkSync(file); } catch (e) { /* gone already */ }
  }
}

module.exports = { prelude, world, serverSlices, swingBlockText, finishBreakText, run, SH, SV };
