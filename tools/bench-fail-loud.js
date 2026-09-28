// Make the bench fail loudly and partially, instead of silently and totally.
//
// Mounting the bench against a MineConfig that was missing TOOL_MAX_LEVEL threw
// `attempt to compare nil <= number` on the very first row, and two separate
// things then conspired to hide it:
//
//   * MineBenchView builds every row inside one refresh(), so a throw on row one
//     leaves the whole list blank -- not one bad row among good ones.
//   * MineShopView wraps refresh in a bare pcall, which discards the message.
//
// The result was an Upgrade tab that drew nothing, with nothing in the console
// to say why. A nil constant should cost one wrong number, not the panel.
const fs = require("fs"), path = require("path");
const ROOT = path.join(__dirname, "..");
const B = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineBenchView.luau");
const V = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineShopView.luau");

function load(p) {
  const raw = fs.readFileSync(p, "utf8");
  return { raw, crlf: raw.indexOf("\r\n") >= 0, s: raw.split("\r\n").join("\n") };
}
function makeOne(box) {
  return function (old, nw) {
    const n = box.s.split(old).length - 1;
    if (n !== 1) throw new Error("expected 1 match, got " + n + " for: " + old.slice(0, 70));
    box.s = box.s.replace(old, nw);
  };
}

// ---------------------------------------------------------------- MineBenchView
const b = load(B);
const oneB = makeOne(b);

// A cap the module can always compare against.
oneB(`local MineBenchView = {}`,
`local MineBenchView = {}

--[[
	The level cap, with a floor under it.

	Every row compares its level against C.TOOL_MAX_LEVEL. When that arrived nil
	-- which a stale module cache is enough to cause -- the comparison threw on
	the first row and the panel drew nothing at all, which reads exactly like
	"you own no tools". A wrong cap costs one wrong number; a nil one cost the
	whole bench.
]]
local function levelCap(C)
	return tonumber(C.TOOL_MAX_LEVEL) or 1000
end`);

oneB(`		local maxed = level >= C.TOOL_MAX_LEVEL
		local costOre, costDust = C.toolUpgradeCost(tool.tier, level, typeMult)`,
`		local cap = levelCap(C)
		local maxed = level >= cap
		-- Pricing lives in MineConfig and is never recomputed here, but a build
		-- without it must still list what you own rather than blank the panel.
		local costOre, costDust
		if C.toolUpgradeCost then
			costOre, costDust = C.toolUpgradeCost(tool.tier, level, typeMult)
		end`);

oneB(`		label(f, string.format("level %d / %d", level, C.TOOL_MAX_LEVEL), 12,`,
`		label(f, string.format("level %d / %d", level, cap), 12,`);

oneB(`		-- scrap is always available; levelling only when it would succeed
		local recOre, recDust = C.toolRecycle(tool.tier, level, typeMult)`,
`		-- scrap is always available; levelling only when it would succeed
		local recOre, recDust = 0, 0
		if C.toolRecycle then
			recOre, recDust = C.toolRecycle(tool.tier, level, typeMult)
		end`);

oneB(`		button(f, "MAX", GREEN, -168, 48, canOne, function()
			if opts.onUpgrade then opts.onUpgrade(tool.uid, C.TOOL_MAX_LEVEL) end
		end)`,
`		button(f, "MAX", GREEN, -168, 48, canOne, function()
			if opts.onUpgrade then opts.onUpgrade(tool.uid, cap) end
		end)`);

// One bad row must not take the other rows with it.
oneB(`		for i, tool in ipairs(sorted) do
			if type(tool) == "table" and tool.uid then
				row(tool, snapshot, i)
			end
		end`,
`		--[[
			One row per tool, each in its own pcall.

			row() reads pricing out of MineConfig and rarity out of MineTools,
			and a single bad tool -- an unknown typeId, a tier past the end of
			the ore roster -- used to take every other row down with it. A tool
			that cannot be priced is worth reporting, not worth hiding the nine
			tools above it.
		]]
		local broke = 0
		for i, tool in ipairs(sorted) do
			if type(tool) == "table" and tool.uid then
				local ok, err = pcall(row, tool, snapshot, i)
				if not ok then
					broke += 1
					warn("[MineBenchView] row " .. i .. " (" .. tostring(tool.uid) .. "): " .. tostring(err))
				end
			end
		end
		if broke > 0 then
			sub.Text = sub.Text .. "  \\u{00B7}  " .. broke .. " could not be priced"
		end`);

fs.writeFileSync(B, b.crlf ? b.s.split("\n").join("\r\n") : b.s);

// ---------------------------------------------------------------- MineShopView
const v = load(V);
const oneV = makeOne(v);

oneV(`			if benchCtl and benchCtl.refresh then
				pcall(benchCtl.refresh)
			end`,
`			if benchCtl and benchCtl.refresh then
				-- A bare pcall here is what made a thrown row look like an empty
				-- bag. If it fails, say so.
				local okR, errR = pcall(benchCtl.refresh)
				if not okR then
					warn("[MineShopView] bench refresh failed: " .. tostring(errR))
				end
			end`);

fs.writeFileSync(V, v.crlf ? v.s.split("\n").join("\r\n") : v.s);
console.log("bench degrades per-row and reports why, instead of blanking silently");
