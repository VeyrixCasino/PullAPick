--[[
	MineScrapSelect -- the bulk-recycle SELECT / RECYCLE control, for any screen.

	The flow is always the same: SELECT puts a list into selection mode, taps
	tick items, RECYCLE asks the server to price them, and the server's reply
	opens the review screen where a 3-second hold confirms. Only the LIST
	differs, and it lives in three different screens: gear, cards and packs in
	the inventory, runes in the Enchanter.

	So the control is here rather than copied. It was written inline in the
	inventory first, and copying ~100 lines of it into the Enchanter is how the
	two would drift -- one of them would learn about SCRAP_MAX, or about kinds,
	and the other would not.

	WHAT A HOST PROVIDES is the three things only it knows: where to draw, how to
	redraw, and how to talk to the server.

		local sel = ScrapSelect.new({
			body = body,                  -- parent for scrapHead's own row
			render = function() render() end,
			ask = function(kind, ids, into) opts.onScrapMany(kind, ids, into, false) end,
			toast = function(msg) if opts.onToast then opts.onToast(msg) end end,
		})

	THE SELECTION CARRIES ITS KIND. An untagged set of ids is a bug waiting to
	happen on any screen with more than one list: tick three gear pieces, switch
	to packs, hit RECYCLE, and the ids go out under the wrong kind. The server
	blocks every one as "not in your bag", which is the polite version of the
	same failure. Changing kind clears the selection, so every id in it is an id
	of that kind by construction rather than by care.

	THE IDS ARE WHAT THE SERVER SCRAPS BY, per kind: a card id, a rune id, a gear
	id, a pack UID. Never an index -- the bag can shift between the list being
	drawn and the confirm, and an index would then scrap whatever slid into that
	position.

	THERE IS NO SELECT-ALL, deliberately: every item in a recycle batch is ticked
	on purpose. And the 3-second hold is NOT on this bar, it is on the review
	screen -- a hold is a confirmation, and up here there is nothing yet to
	confirm against.
]]

local MineScrapSelect = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local T = require(shared:WaitForChild("MineTheme"))

local FONT = T.FONT
local BG3 = T.BG3
local TEXT = T.TEXT
local MUTED = T.MUTED
local GOLD = T.GOLD

