// The blacksmith bench: upgrade an ore tool, or scrap it.
//
// Both act on a uid, never on a list index. A bag that shifts between the
// client drawing the panel and the player pressing the button would otherwise
// upgrade the wrong tool -- the same reason packs already take a uid.
const fs = require("fs"), path = require("path");
const MS = path.join(__dirname, "..", "src/ServerScriptService/Mine/MineServer.server.luau");
const raw = fs.readFileSync(MS, "utf8");
const crlf = raw.indexOf("\r\n") >= 0;
let s = raw.split("\r\n").join("\n");
function one(old, nw) {
  const n = s.split(old).length - 1;
  if (n !== 1) throw new Error("count " + n + " for: " + old.slice(0, 70));
  s = s.replace(old, nw);
}
if (s.indexOf("Verbs.upgradeOreTool") >= 0) { console.log("already present"); process.exit(0); }

const VERBS = `
--[[
	THE BLACKSMITH BENCH.

	Ore tools level on their own 1..TOOL_MAX_LEVEL scale, paid for in ore and
	stardust. MineConfig owns the pricing so the bench, the recycler and the UI
	cannot drift apart: toolUpgradeCost for one step, toolSpent for everything
	poured in, toolRecycle for what comes back.

	Every entry point takes a UID. Not an index -- the bag reorders whenever a
	tool is found or scrapped, and an index captured when the panel was drawn
	names a different tool by the time the button is pressed. Packs already
	learned this; the comment on openAt says so.

	The uid never changes here. Upgrading mutates \`level\` and nothing else, so
	a tool is the same object at level 900 that it was at level 1.
]]
local function findOreTool(p, uid)
	if type(uid) ~= "string" or uid == "" then
		return nil, nil
	end
	for i, t in ipairs(p.oreTools or {}) do
		if type(t) == "table" and t.uid == uid then
			return t, i
		end
	end
	return nil, nil
end

-- The ore an ore tool is made of is the ore it eats to level. Anything else
-- would let a player bank one cheap ore and level every tool they own with it.
local function oreToolCost(tool)
	local oreDef = C.ORES and C.ORES[tonumber(tool.tier) or 1]
	local typeMult = 1
	local ok, Tools = pcall(function()
		return require(shared:WaitForChild("MineTools"))
	end)
	if ok and Tools and Tools.byId then
		local td = Tools.byId(tool.typeId)
		typeMult = (td and tonumber(td.weight)) and (1 / math.max(0.01, td.weight)) or 1
	end
	local level = math.max(1, tonumber(tool.level) or 1)
	local ore, dust = C.toolUpgradeCost(tool.tier, level, typeMult)
	return ore, dust, oreDef, typeMult
end

function Verbs.upgradeOreTool(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local uid = (type(payload) == "table") and payload.uid or payload
	local tool = findOreTool(p, uid)
	if not tool then
		net:FireClient(plr, "toast", "That tool is not in your bag")
		return
	end
	local level = math.max(1, tonumber(tool.level) or 1)
	if level >= (C.TOOL_MAX_LEVEL or 1000) then
		net:FireClient(plr, "toast", "That tool is at max level")
		return
	end

	local ore, dust, oreDef = oreToolCost(tool)
	if not ore or not dust then
		net:FireClient(plr, "toast", "That tool cannot be levelled")
		return
	end
	local oreId = oreDef and oreDef.id
	if not oreId then
		net:FireClient(plr, "toast", "That tool has no ore")
		return
	end

	-- How many steps the player can actually afford, capped by the request and
	-- by the level ceiling. \`count\` lets the panel offer +1 / +10 / max without
	-- a round trip per level.
	local want = math.floor(tonumber(type(payload) == "table" and payload.count) or 1)
	want = math.clamp(want, 1, (C.TOOL_MAX_LEVEL or 1000) - level)

	p.ores = p.ores or {}
	local haveOre = tonumber(p.ores[oreId]) or 0
	local haveDust = tonumber(p.dust) or 0
	local spentOre, spentDust, steps = 0, 0, 0
	for i = 0, want - 1 do
		local o, d = C.toolUpgradeCost(tool.tier, level + i, select(4, oreToolCost(tool)))
		if not o then break end
		if haveOre - spentOre < o or haveDust - spentDust < d then break end
		spentOre += o
		spentDust += d
		steps += 1
	end

	if steps == 0 then
		net:FireClient(plr, "toast", string.format(
			"Needs %s %s and %s stardust",
			shortNum and shortNum(ore) or tostring(ore),
			(oreDef and oreDef.name) or oreId,
			shortNum and shortNum(dust) or tostring(dust)))
		return
	end

	p.ores[oreId] = haveOre - spentOre
	p.dust = haveDust - spentDust
	tool.level = level + steps          -- the uid is untouched, on purpose
	bumpStat(plr, p, "upgrades")
	net:FireClient(plr, "toast", string.format("+%d  ->  level %d", steps, tool.level))
	snap(plr)
	markDirty(plr)
end

function Verbs.recycleOreTool(plr, payload)
	local p = profiles[plr.UserId]
	if not p then
		return
	end
	local uid = (type(payload) == "table") and payload.uid or payload
	local tool, index = findOreTool(p, uid)
	if not tool or not index then
		net:FireClient(plr, "toast", "That tool is not in your bag")
		return
	end
	if tool.equipped then
		net:FireClient(plr, "toast", "Unequip it first")
		return
	end

	local _, _, oreDef, typeMult = oreToolCost(tool)
	local level = math.max(1, tonumber(tool.level) or 1)
	local ore, dust = C.toolRecycle(tool.tier, level, typeMult)
	local oreId = oreDef and oreDef.id

	table.remove(p.oreTools, index)
	if oreId and ore > 0 then
		p.ores = p.ores or {}
		p.ores[oreId] = (tonumber(p.ores[oreId]) or 0) + ore
	end
	if dust > 0 then
		p.dust = (tonumber(p.dust) or 0) + dust
	end
	net:FireClient(plr, "toast", string.format("Scrapped  +%s %s  +%s stardust",
		shortNum and shortNum(ore) or tostring(ore),
		(oreDef and oreDef.name) or "ore",
		shortNum and shortNum(dust) or tostring(dust)))
	snap(plr)
	markDirty(plr)
end
`;

// put them just before the dispatch, after the other verbs exist
one("net.OnServerEvent:Connect(function(plr, action, payload)",
    VERBS + "\nnet.OnServerEvent:Connect(function(plr, action, payload)");

// and wire them into the dispatch
one(`		if action == "dig" and typeof(payload) == "Instance" then swingBlock(plr, payload)`,
`		if action == "dig" and typeof(payload) == "Instance" then swingBlock(plr, payload)
		elseif action == "upgradeOreTool" then Verbs.upgradeOreTool(plr, payload)
		elseif action == "recycleOreTool" then Verbs.recycleOreTool(plr, payload)`);

fs.writeFileSync(MS, crlf ? s.split("\n").join("\r\n") : s);
console.log("bench verbs added and wired into the dispatch");
