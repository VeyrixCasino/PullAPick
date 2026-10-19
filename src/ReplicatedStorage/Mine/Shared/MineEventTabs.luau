--[[
	MineEventTabs -- which events the Events tab shows, which one it opens on,
	and what each event's card says about claiming it.

	Owner, 2026-10-19 (wiki/open-questions.md §0e): the Events tab shows BOTH
	events. It used to show the first event with an open window, and Event
	Horizon is open all season, so it always hid the Candy Crypt -- and the card
	it did show read Event Horizon's claim flag and said "Claim Event Horizon"
	whichever event it was for.

	PURE ON PURPOSE. Everything here reads the snapshot (and MineConfig.EVENTS)
	it is handed and requires nothing at load, so tools/verify/crypt-ui.js runs
	it offline against the real config and MineEventsView draws exactly what it
	returns. The server decides; this only reads what the server said:

	  limitedOpen   { [zoneId] = open } -- every limited zone's own window
	  crypt         the Candy Crypt's block (MineCryptRules.stateFor): owned,
	                window { opensAt, closesAt, open, ended }
	  bigbangOwned / hallowOwned   the claim flags (MineConfig.EVENTS ownedFlag)
]]
local M = {}

-- The screen the owner calls Planets (not Zones) is where an event mine is
-- entered from.
M.CLAIMED_TEXT = "Owned — enter from Planets"

local function crypt(state)
	local cr = type(state) == "table" and state.crypt or nil
	return type(cr) == "table" and cr or nil
end

--[[
	Is this event's window open? The server's own answer first: the snapshot's
	limitedOpen (every limited zone, by its own window), then the Crypt's own
	window block. MineConfig.limitedActive is the last resort only: on a client
	Event Horizon's season clock is not the server's.
]]
function M.isOpen(ev, state, C)
	local zid = type(ev) == "table" and ev.zoneId or nil
	if not zid then
		return false
	end
	local lo = type(state) == "table" and state.limitedOpen or nil
	if type(lo) == "table" and lo[zid] ~= nil then
		return lo[zid] == true
	end
	local cr = crypt(state)
	if zid == "hallow" and cr and type(cr.window) == "table" then
		return cr.window.open == true
	end
	if C and C.limitedActive then
		return C.limitedActive(zid) == true
	end
	return false
end

-- Has the event ENDED (not merely "not open yet")? Only the Crypt's window
-- block says so.
function M.hasEnded(ev, state)
	local cr = crypt(state)
	if type(ev) == "table" and ev.zoneId == "hallow" and cr and type(cr.window) == "table" then
		return cr.window.ended == true
	end
	return false
end

--[[
	Has the player claimed it? EACH EVENT ITS OWN FLAG. The Crypt reads its own
	block (crypt.owned, which is p.hallowOwned), then the top-level hallowOwned;
	never bigbangOwned. Any other event reads its MineConfig.EVENTS ownedFlag.
]]
function M.owned(ev, state)
	if type(ev) ~= "table" or type(state) ~= "table" then
		return false
	end
	if ev.zoneId == "hallow" then
		local cr = crypt(state)
		if cr and cr.owned ~= nil then
			return cr.owned == true
		end
		return state.hallowOwned == true
	end
	local flag = ev.ownedFlag
	return (flag ~= nil and state[flag] == true) or false
end

