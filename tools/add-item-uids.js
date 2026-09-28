// Give every owned INSTANCE a uid, and stamp one on anything that arrives
// without.
//
// The profile splits two ways and only one side needs ids:
//
//   instance lists  cards, packs, runes, gear, chestTools, relics
//   quantity maps   charms[id]=n, tempers[id]={rarity,n}, eventTools[id]=true,
//                   fossilTools[key], ores[id]=n, tools={pickaxe=n}
//
// A quantity map has nothing to identify -- you own three of a charm, not three
// distinguishable charms -- and turning those into instance lists would make the
// datastore BIGGER, which is the opposite of the point. So they stay as counts.
//
// Of the instance lists, cards already carry `serial` (speciesHex3 + 16 hex),
// packs already carry `uid`, and runes already carry a 16-hex `id`. The gaps
// are chestTools, gear and relics.
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

// ---- 1. extend the existing on-load stamp to the rest of the instance lists ----
one(`	for _, pk in ipairs(p.packs or {}) do
		if type(pk) == "table" and not pk.uid then
			pk.uid = instanceHex16()
		end
	end`,
`	for _, pk in ipairs(p.packs or {}) do
		if type(pk) == "table" and not pk.uid then
			pk.uid = instanceHex16()
		end
	end
	--[[
		Same stamp, for every other list of owned instances.

		chestTools was the real gap: its \`id\` is the CATALOG id, so two copies
		of the same flagship tool were indistinguishable in the save -- you
		could not name one of them to upgrade, trade or scrap it. gear and
		relics had the same shape. \`id\` is left alone because plenty of code
		keys off it; \`uid\` is added beside it.

		Runes are skipped on purpose: their \`id\` is already a 16-hex instance
		value, so a \`uid\` next to it would just be the same bytes twice.

		Quantity maps -- charms, tempers, eventTools, fossilTools, ores, tools --
		get nothing. You own three of a charm, not three distinguishable charms,
		and giving each a row would grow the save rather than shrink it.
	]]
	for _, list in ipairs({ p.chestTools, p.gear, p.relics }) do
		if type(list) == "table" then
			for _, row in ipairs(list) do
				if type(row) == "table" and not row.uid then
					row.uid = instanceHex16()
				end
			end
		end
	end`);

// ---- 2. stamp at the point of creation too, so a uid exists before the next save ----
one(`	table.insert(p.chestTools, {
		id = ct.id, name = ct.name, family = ct.family,
		rarity = ct.rarity or ct.rarityId,
		rarityId = ct.rarity or ct.rarityId,
		temperRolls = 0,
	})`,
`	table.insert(p.chestTools, {
		uid = instanceHex16(),
		id = ct.id, name = ct.name, family = ct.family,
		rarity = ct.rarity or ct.rarityId,
		rarityId = ct.rarity or ct.rarityId,
		temperRolls = 0,
	})`);

one(`		table.insert(p.relics, { id = r.id, found = os.time() })`,
    `		table.insert(p.relics, { uid = instanceHex16(), id = r.id, found = os.time() })`);

// ---- 3. my own gear id was collision-prone: same second + same roll repeats ----
one(`			local id = "g" .. tostring(os.time()) .. tostring(rng:NextInteger(1000, 9999))`,
    `			local id = instanceHex16()`);

fs.writeFileSync(MS, crlf ? s.split("\n").join("\r\n") : s);
console.log("uid stamping added: on-load backfill + chestTools/relics at mint, gear id fixed");
