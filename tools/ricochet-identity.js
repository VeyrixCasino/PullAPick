// Give ricochet a job nothing else in the game does. Owner, 2026-10-05:
// "rn ricochet is kinda ass now too, we need to find something to do to switch
// that (i swear we had more aoe things, if not make them bcuz i dont like this
// new shiity echo clone)".
//
// The echo clone is mine. On 2026-10-04 I made ricochet reroll the other procs
// on the block it landed on, which is what Dig.echoAt already does -- and echo
// is half-retired anyway (MineStats calls it "Legacy: paid out as Swing Rate"
// while the mechanic still fires). Two procs doing one job, one of them dying.
//
// WHAT RICOCHET IS NOW: the only proc that comes BACK.
//
//   blast     spreads to all six neighbours
//   zap       wanders away, up to sixteen blocks
//   echo      one full-power hit on a neighbour, which then rolls its own
//   ricochet  one hit on a neighbour, and the bounce returns to the block you
//             were actually swinging at
//
// Every other proc moves damage AWAY from your target. That is wasteful when
// the thing you want is the ore in front of you -- you are paying for splash
// onto dirt you did not aim at. Ricochet is the one that concentrates: it is
// worth taking precisely when the block you are hitting is the valuable one.
//
// That makes it a single-target proc in a list of clearing procs, which is a
// build identity rather than a damage number, and it needs no new stat.
const fs = require("fs"), path = require("path");
const P = path.join(__dirname, "..", "src/ServerScriptService/Mine/MineServer.server.luau");
const raw = fs.readFileSync(P, "utf8");
const crlf = raw.indexOf("\r\n") >= 0;
let s = raw.split("\r\n").join("\n");
function one(old, nw) {
  const n = s.split(old).length - 1;
  if (n !== 1) throw new Error("expected 1, got " + n + " :: " + old.slice(0, 60));
  s = s.replace(old, nw);
}

one(`	--[[
		RICOCHET: breaking a block jumps the hit to ONE block beside it, once.

		Deliberately not a chain. swingNeighbour is called directly rather than
		through anything that re-enters procsAt, so the block it lands on rolls
		nothing of its own -- "no chain reactions" is enforced by the call, not
		by a counter that could be raised later.

		Break-only, like Blast: a ricochet off a block that survived the swing
		would fire on every tick of a long dig.
	]]`,
`	--[[
		RICOCHET: the hit jumps to one block beside it AND BOUNCES BACK.

		This is the only proc that returns. Blast spreads to six neighbours, zap
		wanders up to sixteen blocks away, echo lands a full hit on a neighbour
		which then rolls its own procs -- all three move damage AWAY from what
		you are aiming at, which is waste when the valuable block is the one in
		front of you.

		Ricochet concentrates instead: one hit out, one hit back into the
		original block. It is the proc you take when you care about the ore you
		are swinging at rather than the dirt around it, and that is a build
		identity rather than a damage number.

		It briefly rerolled the other procs where it landed, which made it a
		copy of Dig.echoAt -- and echo is already being wound down (MineStats:
		"Legacy: paid out as Swing Rate"). Two procs doing one job is worse than
		a weak proc.

		Still break-only, like Blast: a ricochet off a block that survived the
		swing would fire on every tick of a long dig. Still not a chain: the
		return hit goes through swingNeighbour, which re-enters nothing.
	]]`);

// Replace the reroll tail with the bounce-back.
one(`				pcall(swingNeighbour, plr, hit, ricDmg, p)
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
				Dig.RICO_LOCK[plr.UserId] = nil`,
`				pcall(swingNeighbour, plr, hit, ricDmg, p)
				--[[
					AND BACK.

					The return lands on the block that was swung at. It has
					already broken -- this branch is break-only -- so the bounce
					goes to whatever is standing there now, which on a deep seam
					is the next block the generator has pushed up into the cell.
					When the cell is empty the bounce is simply lost, which is
					the honest outcome: you cleared what you were aiming at.
				]]
				local home = cells[keyOf(zone.id, cx, cy, cz)]
				if home and typeof(home) == "Instance" and home.Parent
					and not Dig.PROC_SKIP[home:GetAttribute("Kind")] then
					net:FireClient(plr, "loot", { text = "RICOCHET",
						color = Color3.fromRGB(140, 220, 255), pos = home.Position })
					pcall(swingNeighbour, plr, home, ricDmg, p)
				end`);

// The lock is no longer needed: nothing re-enters procsAt from here.
one(`		local ric = math.min(1, tonumber(b.ricochet) or 0)
		if Dig.RICO_LOCK[plr.UserId] then
			ric = 0   -- already inside a ricochet's reroll; never chain
		end`,
`		-- Clamped like blast: one jump out and one back, so a value over 1.0 is
		-- a boolean rather than a rate.
		local ric = math.min(1, tonumber(b.ricochet) or 0)`);

one(`-- Set for the moment a ricochet is rerolling procs on the block it landed on,
-- so that block cannot ricochet again. One jump, never a chain.
Dig.RICO_LOCK = {}

Dig.QUAKE = {}`, `Dig.QUAKE = {}`);

fs.writeFileSync(P, crlf ? s.split("\n").join("\r\n") : s);
console.log("ricochet now bounces back into the block you swung at; the echo clone is gone");
