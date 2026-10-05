// Clamp the proc chances that cannot mean anything above 1.0. Owner, 2026-10-05.
//
// The roll everywhere is `rng:NextNumber() < chance` with no ceiling, so a
// chance of 2.04 does not mean 204% -- it means EVERY swing, forever, and every
// point past the first 100 is silently discarded by the comparison.
//
// That is why blast is not an endgame build. 156 of the 504 pets in the game
// roll blastChance, so three stacked pets come to 204% before gear, charms,
// runes, skills, tempers or cards are considered. A player who never thought
// about procs is already at the ceiling, and a player who deliberately builds
// for them gets nothing at all for it.
//
// ZAP IS DELIBERATELY NOT CLAMPED. Owner: "zap over 100 CAN make sense because
// its a chance decay". Its loop multiplies the chance by ZAP_FALLOFF each hop,
// so a stat above 1.0 is not wasted -- it buys guaranteed EARLY hops and pushes
// the point where the chain starts to break. That is a real curve, and the only
// one of the four that reads a value above 1.0 as more than a boolean.
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

// ---- blast ---------------------------------------------------------------
one(`		local chance = forceBlast and 1 or (b.blastChance or 0)
		if chance > 0 and rng:NextNumber() < chance then`,
`		--[[
			CLAMPED. Blast fires once or not at all, so anything over 1.0 was
			discarded by the comparison below -- 156 of 504 pets roll this stat
			and three of them already total 204%, which is why blast reads as
			ambient rather than as a build.

			Clamping does not nerf anyone who was at 100%: it makes the points
			ABOVE 100% visible as waste, so the curve can be re-cut to cost
			something.
		]]
		local chance = forceBlast and 1 or math.min(1, b.blastChance or 0)
		if chance > 0 and rng:NextNumber() < chance then`);

// ---- ricochet ------------------------------------------------------------
one(`		local ric = tonumber(b.ricochet) or 0
		if Dig.RICO_LOCK[plr.UserId] then`,
`		-- Clamped for the same reason as blast: one jump, so over 1.0 is a
		-- boolean rather than a rate.
		local ric = math.min(1, tonumber(b.ricochet) or 0)
		if Dig.RICO_LOCK[plr.UserId] then`);

// ---- earthquake ----------------------------------------------------------
one(`		local eq = tonumber(b.earthquake) or 0`,
`		-- Clamped: a quake either starts on this swing or it does not. The
		-- STACK is where the depth lives now, not the roll.
		local eq = math.min(1, tonumber(b.earthquake) or 0)`);

// ---- zap: say why it is the exception, at the roll ------------------------
one(`	local startZap = b.zap or 0
	if startZap <= 0 or rng:NextNumber() >= startZap then`,
`	--[[
		NOT clamped, and that is the point. Owner, 2026-10-05: "zap over 100 CAN
		make sense because its a chance decay".

		\`chance\` is multiplied by ZAP_FALLOFF every hop, so a stat above 1.0 is
		not thrown away -- it buys guaranteed early hops and moves the point
		where the chain starts failing. Zap is the only one of the four where a
		value over 1.0 is a curve rather than a boolean.
	]]
	local startZap = b.zap or 0
	if startZap <= 0 or rng:NextNumber() >= startZap then`);

fs.writeFileSync(P, crlf ? s.split("\n").join("\r\n") : s);
console.log("clamped blast, ricochet and earthquake at 1.0; zap left uncapped on purpose");