--[[
	The events to show, in MineConfig.EVENTS order: every one whose window is
	open -- so the Crypt shows while Event Horizon is open too.

	(After the Crypt ends, its tools' main-world switch will need a card for
	a player who claimed it; that screen waits for the Crypt's next tools API,
	owner's scope change 2026-10-19, so for now a closed event is not shown.)
]]
function M.shown(C, state)
	local out = {}
	for _, ev in ipairs((C and C.EVENTS) or {}) do
		local open = M.isOpen(ev, state, C)
		if open then
			table.insert(out, {
				ev = ev, open = open, owned = M.owned(ev, state), ended = M.hasEnded(ev, state),
			})
		end
	end
	return out
end

--[[
	Which event the tab opens on: the one whose zone the player is standing in,
	else the Crypt while it is open, else the first shown. Returns an event id
	(MineConfig.EVENTS `id`), or nil when nothing is shown.
]]
function M.defaultId(list, state)
	local zid = type(state) == "table" and state.zoneId or nil
	for _, row in ipairs(list or {}) do
		if zid ~= nil and row.ev.zoneId == zid then
			return row.ev.id
		end
	end
	for _, row in ipairs(list or {}) do
		if row.ev.zoneId == "hallow" and row.open then
			return row.ev.id
		end
	end
	return list and list[1] and list[1].ev.id or nil
end

-- The row for an event id in a shown list, or nil.
function M.find(list, id)
	for _, row in ipairs(list or {}) do
		if row.ev.id == id then
			return row
		end
	end
	return nil
end

--[[
	The claim button: its words, and whether pressing it claims (buyZone) --
	the event's OWN name, so the Crypt's never says "Event Horizon".
	Owned: "Owned — enter from Planets", and pressing it opens Planets.
]]
function M.claim(ev, state, open)
	if M.owned(ev, state) then
		return M.CLAIMED_TEXT, false
	end
	if open then
		return "Claim " .. tostring((type(ev) == "table" and ev.name) or "event") .. "  \u{00B7}  FREE", true
	end
	if M.hasEnded(ev, state) then
		return "Event ended", false
	end
	return "Not open yet", false
end

--[[
	What the (i) on an event's card says: its own first-entry notice when it
	has one (MineCryptRules.NOTICES -- the same text the pop-up shows), else its
	blurb. NOT MineCryptRules.noticeFor for every event: that falls back to the
	Crypt's notice, which promises Event Horizon's tools a main-world life the
	owner did not give them ("Crypt only for now").
]]
function M.notice(ev, Rules)
	local zid = type(ev) == "table" and ev.zoneId or nil
	local own = Rules and type(Rules.NOTICES) == "table" and zid and Rules.NOTICES[zid] or nil
	if own and Rules.noticeFor then
		local n = Rules.noticeFor(zid)
		return { title = tostring(n.title or ""), text = tostring(n.text or "") }
	end
	return {
		title = tostring((type(ev) == "table" and ev.name) or "Event"),
		text = tostring((type(ev) == "table" and ev.blurb) or ""),
	}
end

-- "19d 4h", "3h 12m", "12m 05s": coarse far out, finer close in.
function M.clock(secs)
	secs = math.max(0, math.floor(tonumber(secs) or 0))
	local d = math.floor(secs / 86400)
	local h = math.floor((secs % 86400) / 3600)
	local m = math.floor((secs % 3600) / 60)
	if d >= 1 then
		return string.format("%dd %dh", d, h)
	end
	if h >= 1 then
		return string.format("%dh %dm", h, m)
	end
	return string.format("%dm %02ds", m, secs % 60)
end

--[[
	The Crypt's window as a line, against `now` (the server's clock on a
	client: workspace:GetServerTimeNow()). Returns the line and the unix time
	it counts to (for a local date beside it), or nil when there is none.
]]
function M.cryptWindowLine(state, now)
	local cr = crypt(state)
	local w = cr and type(cr.window) == "table" and cr.window or nil
	if not w then
		return "", nil
	end
	now = tonumber(now) or 0
	local opens, closes = tonumber(w.opensAt), tonumber(w.closesAt)
	if w.ended then
		-- (What the Crypt's tools do after the event is part of the redesign
		-- still to come, so the line promises nothing about them.)
		return "Event ended", closes
	end
	if opens and now < opens then
		return "Opens in " .. M.clock(opens - now), opens
	end
	if closes then
		return "Closes in " .. M.clock(closes - now), closes
	end
	return w.open and "Open now" or "", nil
end

--[[
	A unix time as the PLAYER's local date and time ("Sat, Nov 7, 11:00 PM").
	DateTime is Roblox's; offline (the checks) there is no DateTime, and the
	fallback is os.date, which a Roblox client also reads in local time.
]]
function M.localDate(unix)
	unix = tonumber(unix)
	if not unix then
		return ""
	end
	local ok, s = pcall(function()
		return DateTime.fromUnixTimestamp(math.floor(unix)):FormatLocalTime("ddd, MMM D, h:mm A", "en-us")
	end)
	if ok and type(s) == "string" and s ~= "" then
		return s
	end
	local ok2, s2 = pcall(os.date, "%a %d %b %H:%M", math.floor(unix))
	return (ok2 and type(s2) == "string") and s2 or ""
end

return M
