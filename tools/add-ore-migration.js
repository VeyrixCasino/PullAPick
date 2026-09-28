// One-time save migration for the ore roster swap.
const fs = require("fs"), path = require("path");
const MS = path.join(__dirname, "..", "src/ServerScriptService/Mine/MineServer.server.luau");
const raw = fs.readFileSync(MS, "utf8");
const CRLF = raw.indexOf("\r\n") >= 0;
let s = raw.split("\r\n").join("\n");

if (s.indexOf("oreMigrationPass") >= 0) { console.log("already present"); process.exit(0); }

const anchor = `	if p.gotFirstPick == nil then
		p.gotFirstPick = true
	end`;
if (s.split(anchor).length - 1 !== 1) throw new Error("load-guard anchor not unique");

const block = anchor + `
	--[[
		Ore roster swap: 33 ids were retired and every one of them is load
		bearing twice over. p.ores[id] is banked material, and every ore pack in
		the bag is "<id>_ore_pack" -- so dropping an id without a map does not
		just rename a rock, it deletes a player's stock and bricks their packs
		into rows that no longer resolve to anything.

		Runs once per profile and stamps oreRosterV so it never runs twice. The
		merge is additive: a save holding both the old id and its replacement
		keeps the sum rather than whichever the loop happened to reach last.
	]]
	if p.oreRosterV ~= 1 then
		local map = C.ORE_MIGRATION
		if type(map) == "table" then
			if type(p.ores) == "table" then
				for oldId, newId in pairs(map) do
					local held = tonumber(p.ores[oldId])
					if held and held > 0 then
						p.ores[newId] = (tonumber(p.ores[newId]) or 0) + held
					end
					p.ores[oldId] = nil
				end
			end
			if type(p.packs) == "table" then
				for _, pk in ipairs(p.packs) do
					local pid = pk and pk.packId
					if type(pid) == "string" then
						local baseId = pid:match("^(.*)_ore_pack$")
						local to = baseId and map[baseId]
						if to then
							pk.packId = to .. "_ore_pack"
							local def = Packs and Packs.get and Packs.get(pk.packId)
							pk.packName = (def and def.name) or pk.packName
						end
					end
				end
			end
		end
		p.oreRosterV = 1
	end`;

s = s.replace(anchor, block);
fs.writeFileSync(MS, CRLF ? s.split("\n").join("\r\n") : s);
console.log("migration pass added");
