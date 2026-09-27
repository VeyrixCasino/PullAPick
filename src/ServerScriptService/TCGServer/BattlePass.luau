--!strict
-- AFK stub: pass XP is best-effort; never wipe the battle-pass store.
local BattlePass = {}
function BattlePass.addXp(_player, _amount)
	return true
end
return BattlePass
