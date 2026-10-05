// Earthquake becomes a stacking bleed. Owner, 2026-10-04.
//
// WAS: a block starts shaking, bleeds a fixed per-tick figure for five seconds,
// up to five blocks at once, and a block already shaking ignores further procs.
// Total value 0.60 of one swing. Against instant procs and an endgame player
// breaking ten blocks a second, never worth a slot.
//
// IS: stacks live on the PLAYER, not the block. Every proc adds one (cap 100)
// and refreshes a five-second window; the stacks only clear after five full
// seconds with no quake. Each tick every shaking block takes
// stacks x QUAKE_STACK_SHARE x swing -- 10x a swing per second at the ceiling.
//
// Keeping the per-block set matters: it is what the client reads to shake a
// block, and what stops the damage applying to rubble. What changes is that the
// per-block entry no longer carries its own frozen damage figure; the stack
// count does, so a quake that has been fed keeps paying on blocks that were
// already shaking.
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

// ---- the per-player stack bank -------------------------------------------
one(`Dig.QUAKE = {}`,
`Dig.QUAKE = {}

--[[
	The quake stack bank, per player.

	  n      how many stacks are up, capped at QUAKE_MAX_STACKS
	  dies   when the whole bank expires, pushed out by every fresh proc
	  swing  the player's swing damage as of the last proc, so the bleed
	         tracks the tool they are actually holding

	Separate from Dig.QUAKE, which stays a set of the blocks currently shaking:
	that is what the client reads and what keeps the damage off rubble.
]]
Dig.QUAKE_STACK = {}`);

// ---- adding a stack -------------------------------------------------------
one(`	-- Cannot stack: already shaking, so nothing happens.
	if mine[part] then
		return false
	end`,
`	--[[
		A proc always feeds the bank, even on a block already shaking.

		The old code returned early here, which is what made a second quake on
		the same block worth nothing. The STACK is the reward now; the block set
		below is only about which blocks are visibly shaking.
	]]
	local bank = Dig.QUAKE_STACK[uid]
	if not bank or os.clock() >= (bank.dies or 0) then
		bank = { n = 0 }
		Dig.QUAKE_STACK[uid] = bank
	end
	bank.n = math.min(bank.n + 1, math.max(1, math.floor(tonumber(C.QUAKE_MAX_STACKS) or 100)))
	bank.dies = os.clock() + (tonumber(C.EARTHQUAKE_SEC) or 5)
	bank.swing = math.max(1, math.floor(tonumber(dmg) or 1))

	if mine[part] then
		-- Already shaking: the stack above is the whole effect.
		return true
	end`);

// ---- the per-block entry no longer freezes a damage figure ----------------
one(`	mine[part] = {
		dmg = math.max(1, math.floor(tonumber(dmg) or 1)),
		dies = os.clock() + (tonumber(C.EARTHQUAKE_SEC) or 5),
	}`,
`	-- No frozen dmg: the bank decides what a tick is worth, so a block that
	-- started shaking early keeps up with a stack that has since grown.
	mine[part] = { dies = os.clock() + (tonumber(C.EARTHQUAKE_SEC) or 5) }`);

// ---- the tick reads the bank ---------------------------------------------
one(`				for part, q in pairs(mine) do
					if not part.Parent or now >= q.dies then
						if part.Parent then
							pcall(function()
								part:SetAttribute("Quaking", nil)
							end)
						end
						mine[part] = nil
					else
						-- q.dmg is already the per-tick figure (C.procDamage at
						-- start time), so this is a straight application.
						pcall(swingNeighbour, plr, part, q.dmg, prof)
					end
				end`,
`				--[[
					One tick is stacks x share x swing, to every shaking block.

					The bank expires as a whole: five seconds with no quake and
					the stack count is gone, which is what stops a player
					banking 100 stacks and carrying them between veins.
				]]
				local bank = Dig.QUAKE_STACK[uid]
				if bank and now >= (bank.dies or 0) then
					Dig.QUAKE_STACK[uid] = nil
					bank = nil
				end
				local share = tonumber(C.QUAKE_STACK_SHARE) or 0.1
				local tick = bank and math.max(1,
					math.floor((bank.swing or 1) * share * (bank.n or 0))) or 0
				for part, q in pairs(mine) do
					if not part.Parent or now >= q.dies then
						if part.Parent then
							pcall(function()
								part:SetAttribute("Quaking", nil)
							end)
						end
						mine[part] = nil
					elseif tick > 0 then
						pcall(swingNeighbour, plr, part, tick, prof)
					end
				end`);

// ---- drop the bank with the player ---------------------------------------
one(`			if not (plr and prof) then
				Dig.QUAKE[uid] = nil`,
`			if not (plr and prof) then
				Dig.QUAKE[uid] = nil
				Dig.QUAKE_STACK[uid] = nil`);

fs.writeFileSync(P, crlf ? s.split("\n").join("\r\n") : s);
console.log("earthquake stacks: +1 a proc, cap 100, 0.1 swing per stack per second, 5s window");
