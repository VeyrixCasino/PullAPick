-- MineFounders: Founders Pack membership (credits or gamepass).
-- Kept out of MineServer so the main script stays under Luau's local-register cap.
local MineFounders = {}

function MineFounders.isMember(p)
	return (p and type(p.vip) == "table" and p.vip.since ~= nil) or false
end

function MineFounders.creditsPrice(C, Packs)
	return tonumber(C and C.FOUNDERS_CREDITS)
		or tonumber(Packs and Packs.VIP_PRICE)
		or 799
end

function MineFounders.robuxPrice(C, Packs)
	return tonumber(C and C.FOUNDERS_ROBUX)
		or tonumber(Packs and Packs.VIP_ROBUX)
		or 799
end

function MineFounders.gamePassId(C)
	return tonumber(C and C.FOUNDERS_GAMEPASS_ID) or 1982786367
end

--[[
	Grant Founders once. `seatsRef` is { left = n } so the caller keeps seat state.
	`grantScrolls(p, id, n)` and optional Vfx require come from the caller env.
]]
function MineFounders.grant(p, plr, source, opts)
	opts = opts or {}
	if MineFounders.isMember(p) then
		return false
	end
	p.vip = { since = os.time(), source = source or "credits" }
	if opts.seatsRef then
		opts.seatsRef.left = math.max(0, (opts.seatsRef.left or 0) - 1)
	end
	if opts.grantScrolls then
		opts.grantScrolls(p, "white", 1)
	end
	pcall(function()
		local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
		local Vfx = require(shared:WaitForChild("MineVfx"))
		p.vfx = p.vfx or {}
		if Vfx.BY_ID and Vfx.BY_ID.tag_founder then
			p.vfx.tag_founder = true
		end
	end)
	if plr and opts.toast then
		opts.toast(plr, "Founders Pack active -- White Scroll, Founder Tag, +5% luck (stated)")
	end
	return true
end

return MineFounders
