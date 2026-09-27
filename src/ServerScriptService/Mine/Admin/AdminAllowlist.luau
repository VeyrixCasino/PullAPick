--[[
	ADMIN ALLOWLIST — Dig for Cards

	WHERE TO ADD ADMINS:
	  Edit ADMIN_USER_IDS below. Use numeric UserIds ONLY.
	  Never use DisplayName / Username for authorization.

	SECURITY:
	  This ModuleScript lives under ServerScriptService.Mine.Admin.
	  Clients cannot require() it. Do NOT move it to ReplicatedStorage.
	  Chat commands and the panel both re-check Allowlist.isAdmin(UserId).

	Seeded with place CreatorId (game.CreatorId) from Studio.
]]

local ADMIN_USER_IDS = {
	465369561, -- place owner / CreatorId (livinghell07)
	-- Add more numeric UserIds here:
	-- 123456789,
}

local allow = {}
for _, id in ipairs(ADMIN_USER_IDS) do
	local n = tonumber(id)
	if n then
		allow[n] = true
	end
end

local AdminAllowlist = {}

function AdminAllowlist.isAdmin(userId)
	local n = tonumber(userId)
	return n ~= nil and allow[n] == true
end

return AdminAllowlist
