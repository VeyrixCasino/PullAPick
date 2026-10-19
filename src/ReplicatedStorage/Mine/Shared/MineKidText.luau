--[[
	MineKidText -- words into icons and numbers, for the toasts.

	The kid-friendly pass (owner, 2026-10-12, resumed 2026-10-19: "icons with
	big numbers, 1-3 words"). The server sends about 285 different toasts, in
	words: "Quest done - 800 Coins", "Scrapped pack for 50 gems". Rewriting each
	one would scatter the style across the server, so the client runs every
	toast through toast() instead:

	  "Quest done - 800 Coins  +  60 Gems"  ->  "✅ Quest done!  💰 800  +  💎 60"
	  "Gift: 2 Stardust"                    ->  "🎁 ✨ 2"

	Only an amount directly followed by its currency word changes, so "Gem
	Shop", "Gemfinder" and "you have 200" stay as they are. Pure: checked
	offline by tools/verify/kid-text.js.
]]
local M = {}

-- Same icons as MineQuests.REWARD_ICON, so a reward reads alike everywhere.
M.MONEY = {
	{ word = "[Cc]oins?", icon = "💰" },
	{ word = "[Gg]ems?", icon = "💎" },
	{ word = "[Ss]tardust", icon = "✨" },
	{ word = "[Cc]redits?", icon = "💵" },
}

-- A toast's opening words, swapped for an icon and a shout.
M.LEADS = {
	{ from = "^Quest done %- ", to = "✅ Quest done!  " },
	{ from = "^Milestone %- ", to = "🏆 Milestone!  " },
	{ from = "^Gift: ", to = "🎁 " },
}

-- Words anywhere in a toast that have an icon of their own.
M.WORDS = {
	{ from = "Unlocks ", to = "🔓 " },
}

-- An amount: 800, 1,000, 12.5K, 3M.
local AMOUNT = "(%d[%d,%.]*[KkMB]?)"

function M.toast(s)
	if type(s) ~= "string" or s == "" then
		return s
	end
	for _, lead in ipairs(M.LEADS) do
		s = s:gsub(lead.from, lead.to)
	end
	for _, w in ipairs(M.WORDS) do
		s = s:gsub(w.from, w.to)
	end
	for _, m in ipairs(M.MONEY) do
		-- %f[%A] ends the word, so "5 Gemstones" is left alone.
		s = s:gsub(AMOUNT .. " " .. m.word .. "%f[%A]", m.icon .. " %1")
	end
	return s
end

return M
