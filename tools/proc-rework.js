// Three proc changes, owner 2026-10-04.
//
// RICOCHET -- it rerolls the other procs on the block it lands on. Today it
// calls swingNeighbour, which deliberately re-enters nothing, so a ricochet is
// one flat hit for 0.60 of a swing and nothing else: "ass if it doesnt reroll
// the all enchantments when it hits". It rerolls blast, zap and earthquake on
// the landing block now -- but never ricochet, so there is still no chain.
//
// EARTHQUAKE -- stacking damage-over-time instead of a flat 5s bleed.
// Everything else in the list is instant and an endgame player breaks 10+
// blocks a second, so 0.60 of a swing spread over five seconds was never worth
// a slot. Now +1 stack a proc, 100 cap, 0.1 of a swing per stack per second
// (10x a swing per second at the ceiling), and the five-second window refreshes
// on every proc so the stack only falls off after five full quiet seconds.
//
// ZAP -- 16 hops, falloff retuned so a big stat buys LENGTH rather than
// certainty. Solved in tools/zap-solve.js: 0.89 puts 250% at 7.7% to reach all
// sixteen (averaging 12.5 blocks) while 100% averages 4.7 and never maxes.
const fs = require("fs"), path = require("path");
const R = path.join(__dirname, "..");
const CFG = path.join(R, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const SRV = path.join(R, "src/ServerScriptService/Mine/MineServer.server.luau");

function load(p) {
  const raw = fs.readFileSync(p, "utf8");
  return { p, crlf: raw.indexOf("\r\n") >= 0, s: raw.split("\r\n").join("\n") };
}
function save(b) { fs.writeFileSync(b.p, b.crlf ? b.s.split("\n").join("\r\n") : b.s); }
function one(b, old, nw) {
  const n = b.s.split(old).length - 1;
  if (n !== 1) throw new Error(path.basename(b.p) + ": expected 1, got " + n + " :: " + old.slice(0, 55));
  b.s = b.s.replace(old, nw);
}

// ----------------------------------------------------------------- config
const cfg = load(CFG);

one(cfg, `MineConfig.ZAP_MAX_HOPS = 6`, `MineConfig.ZAP_MAX_HOPS = 16`);

one(cfg, `MineConfig.ZAP_FALLOFF = 0.75`,
`--[[
	0.75 -> 0.89, with the cap raised to 16 hops.

	The chain continues while rng < chance, where chance starts at the zap stat
	and is multiplied by this each hop. A stat above 1 therefore buys guaranteed
	EARLY hops, and the falloff decides where certainty ends.

	Solved against the owner's target -- 250% should be borderline -- in
	tools/zap-solve.js:

	    zap 100%   averages  4.7 blocks,  0.000% reach 16
	    zap 150%   averages  8.2 blocks,  0.084% reach 16
	    zap 250%   averages 12.5 blocks,  7.7%   reach 16
	    zap 400%   averages 16.0 blocks,   68%   reach 16

	At 0.75 even 400% reached sixteen essentially never, so the hop cap did all
	the work and the stat bought nothing past the first few hops.
]]
MineConfig.ZAP_FALLOFF = 0.89`);

one(cfg, `MineConfig.EARTHQUAKE_SEC = 5`,
`--[[
	EARTHQUAKE STACKS. Owner, 2026-10-04.

	It was a flat bleed on up to five blocks for five seconds, 0.60 of one swing
	in total. Everything else in the proc list is instant and an endgame player
	breaks ten or more blocks a second, so a trickle that small was never worth
	a slot.

	It accumulates now: every proc adds a stack and refreshes the window, and
	the stack only falls off after EARTHQUAKE_SEC seconds with no quake at all.
	At the cap that is QUAKE_STACK_SHARE x QUAKE_MAX_STACKS = 10x a swing per
	second -- the one proc that pays for sustained digging rather than a lucky
	hit.
]]
MineConfig.EARTHQUAKE_SEC = 5
MineConfig.QUAKE_STACK_SHARE = 0.1   -- of one swing, per stack, per second
MineConfig.QUAKE_MAX_STACKS = 100    -- 10x a swing per second at the ceiling`);

one(cfg, `	quake = 0.12,`,
`	-- Superseded by the stack model, which prices a quake as
	-- QUAKE_STACK_SHARE per stack per second. Kept so procDamage("quake")
	-- still answers for any caller that has not moved across.
	quake = 0.12,`);
save(cfg);

// ----------------------------------------------------------------- server
const srv = load(SRV);

// A lock, beside the other Dig state, so the landing block cannot ricochet on.
one(srv, `Dig.QUAKE = {}`,
`-- Set for the moment a ricochet is rerolling procs on the block it landed on,
-- so that block cannot ricochet again. One jump, never a chain.
Dig.RICO_LOCK = {}

Dig.QUAKE = {}`);

// opts has to carry the cell coords: procsAt takes them, and a block does not
// know its own (there is no Cx attribute on a part).
one(srv, `			local opts = {}
			for _, d in ipairs(Dig.FACE6) do
				local other = cells[keyOf(zone.id, cx + d[1], cy + d[2], cz + d[3])]
				if other and typeof(other) == "Instance" and other.Parent
					and not Dig.PROC_SKIP[other:GetAttribute("Kind")] then
					table.insert(opts, other)
				end
			end`,
`			local opts = {}
			for _, d in ipairs(Dig.FACE6) do
				local nx, ny, nz = cx + d[1], cy + d[2], cz + d[3]
				local other = cells[keyOf(zone.id, nx, ny, nz)]
				if other and typeof(other) == "Instance" and other.Parent
					and not Dig.PROC_SKIP[other:GetAttribute("Kind")] then
					-- Coords travel with the part: procsAt needs the cell, and a
					-- block carries no Cx/Cy/Cz attribute to read them back off.
					table.insert(opts, { part = other, cx = nx, cy = ny, cz = nz })
				end
			end`);

one(srv, `			if #opts > 0 then
				local hit = opts[rng:NextInteger(1, #opts)]
				net:FireClient(plr, "loot", { text = "RICOCHET",
					color = Color3.fromRGB(140, 220, 255), pos = hit.Position })
				pcall(swingNeighbour, plr, hit, C.procDamage(dmg, "ricochet", pp), p)
			end`,
`			if #opts > 0 then
				local pick = opts[rng:NextInteger(1, #opts)]
				local hit = pick.part
				local ricDmg = C.procDamage(dmg, "ricochet", pp)
				net:FireClient(plr, "loot", { text = "RICOCHET",
					color = Color3.fromRGB(140, 220, 255), pos = hit.Position })
				pcall(swingNeighbour, plr, hit, ricDmg, p)
				--[[
					AND THE LANDING BLOCK ROLLS YOUR OTHER PROCS.

					Owner, 2026-10-04: a ricochet that only lands one flat hit is
					the weakest slot in the game. Blast, zap and earthquake all
					get a roll where it lands, so taking ricochet is worth
					something to every other proc on the build.

					Ricochet itself is locked out for the duration, so the second
					block cannot ricochet again: one jump, carrying the rest of
					the kit with it. broke=false, because the block was not
					necessarily destroyed by the ricochet -- the break-only procs
					decide that for themselves.
				]]
				Dig.RICO_LOCK[plr.UserId] = true
				pcall(Dig.procsAt, plr, p, b, zone, cells, hit,
					pick.cx, pick.cy, pick.cz, ricDmg,
					hit:GetAttribute("Kind"), false, false)
				Dig.RICO_LOCK[plr.UserId] = nil
			end`);

one(srv, `		local ric = tonumber(b.ricochet) or 0
		if ric > 0 and rng:NextNumber() < ric then`,
`		local ric = tonumber(b.ricochet) or 0
		if Dig.RICO_LOCK[plr.UserId] then
			ric = 0   -- already inside a ricochet's reroll; never chain
		end
		if ric > 0 and rng:NextNumber() < ric then`);
save(srv);
console.log("zap 16 @ 0.89 | ricochet rerolls the other procs | quake stack constants in");
