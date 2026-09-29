// Chest drop tables, redone: gems out, hats and charms in, pack counts unbounded.
const fs = require("fs"), path = require("path");
const R = path.join(__dirname, "..", "src");
const CFG = path.join(R, "ReplicatedStorage/Mine/Shared/MineConfig.luau");
const GEAR = path.join(R, "ReplicatedStorage/Mine/Shared/MineGear.luau");
const MS = path.join(R, "ServerScriptService/Mine/MineServer.server.luau");

function edit(file, fn) {
  const raw = fs.readFileSync(file, "utf8");
  const crlf = raw.indexOf("\r\n") >= 0;
  let s = raw.split("\r\n").join("\n");
  const before = s;
  s = fn(s);
  if (s === before) throw new Error("no change: " + path.basename(file));
  fs.writeFileSync(file, crlf ? s.split("\n").join("\r\n") : s);
  console.log("ok " + path.basename(file));
}
function one(s, old, nw) {
  const n = s.split(old).length - 1;
  if (n !== 1) throw new Error("count " + n + " for: " + old.slice(0, 60));
  return s.replace(old, nw);
}

// ---------- 1. the table (skipped if already applied) ----------
const cfgDone = fs.readFileSync(CFG,"utf8").includes("CHEST_PACK_STREAK");
if (cfgDone) console.log("skip MineConfig.luau (already applied)"); else edit(CFG, s => one(s,
`MineConfig.CHEST_LOOT = {
	{ kind = "pack",   weight = 62 },
	{ kind = "coins",  weight = 14 },
	{ kind = "gems",   weight = 12 },
	{ kind = "dust",   weight = 8 },
	{ kind = "relic",  weight = 0.6, lucky = true },
}`,
`--[[
	WHAT A CHEST PAYS.

	Gems are gone from this table on purpose. Gems are minted by selling scrap
	ore now, which is the whole point of the ore roster -- a currency whose
	price we set rather than one that leaks out of every chest in the game.

	Hats and charms both arrive here, and the gap between them is the design:
	a hat is something you see often enough to go looking for sets, a charm is
	a real find. Hats run about 8x the rate of charms.

	Per 1000 chests, roughly: 701 packs, 170 coins, 90 hats, 22 dust,
	11 charms, 6 relics.
]]
MineConfig.CHEST_LOOT = {
	{ kind = "pack",   weight = 70 },
	{ kind = "coins",  weight = 17 },
	{ kind = "hat",    weight = 9 },
	{ kind = "dust",   weight = 2.2 },
	{ kind = "charm",  weight = 1.1, lucky = true },
	{ kind = "relic",  weight = 0.6, lucky = true },
}

--[[
	HOW MANY PACKS A PACK CHEST PAYS.

	Not one. A chest can come up empty and a chest can bury you, and there is
	no cap on the good end -- that open tail is the entire reason the empty end
	is allowed to exist. No pity, no floor, no "guaranteed after N".

	The haul is base + a geometric run: each extra pack keeps the run going
	with probability STREAK, scaled by luck. At luck 1 that averages under two
	packs and comes up empty about one time in ten. Stack enough luck and
	STREAK approaches its ceiling, where hauls of 10-20 stop being remarkable.
	The ceiling is on the per-step probability, never on the count.
]]
MineConfig.CHEST_PACK_BASE = 1
MineConfig.CHEST_PACK_EMPTY = 0.10
MineConfig.CHEST_PACK_STREAK = 0.42
MineConfig.CHEST_PACK_STREAK_MAX = 0.94

function MineConfig.chestPackCount(luck, rng)
	rng = rng or Random.new()
	local l = math.max(1, tonumber(luck) or 1)
	if rng:NextNumber() < (MineConfig.CHEST_PACK_EMPTY / l) then
		return 0
	end
	local n = MineConfig.CHEST_PACK_BASE
	local p = math.min(MineConfig.CHEST_PACK_STREAK_MAX, MineConfig.CHEST_PACK_STREAK * l)
	while rng:NextNumber() < p do
		n += 1
	end
	return n
end`));

// ---------- 2. let a caller force the slot, so a hat crate gives a hat ----------
edit(GEAR, s => one(s,
`function MineGear.rollPiece(id, rng)
	rng = rng or Random.new()
	local slot = MineGear.rollSlot(rng)`,
`-- \`forceSlot\` pins the slot instead of rolling it, which is what makes a hat
-- crate a hat crate rather than a gear crate that sometimes pays boots.
function MineGear.rollPiece(id, rng, forceSlot)
	rng = rng or Random.new()
	local slot = forceSlot or MineGear.rollSlot(rng)`));

