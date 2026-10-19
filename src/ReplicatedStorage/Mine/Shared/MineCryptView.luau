--[[
	MineCryptView -- the Candy Crypt's card on the Events tab, in the Halloween
	theme (owner's redesign, 2026-10-19; wiki/open-questions.md §0e, "The
	Candy Crypt, redesigned").

	MineEventsView draws the card's head (title, the (i), the window, the claim
	button) for every event the same way; this module draws what only the
	Crypt has. THE SHELL, for now:

	  YOUR CANDY       the balance, beside the rule every player must know
	                   (MineCryptRules.NOTICE: only event tools work here, and
	                   the tools are yours to keep)
	  TRICK-OR-TREAT   OPEN, which sends buyTrickOrTreat at the snapshot's price
	                   (crypt.casePrice), greyed when it cannot be bought

	SCOPE (owner, 2026-10-19, later the same day): the Crypt is being
	redesigned again, so its TOOLS and CHARMS API and the Trick-or-Treat LOOT
	will change. The Crypt tools list (EQUIP, MERGE, the main-world switch), the
	candy-charm crafting and the case's odds sheet and result reveal are NOT
	built here; they are redone against the new API. The odds sheet's place is
	kept: see CryptView.mountCaseOdds and the "OddsSlot" frame below.

	THE VIEW OWNS NO RULES. It renders the snapshot's `crypt` block and reports
	taps; the host turns OPEN into buyTrickOrTreat. A snapshot lands up to ten
	times a second while digging; only texts change on one.

	PROPOSED (2026-10-19): the layout and the wording on the card.
]]
local CryptView = {}

local shared = script.Parent
local T = require(shared:WaitForChild("MineTheme"))
local UI = require(shared:WaitForChild("MineUI"))
local R = require(shared:WaitForChild("MineCryptRules"))
local Abbrev = require(shared:WaitForChild("MineAbbrev"))

local THEME = T.EVENT_THEMES.halloween
CryptView.THEME = THEME

local function commas(n)
	n = math.max(0, math.floor(tonumber(n) or 0))
	if n >= 1e6 then
		return Abbrev.currency(n)
	end
	local s = tostring(n)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end
CryptView.commas = commas

--[[
	PURE: what OPEN says and whether it buys, from the snapshot's crypt block.
	Returns caption, job ("primary" buys, "off" greys it out and makes it
	inert). The price is the server's (crypt.casePrice); the client only
	compares it with the balance the server sent.
]]
function CryptView.openState(cr)
	cr = type(cr) == "table" and cr or {}
	local w = type(cr.window) == "table" and cr.window or {}
	local price = math.floor(tonumber(cr.casePrice) or 0)
	local candy = math.floor(tonumber(cr.candy) or 0)
	if cr.owned ~= true then
		return "CLAIM THE CRYPT FIRST", "off"
	end
	if w.open ~= true then
		return w.ended and "THE CRYPT HAS CLOSED" or "OPENS SOON", "off"
	end
	if price <= 0 then
		return "OPEN", "primary"
	end
	if candy < price then
		return "NEED " .. commas(price - candy) .. " MORE 🍬", "off"
	end
	return "OPEN  \u{00B7}  " .. commas(price) .. " 🍬", "primary"
end