-- The red of a destructive action, shared with the review screen's hold button.
local HOT = Color3.fromRGB(150, 58, 58)
local HOT_INK = Color3.fromRGB(255, 226, 226)
local TICK = Color3.fromRGB(255, 200, 160)
MineScrapSelect.HOT = HOT
MineScrapSelect.TICK = TICK
MineScrapSelect.EDGE = Color3.fromRGB(255, 120, 100)
MineScrapSelect.VEIL = Color3.fromRGB(8, 8, 12)

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function round(o, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
	return o
end

function MineScrapSelect.max()
	return math.max(1, math.floor(tonumber(C.SCRAP_MAX) or 200))
end

function MineScrapSelect.new(host)
	host = (type(host) == "table") and host or {}
	local sel = { kind = nil, ids = {} }

	local function redraw()
		if type(host.render) == "function" then
			host.render()
		end
	end

	function sel.count()
		local n = 0
		for _ in pairs(sel.ids) do
			n += 1
		end
		return n
	end

	function sel.clear()
		sel.kind, sel.ids = nil, {}
	end

	-- Is this list the one currently selecting?
	function sel.on(kind)
		return sel.kind == kind
	end

	function sel.has(kind, id)
		return (sel.kind == kind and id ~= nil and sel.ids[id] == true) or false
	end

	--[[
		Tick or untick one id, or a whole STACK of them.

		A tile is sometimes a stack -- several packs, several copies of a rune --
		and the server takes them one id at a time, so the stack goes in or comes
		out together. A half-ticked stack has nowhere to show itself on a single
		tile.

		Clamped to SCRAP_MAX, the number the server truncates the list at.
		Without the clamp a 300-pack stack would be ticked, quoted at 200 and
		scrapped at 200: the review would be honest about a list the player never
		chose. Returns false when it had to refuse, so the caller can say why.
	]]
	function sel.toggle(kind, ids)
		if type(ids) ~= "table" or #ids == 0 then
			return true
		end
		if sel.kind ~= kind then
			sel.kind, sel.ids = kind, {}
		end
		if sel.ids[ids[1]] then
			for _, id in ipairs(ids) do
				sel.ids[id] = nil
			end
			return true
		end
		if sel.count() + #ids > MineScrapSelect.max() then
			return false
		end
		for _, id in ipairs(ids) do
			sel.ids[id] = true
		end
		return true
	end

	--[[
		Drop ids that are no longer there.

		A selection can go stale without this screen doing anything: the review
		is confirmed from another panel, a rune is fused, a pack is opened, an
		item is traded away. The server blocks an id it cannot find and the batch
		is all-or-nothing, so a stale tick turns into a refused batch and a tick
		drawn on something that does not exist.

		`keep(id)` answers whether an id is still real. Call it from the host's
		paint, where the fresh snapshot is already in hand.
	]]
	function sel.prune(keep)
		if type(keep) ~= "function" then
			return
		end
		for id in pairs(sel.ids) do
			if not keep(id) then
				sel.ids[id] = nil
			end
		end
		-- The KIND is deliberately left alone. Nothing ticked is still "selecting
		-- this kind" -- the bar reads `on` for that -- so the mode ends when the
		-- player ends it, not when the last item happens to vanish.
	end

	-- Tap handling, in the one shape every tile wants: tick it, or say why not.
	-- Returns true when the caller should stop (it was a selection tap).
	function sel.tap(kind, ids, canSell)
		if not sel.on(kind) then
			return false
		end
		if not canSell then
			return true
		end
		if not sel.toggle(kind, ids) then
			if type(host.toast) == "function" then
				host.toast("One recycle batch carries at most "
					.. MineScrapSelect.max() .. " items")
			end
			return true
		end
		redraw()
		return true
	end

	--[[
		The SELECT / RECYCLE pair, drawn into a row the caller already has.

		`into` is the currency the server pays in and it differs by kind, so the
		caller names it rather than this guessing: the server prices from the
		same field and the two must not drift. Cards pay stardust; gear, packs
		and runes pay gems.

		`hints` is optional: { off = ..., none = ..., some = ... }, the line shown
		beside the buttons when not selecting, selecting with nothing ticked, and
		selecting with something ticked.
	]]
	function sel.bar(row, kind, into, hints)
		local on = sel.on(kind)
		local n = on and sel.count() or 0
		local modeB = mk("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = on and HOT or BG3,
			Text = on and ("SELECTING  " .. n) or "SELECT",
			Font = FONT, TextSize = 12,
			TextColor3 = on and HOT_INK or TEXT,
			Size = UDim2.fromOffset(118, 28), Position = UDim2.new(1, -270, 0.5, -14),
		}, row)
		round(modeB, 8)
		modeB.MouseButton1Click:Connect(function()
			if sel.on(kind) then
				sel.clear()
			else
				sel.kind, sel.ids = kind, {}
			end
			redraw()
		end)
		local goB = mk("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = (on and n > 0) and HOT or BG3,
			Text = (on and n > 0) and ("RECYCLE " .. n) or "RECYCLE",
			Font = FONT, TextSize = 12,
			TextColor3 = (on and n > 0) and HOT_INK or MUTED,
			Size = UDim2.fromOffset(96, 28), Position = UDim2.new(1, -146, 0.5, -14),
		}, row)
		round(goB, 8)
		goB.MouseButton1Click:Connect(function()
			if not sel.on(kind) or sel.count() <= 0 then
				return
			end
			local ids = {}
			for id in pairs(sel.ids) do
				table.insert(ids, id)
			end
			-- The ASK. The server prices it and replies with confirmScrap, which
			-- opens the review; nothing is scrapped by this call.
			if type(host.ask) == "function" then
				host.ask(kind, ids, into)
			end
		end)
		if type(hints) == "table" then
			local text = (not on and hints.off) or ((n > 0) and hints.some) or hints.none
			if text then
				local l = mk("TextLabel", {
					BackgroundTransparency = 1,
					Font = FONT, TextSize = 11,
					TextColor3 = (n > 0) and GOLD or MUTED,
					Text = tostring(text),
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(120, 0),
					Size = UDim2.new(0.35, 0, 1, 0),
				}, row)
				l.Name = "ScrapHint"
			end
		end
		return on, n
	end

	return sel
end

return MineScrapSelect