// ---------- 3. the branches ----------
edit(MS, s => {
  // pack: hand out a run, not a single row
  s = one(s,
`	if chosen.kind == "pack" then
		local row = {
			kind = kind,
			chestId = chest.id,
			zoneTier = tier,
			zoneId = zone.id,
			layer = layer,
			setId = C.setForLayer(zone, layer),
		}
		local stampedLuck = tonumber(b and b.luck) or 1
		if stampedLuck > 1 then
			row.luck = stampedLuck
		end
		table.insert(p.packs, row)
		return "pack", chest.id
	elseif chosen.kind == "coins" then`,
`	if chosen.kind == "pack" then
		-- A run, not a row. Sometimes nothing, sometimes a pile; the count is
		-- uncapped on purpose (C.chestPackCount).
		local stampedLuck = tonumber(b and b.luck) or 1
		local n = C.chestPackCount and C.chestPackCount(luck, rng) or 1
		for _ = 1, n do
			local row = {
				kind = kind,
				chestId = chest.id,
				zoneTier = tier,
				zoneId = zone.id,
				layer = layer,
				setId = C.setForLayer(zone, layer),
			}
			if stampedLuck > 1 then
				row.luck = stampedLuck
			end
			table.insert(p.packs, row)
		end
		if n == 0 then
			return "empty", 0
		end
		return "pack", chest.id, n
	elseif chosen.kind == "hat" then
		-- Head-slot gear, rolled on the spot. The common cosmetic find.
		if Gear and Gear.rollPiece then
			p.gear = p.gear or {}
			local id = "g" .. tostring(os.time()) .. tostring(rng:NextInteger(1000, 9999))
			local piece = Gear.rollPiece(id, rng, "head")
			if piece then
				table.insert(p.gear, piece)
				return "hat", piece.name or "Hat"
			end
		end
		-- Gear unavailable: fall through to a pack rather than a dead chest.
		table.insert(p.packs, { kind = kind, chestId = chest.id, zoneTier = tier,
			zoneId = zone.id, layer = layer, setId = C.setForLayer(zone, layer) })
		return "pack", chest.id
	elseif chosen.kind == "charm" then
		-- The rare one. Never a duplicate; a full set falls back to a pack so
		-- the rarest roll is never a dead one, same as relics.
		local okC, Charms = pcall(function()
			return require(shared:WaitForChild("MineCharms"))
		end)
		if okC and Charms and Charms.packPool then
			p.charms = p.charms or {}
			local pool = {}
			for _, c in ipairs(Charms.packPool() or {}) do
				if not p.charms[c.id] then table.insert(pool, c) end
			end
			if #pool > 0 then
				local c = pool[rng:NextInteger(1, #pool)]
				p.charms[c.id] = true
				return "charm", c.name or c.id
			end
		end
		table.insert(p.packs, { kind = kind, chestId = chest.id, zoneTier = tier,
			zoneId = zone.id, layer = layer, setId = C.setForLayer(zone, layer) })
		return "pack", chest.id
	elseif chosen.kind == "coins" then`);

  // gems row is gone from the table; drop the branch that served it
  s = one(s,
`	elseif chosen.kind == "gems" then
		-- Worth roughly 6-18 ore blocks.
		local amount = math.max(1, math.floor(oreValue * (6 + rng:NextNumber() * 12)
			* (b.gemFind or 1) * luck))
		p.gems = (p.gems or 0) + amount
		return "gems", amount
	elseif chosen.kind == "dust" then`,
`	elseif chosen.kind == "dust" then`);

  // oreValue only existed for the gems row
  s = one(s,
`	local oreValue = math.max(1, C.gemsFor and C.gemsFor("iron", zone, layer) or 1)
`, "");

  // and the comment above the function no longer describes it
  s = one(s,
`-- What a broken chest actually yields. Almost always a pack; sometimes coins,
-- gems or dust; very rarely a relic, which is a permanent item that survives
-- rebirth. Luck shifts weight onto the rows worth having.`,
`-- What a broken chest actually yields. Usually packs -- a run of them, which
-- can be none -- sometimes coins, a hat often enough to chase sets, a charm
-- rarely, and a relic almost never. No gems: those are minted from scrap ore
-- now. Luck shifts weight onto the rows worth having AND lengthens the run.`);
  return s;
});
console.log("chest tables redone");
