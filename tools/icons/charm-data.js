// Reads the REAL charm roster out of MineCharms.luau, plus each ore's colour out
// of MineConfig.luau.
//
// It runs the module rather than re-deriving the shape assignment in JS. That
// matters: the icon for `stone_charm` has to show the shape MineCharms actually
// gave it, and a second copy of the indexing here would silently drift the first
// time a stride changes. Same stub trick tools/verify/charms.js uses.
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const SHARED = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared");
const LUAU = path.join(ROOT, ".luau-bin/luau");

const BANDS = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic"];

function readRoster() {
  const cfg = fs.readFileSync(path.join(SHARED, "MineConfig.luau"), "utf8");
  // id, name, tier and the authored Color3 on the same row.
  const ores = [...cfg.matchAll(
    /\{ id = "(\w+)", name = "([^"]+)", tier = (\d+),[^\n]*?color = Color3\.fromRGB\((\d+), (\d+), (\d+)\)/g
  )].map((m) => ({
    id: m[1], name: m[2], tier: Number(m[3]),
    rgb: [Number(m[4]), Number(m[5]), Number(m[6])],
  }));
  const cuts = [...cfg.matchAll(/\{ upTo = (\d+), lo = \d+, hi = \d+ \}/g)].map((m) => Number(m[1]));
  if (!ores.length) throw new Error("could not read ore rows (id/name/tier/color) from MineConfig");
  if (cuts.length !== BANDS.length) throw new Error(`expected ${BANDS.length} band cutoffs, got ${cuts.length}`);
  const bandFor = (tier) => {
    for (let i = 0; i < cuts.length; i++) if (tier <= cuts[i]) return [BANDS[i], i + 1];
    return [BANDS[BANDS.length - 1], BANDS.length];
  };
  return { ores, bandFor };
}

// Run MineCharms for real and have it print its own roster.
function readCharms(ores, bandFor) {
  if (!fs.existsSync(LUAU)) {
    throw new Error("luau not present (.luau-bin/luau) — run tools/verify/syntax.sh first");
  }
  const charms = fs.readFileSync(path.join(SHARED, "MineCharms.luau"), "utf8");
  const oreRows = ores.map((o) => {
    const [band, bandIndex] = bandFor(o.tier);
    return `\t{ id = "${o.id}", name = "${o.name}", tier = ${o.tier}, band = "${band}", bandIndex = ${bandIndex}, homeHp = 20 },`;
  }).join("\n");

  const src = `
Color3 = { fromRGB = function() return {} end, fromHSV = function() return {} end }
Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function(_, k) return { Name = k } end }) end })
Random = { new = function() return { NextNumber = function() return 0.5 end, NextInteger = function(_, a) return a end } end }
local S = {
	ORE_COUNT = ${ores.length},
	ORE_BAND_ORDER = { ${BANDS.map((b) => `"${b}"`).join(", ")} },
	ZONES = { {id="z1"},{id="z2"},{id="z3"},{id="z4"},{id="z5"},{id="z6"},{id="z7"},{id="z8"},{id="z9"},{id="z10"},{id="z11"} },
	ORES = {
${oreRows}
	},
}
function S.zoneIndex(id) for i, z in ipairs(S.ZONES) do if z.id == id then return i end end return 1 end
local M = { MineConfig = S }
script = { Name = "MineCharms", Parent = { WaitForChild = function(_, n) return { Name = n } end } }
function require(t) local n = type(t) == "table" and t.Name or tostring(t) return M[n] end
local C = (function()
${charms}
end)()
for _, d in ipairs(C.LIST) do
	if d.source == "ore" then
		print(table.concat({ d.id, d.oreId, d.variant, d.shape, d.band, d.bandIndex, d.name }, "\\t"))
	end
end
`;
  const tmp = path.join(require("os").tmpdir(), `charm-data-${process.pid}.luau`);
  fs.writeFileSync(tmp, src);
  try {
    const out = execFileSync(LUAU, [tmp], { encoding: "utf8", maxBuffer: 1 << 24 });
    return out.trim().split("\n").filter(Boolean).map((line) => {
      const [id, oreId, variant, shape, band, bandIndex, name] = line.split("\t");
      return { id, oreId, variant: Number(variant), shape, band, bandIndex: Number(bandIndex), name };
    });
  } finally {
    fs.unlinkSync(tmp);
  }
}

function load() {
  const { ores, bandFor } = readRoster();
  const byOre = new Map(ores.map((o) => [o.id, o]));
  const charms = readCharms(ores, bandFor).map((c) => {
    const ore = byOre.get(c.oreId);
    if (!ore) throw new Error(`charm ${c.id} names ore ${c.oreId}, which is not in the roster`);
    return { ...c, rgb: ore.rgb, oreName: ore.name, tier: ore.tier };
  });
  return { ores, charms, BANDS };
}

module.exports = { load, BANDS };
