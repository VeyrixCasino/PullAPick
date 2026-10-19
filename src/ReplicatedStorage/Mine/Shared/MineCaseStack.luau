--[[
	MineCaseStack -- OPENING UP TO FIVE CASES AT ONCE, AS STACKED SPINS.

	Owner, 2026-10-19 (wiki open-questions, "Candy Crypt v2"): "make every case
	in the game be able to spin up to 5 slot spins at a time (one on top of
	another)".

	  * Every place a case is opened has a 1-5 picker (picker below): the bag's
	    case tiles (pack cases, ore/skin cases, gear cases), the Enchanter's
	    Temperament Case and the wandering traders' shelf.
	  * The server opens that many in ONE request, each rolled exactly as a single
	    open is, and a paid open (Temperament Case tokens, a trader's tokens) is
	    charged all or nothing (charge below): never four of five.
	  * The case screen (MineGradeReveal.caseSpin) spins the results on reels
	    stacked one above another. They start together and stop in turn, top to
	    bottom (stopAt), then the screen shows what they paid. Every reel is built
	    around the winner the server already rolled; the spin decides nothing.
	  * More than five reels (five Gear Vaults are 25 items) play in rounds of
	    five (rounds), each round on the player's close, with SKIP ALL.

	Not cases, so not here: lucky blocks (their own tap-through screen), packs,
	prototype crates. The Trick-or-Treat case is rebuilt with the Crypt.

	Shared by the server (clamp, charge, isCase), the client (picker, rounds,
	remember) and tools/verify/case-stack.js. Nothing touches an Instance until
	picker() is called, so a plain luau harness can require it.
]]

local MineCaseStack = {}

-- At most this many open in one go (owner: "up to 5").
MineCaseStack.MAX = 5

--[[
	PROPOSED (2026-10-19): the stacked spin's timing. The top reel spins SPIN
	seconds and each reel under it stops STAGGER seconds after the one above, so
	five land over SPIN + 4 x STAGGER = 6.6 s (one reel alone keeps the old 5.4 s).
	A tap stops them all at once.
]]
MineCaseStack.SPIN = 4.6
MineCaseStack.STAGGER = 0.5

-- How many to open: the request, floored and kept to 1..MAX, and to what the
-- player holds when that is known (a stack of 3 cannot open 5).
function MineCaseStack.clamp(n, held)
	local cap = MineCaseStack.MAX
	if held ~= nil then
		cap = math.min(cap, math.max(1, math.floor(tonumber(held) or 1)))
	end
	return math.clamp(math.floor(tonumber(n) or 1), 1, cap)
end

--[[
	ALL OR NOTHING. The price of `n` opens at `unit` each, or nil and that price
	when `have` cannot cover every one of them. Asked BEFORE anything is rolled
	or charged, so a short purse opens nothing instead of some.
]]
function MineCaseStack.charge(have, unit, n)
	local total = math.max(0, math.floor(tonumber(unit) or 0)) * math.max(0, math.floor(tonumber(n) or 0))
	if (tonumber(have) or 0) < total then
		return nil, total
	end
	return total
end

-- Seconds after the stack starts that reel `i` (1 = the top) stops.
function MineCaseStack.stopAt(i)
	return MineCaseStack.SPIN + (math.max(1, math.floor(tonumber(i) or 1)) - 1) * MineCaseStack.STAGGER
end

-- `list` cut into rounds of at most `size` (default MAX), in order.
function MineCaseStack.rounds(list, size)
	size = math.max(1, math.floor(tonumber(size) or MineCaseStack.MAX))
	local out, cur = {}, nil
	for _, v in ipairs(list or {}) do
		if not cur or #cur >= size then
			cur = {}
			table.insert(out, cur)
		end
		table.insert(cur, v)
	end
	return out
end

--[[
	IS THIS BAG ROW A CASE? The picker replaces a tile's x10 / ALL chips only for
	these: a pack case (wild or set, MineCases), an ore case (it pays a skin or a
	charm; `<ore>_ore_case`), and a gear case (gear_pack, gear_case_pack,
	gear_vault_pack: the pack rows of kind "gear"). Lazy requires: MinePackConfig
	requires MineCases at load, and neither needs this.
]]
function MineCaseStack.isCase(packId, kind)
	packId = tostring(packId or "")
	if kind == "pack_case" or kind == "ore_case" or kind == "gear" then
		return true
	end
	if string.match(packId, "_ore_case$") then
		return true
	end
	local okC, Cases = pcall(function()
		return require(script.Parent:WaitForChild("MineCases"))
	end)
	if okC and Cases and Cases.get and Cases.get(packId) then
		return true
	end
	local okP, Packs = pcall(function()
		return require(script.Parent:WaitForChild("MinePackConfig"))
	end)
	return (okP and Packs and Packs.packKind and Packs.packKind(packId) == "gear") or false
end

-- The count a picker last showed for `key` (a stack, the Temperament Case, the
-- trader), kept for the session so a re-render does not throw it back to 1.
MineCaseStack.memory = {}

function MineCaseStack.remember(key, n)
	MineCaseStack.memory[tostring(key)] = MineCaseStack.clamp(n)
end

function MineCaseStack.recall(key, held)
	return MineCaseStack.clamp(MineCaseStack.memory[tostring(key)] or 1, held)
end

--[[
	THE PICKER: chips 1..max in a row, the picked one filled. Kids read "3" faster
	than a stepper, and one tap sets it.

	opts = {
		max      = how many chips (clamped to MAX; a stack of 3 shows 1-3),
		value    = the picked count,
		key      = remember the pick under this key (MineCaseStack.memory),
		color    = the filled chip (the tile's or row's own colour),
		ink      = text on the filled chip,
		size     = Vector2 chip size (default 24 x 26), gap = px between chips,
		textSize = at least 14 (MineTheme.TEXT_MIN),
		zIndex   = number,
		onPick   = function(n),
	}
	Returns { frame, get(), set(n) }. The chips are plain buttons: MineUI.watch
	gives them the house shading, and nothing here scales text.
]]
function MineCaseStack.picker(parent, opts)
	opts = opts or {}
	local max = MineCaseStack.clamp(opts.max or MineCaseStack.MAX)
	local value = MineCaseStack.clamp(opts.value or (opts.key and MineCaseStack.recall(opts.key, max)) or 1, max)
	local col = opts.color or Color3.fromRGB(255, 206, 92)
	local ink = opts.ink or Color3.fromRGB(24, 18, 10)
	local size = opts.size or Vector2.new(24, 26)
	local gap = tonumber(opts.gap) or 3
	local z = tonumber(opts.zIndex) or 1
	local textSize = math.max(14, tonumber(opts.textSize) or 14)
	local frame = Instance.new("Frame")
	frame.Name = "CasePicker"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromOffset(max * size.X + (max - 1) * gap, size.Y)
	frame.ZIndex = z
	if opts.position then
		frame.Position = opts.position
	end
	if opts.anchor then
		frame.AnchorPoint = opts.anchor
	end
	local chips = {}
	local ctl = { frame = frame }
	local function paint()
		for n, chip in ipairs(chips) do
			local on = n == value
			chip.BackgroundColor3 = on and col or Color3.fromRGB(28, 24, 44)
			chip.TextColor3 = on and ink or col
			chip:FindFirstChildOfClass("UIStroke").Transparency = on and 1 or 0.2
		end
	end
	for n = 1, max do
		local chip = Instance.new("TextButton")
		chip.Name = "Pick" .. n
		chip.AutoButtonColor = true
		chip.BorderSizePixel = 0
		chip.Font = Enum.Font.BuilderSansBold
		chip.TextSize = textSize
		chip.Text = tostring(n)
		chip.Position = UDim2.fromOffset((n - 1) * (size.X + gap), 0)
		chip.Size = UDim2.fromOffset(size.X, size.Y)
		chip.ZIndex = z + 1
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = chip
		local edge = Instance.new("UIStroke")
		edge.Thickness = 1.5
		edge.Color = col
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Parent = chip
		chip.Parent = frame
		chip.MouseButton1Click:Connect(function()
			ctl.set(n)
			if opts.onPick then
				opts.onPick(n)
			end
		end)
		chips[n] = chip
	end
	function ctl.get()
		return value
	end
	function ctl.set(n)
		value = MineCaseStack.clamp(n, max)
		if opts.key then
			MineCaseStack.remember(opts.key, value)
		end
		paint()
	end
	paint()
	frame.Parent = parent
	return ctl
end

return MineCaseStack