--[[
	PLACEHOLDER (2026-10-19): THE TRICK-OR-TREAT ODDS SHEET GOES HERE.

	Paid random items show their odds before purchase (house style rule 10),
	and this one will, once the new Trick-or-Treat loot API lands: build an
	ODDS button into `slot` (the card's "OddsSlot", hidden until then) that
	opens MineLuckyOddsView.sheet on the new odds function, show the slot, and
	narrow OPEN beside it. Until then it builds nothing and returns nil.
]]
function CryptView.mountCaseOdds(_slot, _opts)
	return nil
end

--------------------------------------------------------------------------------
-- THE CARD
--------------------------------------------------------------------------------

local function keep(inst)
	inst:SetAttribute("MineUIAdopted", true)
	return inst
end

local function frame(parent, props)
	local f = UI.new("Frame", props, parent)
	f.BorderSizePixel = 0
	return keep(f)
end

local function label(parent, str, size, ink, pos, sz, font)
	local l = UI.themeText(parent, str, size, THEME, ink, font)
	l.Position = pos or UDim2.fromOffset(0, 0)
	l.Size = sz or UDim2.new(1, 0, 0, size + 6)
	l.TextTruncate = Enum.TextTruncate.AtEnd
	return l
end

--[[
	mount(host, opts) -> ctl
	  host     a Frame the card grows in (AutomaticSize Y is set on what this adds)
	  opts     onTrickOrTreat(), overlay (where a sheet would draw)
	  ctl      setState(snap), onCaseOpened(), root
]]
function CryptView.mount(host, opts)
	opts = opts or {}
	local ctl = {}
	local busyUntil = 0

	local body = frame(host, {
		Name = "CryptBody", BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, body)

	-- ---------------------------------------------------- your candy + rule --
	local candyCard = UI.themeCard(body, THEME, UDim2.new(1, 0, 0, 100), nil, "FACE")
	candyCard.Name = "Candy"
	candyCard.LayoutOrder = 1
	local candyIcon = label(candyCard, "🍬", 40, "ON_FACE", UDim2.fromOffset(12, 0), UDim2.new(0, 52, 1, 0))
	candyIcon.TextXAlignment = Enum.TextXAlignment.Center
	local candyNum = label(candyCard, "0", 32, "ON_FACE", UDim2.fromOffset(70, 18), UDim2.new(0.42, -74, 0, 36))
	candyNum.Name = "CandyBalance"
	UI.popNumber(candyNum)
	label(candyCard, "YOUR CANDY", 14, "ON_FACE_MUTED", UDim2.fromOffset(70, 58), UDim2.new(0.42, -74, 0, 18))
	local rule = label(candyCard, R.NOTICE.text, 14, "ON_FACE_MUTED",
		UDim2.new(0.42, 0, 0, 8), UDim2.new(0.58, -14, 1, -16), T.FONT_M)
	rule.Name = "Rule"
	rule.TextWrapped = true
	rule.TextTruncate = Enum.TextTruncate.None
	rule.TextYAlignment = Enum.TextYAlignment.Center

	-- ------------------------------------------------------ trick-or-treat --
	local tot = UI.themeCard(body, THEME, UDim2.new(1, 0, 0, 136))
	tot.Name = "TrickOrTreat"
	tot.LayoutOrder = 2
	label(tot, "🎁 TRICK-OR-TREAT CASE", 20, "TEXT", UDim2.fromOffset(14, 10), UDim2.new(1, -28, 0, 26))
	label(tot, "Trade in candy for a Trick-or-Treat surprise.", 14, "MUTED",
		UDim2.fromOffset(14, 38), UDim2.new(1, -28, 0, 20), T.FONT_M)
	-- Where the ODDS button goes (CryptView.mountCaseOdds): kept, hidden.
	local oddsSlot = frame(tot, {
		Name = "OddsSlot", BackgroundTransparency = 1, Visible = false,
		Position = UDim2.new(0, 14, 1, -64), Size = UDim2.fromOffset(110, 50),
	})
	CryptView.mountCaseOdds(oddsSlot, opts)
	local openBtn, openLbl = UI.themeButton(tot, "OPEN", UDim2.new(1, -28, 0, 50),
		UDim2.new(0, 14, 1, -64), THEME, "primary")
	openBtn.Name = "Open"
	openLbl.TextSize = 18
	openLbl.TextTruncate = Enum.TextTruncate.AtEnd
	local openJob = "primary"

	openBtn.MouseButton1Click:Connect(function()
		if not openBtn.Active or os.clock() < busyUntil then
			return
		end
		-- One case at a time: the server answers with trickOrTreatOpened (and a
		-- toast), and a double tap must not buy two.
		busyUntil = os.clock() + 3
		if opts.onTrickOrTreat then
			opts.onTrickOrTreat()
		end
	end)

	-- ------------------------------------------------------------- state --
	function ctl.setState(snap)
		local cr = (type(snap) == "table" and type(snap.crypt) == "table") and snap.crypt or {}
		candyNum.Text = commas(cr.candy)
		local text, job = CryptView.openState(cr)
		openLbl.Text = text
		if job ~= openJob then
			openJob = job
			UI.setJob(openBtn, THEME, job)
		end
	end

	-- The case answered (trickOrTreatOpened): OPEN may be pressed again. What
	-- came out is the server's toast for now; the reveal is redone against
	-- the new Trick-or-Treat API.
	function ctl.onCaseOpened()
		busyUntil = 0
	end

	ctl.root = body
	return ctl
end

return CryptView
