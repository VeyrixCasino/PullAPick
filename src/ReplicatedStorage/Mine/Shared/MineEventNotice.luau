--[[
	MineEventNotice -- the pop-up on a player's FIRST entry to an event mine
	(owner, 2026-10-19; wiki/open-questions.md §0e, "telling players": a pop-up
	on first entry to each event, once, plus the same text behind an (i) on its
	card).

	ONCE, AND NEVER ANNOYING:
	  * It shows when the server says so -- the `eventNotice` push it sends on
	    entering an event-tools-only mine until the player has seen it -- or,
	    as a fallback, when a snapshot finds the player standing in such a mine
	    with its notice unseen (`crypt.noticeSeen`).
	  * It shows at most once a session per event (`shown`), whichever of the
	    two asks first, so a push and a snapshot can never stack it twice.
	  * One button, "Got it": it closes the pop-up and reports the event's zone
	    (the host sends `cryptNoticeSeen { zoneId }`), and the server never
	    asks again. Tapping beside it does nothing, so a stray tap cannot
	    dismiss it unread.
	  * It does not scale in: text never rides a scale animation (house style).

	In the event's own theme (MineTheme.eventTheme), so the Crypt's is Halloween.

	PROPOSED (2026-10-19): the layout and the "Got it" caption's styling; the
	words are MineCryptRules.NOTICE, the owner-approved line.
]]
local N = {}

local shared = script.Parent
local T = require(shared:WaitForChild("MineTheme"))

-- The zone ids a notice exists for, read from MineCryptRules (lazily: the
-- pure check below must not need the rules to load).
local function rules()
	local ok, R = pcall(function()
		return require(shared:WaitForChild("MineCryptRules"))
	end)
	return ok and R or nil
end

--[[
	PURE: should a snapshot show the pop-up for `zoneId`? Only for an event mine
	the snapshot carries notice state for (the Crypt's block: crypt.zoneId),
	only while it is unseen, and never twice in a session (`shown`).
]]
function N.shouldShow(snap, zoneId, shown)
	zoneId = tostring(zoneId or "")
	if zoneId == "" or (type(shown) == "table" and shown[zoneId]) then
		return false
	end
	local cr = type(snap) == "table" and snap.crypt or nil
	if type(cr) ~= "table" or cr.zoneId ~= zoneId then
		return false
	end
	local seen = type(cr.noticeSeen) == "table" and cr.noticeSeen or {}
	return not seen[zoneId]
end

--[[
	mount(parent, opts) -> ctl
	  opts.onSeen(zoneId)   "Got it" was pressed: the host tells the server
	  ctl.show({ zoneId, title, text })   the server's eventNotice push
	  ctl.onSnapshot(snap)  the fallback, cheap enough for every snapshot
	  ctl.isOpen(), ctl.shown (the per-session record)
]]
function N.mount(parent, opts)
	opts = opts or {}
	local UI = require(shared:WaitForChild("MineUI"))
	local ctl = { shown = {} }
	local current = nil

	-- The veil sinks taps so the world behind is not clicked through, and
	-- does nothing else: only "Got it" closes it.
	local veil = UI.new("TextButton", {
		Name = "EventNotice",
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		BackgroundColor3 = T.INK,
		BackgroundTransparency = 0.35,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 300,
	}, parent)
	veil:SetAttribute("MineUIAdopted", true)
	veil:SetAttribute("NoClickSfx", true)
	veil:SetAttribute("ThemeFill", "INK")

	local box = UI.themePanel(veil, nil, UDim2.new(0.86, 0, 0, 330), UDim2.fromScale(0.5, 0.5))
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.ZIndex = 301
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(560, 360) }, box)

	local badge = UI.themeText(box, "", 44, nil, "TEXT")
	badge.TextXAlignment = Enum.TextXAlignment.Center
	badge.Position = UDim2.fromOffset(0, 14)
	badge.Size = UDim2.new(1, 0, 0, 52)
	badge.ZIndex = 302

	local title = UI.themeText(box, "", 26, nil, "GLOW")
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Position = UDim2.fromOffset(20, 70)
	title.Size = UDim2.new(1, -40, 0, 34)
	title.TextWrapped = true
	title.ZIndex = 302
	UI.outlineText(title, 2)
	title.TextColor3 = T.themeFor(nil).GLOW

	local body = UI.themeText(box, "", 18, nil, "TEXT", T.FONT_M)
	body.TextXAlignment = Enum.TextXAlignment.Center
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.Position = UDim2.fromOffset(24, 112)
	body.Size = UDim2.new(1, -48, 0, 120)
	body.ZIndex = 302

	local got, gotL = UI.themeButton(box, "Got it", UDim2.fromOffset(220, 56), UDim2.new(0.5, -110, 1, -76), nil, "go")
	got.ZIndex = 303
	gotL.ZIndex = 304
	gotL.TextSize = 22

	function ctl.isOpen()
		return veil.Visible
	end

	--[[
		Show the pop-up for an event. Returns true when it showed. The session
		record is written BEFORE it shows: whatever asks second -- the push or
		a snapshot -- finds it already shown.
	]]
	function ctl.show(payload)
		if type(payload) ~= "table" then
			return false
		end
		local zid = tostring(payload.zoneId or "")
		if zid == "" or ctl.shown[zid] then
			return false
		end
		ctl.shown[zid] = true
		current = zid
		local theme = UI.applyTheme(veil, T.themeFor(zid))
		title.TextColor3 = theme.GLOW
		badge.Text = (theme.BADGE ~= "" and theme.BADGE) or "⭐"
		title.Text = tostring(payload.title or "")
		body.Text = tostring(payload.text or "")
		veil.Visible = true
		return true
	end

	function ctl.onSnapshot(snap)
		if veil.Visible or type(snap) ~= "table" then
			return
		end
		local zid = snap.zoneId
		if N.shouldShow(snap, zid, ctl.shown) then
			local R = rules()
			local n = R and R.noticeFor and R.noticeFor(zid) or nil
			if n then
				ctl.show({ zoneId = zid, title = n.title, text = n.text })
			end
		end
	end

	got.MouseButton1Click:Connect(function()
		veil.Visible = false
		local zid = current
		current = nil
		if zid and opts.onSeen then
			opts.onSeen(zid)
		end
	end)

	ctl.root = veil
	return ctl
end

return N
