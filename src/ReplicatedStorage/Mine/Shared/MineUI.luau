--[[
	MineUI -- the shared kit every panel is built from.

	WHY THIS EXISTS, AND WHY A PALETTE WAS NOT ENOUGH.

	MineTheme already gave the game one set of colours, and the game still did
	not look like one game. The reason is measurable: TWENTY-FIVE modules each
	declare their own `local function mk(...)`, so every panel builds its own
	frames, picks its own padding, decides for itself whether a surface gets a
	stroke, and lands on its own corner radius. A shared palette cannot survive
	twenty-five independent constructors -- the twenty-sixth panel invents a
	twenty-sixth look, and the drift starts again the day after it is tidied.

	Owner, 2026-10-05, with a generated reference screen: "HOW CAN I MAKE THAT
	THE UI STANDARD FOR THE ENTIRE GAME". This is the answer. Not a document
	saying what the standard is -- a set of constructors that cannot produce
	anything else.

	WHAT MAKES THE REFERENCE LOOK EXPENSIVE. It is not the colours, it is the
	consistency of four things, every one of which is free once it lives here:

	  1. every surface has the SAME corner radius for its size class
	  2. every surface has a lit hairline edge, never a hard flat rectangle
	  3. padding is generous and identical everywhere
	  4. panels carry a faint vertical gradient, so they read as lit from above
	     rather than as flat fills

	USE IT LIKE THIS, and never reach past it into raw Instance.new for a
	surface:

	    local UI = require(shared.MineUI)
	    local panel = UI.panel(parent, UDim2.fromScale(1, 1))
	    local row   = UI.card(panel, UDim2.new(1, 0, 0, 64))
	    UI.title(row, "Clay Pickaxe")
	    UI.pill(row, "UNCOMMON", T.ACCENT)

	If a panel needs something this file cannot build, ADD IT HERE. A one-off in
	a view is how the last five looks happened.
]]

local shared = script.Parent
local T = require(shared:WaitForChild("MineTheme"))

local MineUI = {}

MineUI.PAD = 14
MineUI.GAP = 12

--[[
	The primitive everything else is made of.

	`props` is applied verbatim after the defaults, so any caller can override
	one thing without re-specifying the rest -- which is what stops a view from
	deciding it needs its own constructor again.
]]
function MineUI.new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

-- Rounded corners, one radius per size class so they stop drifting.
function MineUI.round(inst, r)
	MineUI.new("UICorner", { CornerRadius = UDim.new(0, r or T.RADIUS) }, inst)
	return inst
end

--[[
	The lit hairline. Every surface in the reference has one; a flat rectangle
	with no edge is the single biggest tell of a programmer-built Roblox UI.
]]
function MineUI.edge(inst, color, thickness)
	return MineUI.new("UIStroke", {
		Color = color or T.EDGE,
		Thickness = thickness or 1,
		Transparency = 0.15,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, inst)
end

--[[
	The faint top-down gradient that makes a panel read as lit.

	Rotation 90 is top-to-bottom. The reference is subtle about this -- about
	eight percent -- and subtlety is the difference between "lit" and "a gradient
	was applied here".
]]
function MineUI.lit(inst, strength)
	local s = strength or 0.08
	return MineUI.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(1 - s, 1 - s, 1 - s)),
		}),
	}, inst)
end

function MineUI.pad(inst, n)
	n = n or MineUI.PAD
	return MineUI.new("UIPadding", {
		PaddingTop = UDim.new(0, n), PaddingBottom = UDim.new(0, n),
		PaddingLeft = UDim.new(0, n), PaddingRight = UDim.new(0, n),
	}, inst)
end

-- ---------------------------------------------------------------- surfaces --

-- PANEL: a window on the page. Largest radius, lit edge, gradient, padding.
function MineUI.panel(parent, size, pos)
	local f = MineUI.new("Frame", {
		BackgroundColor3 = T.PANEL,
		BorderSizePixel = 0,
		Size = size or UDim2.fromScale(1, 1),
		Position = pos or UDim2.fromOffset(0, 0),
	}, parent)
	MineUI.round(f, T.RADIUS_LG)
	MineUI.edge(f)
	MineUI.lit(f)
	return f
end

-- CARD: a row or tile inside a panel. One step lighter, one step smaller.
function MineUI.card(parent, size, pos, tint)
	local f = MineUI.new("Frame", {
		BackgroundColor3 = tint or T.CARD,
		BorderSizePixel = 0,
		Size = size or UDim2.new(1, 0, 0, 56),
		Position = pos or UDim2.fromOffset(0, 0),
	}, parent)
	MineUI.round(f, T.RADIUS)
	MineUI.edge(f, T.LINE)
	MineUI.lit(f, 0.05)
	return f
end

--[[
	TILE: a card that can be selected, which is most of the reference's chrome --
	the left rail, the counter row along the bottom, the tool slots.

	`accent` is the colour it lights up in. Returns the frame and a setter, so a
	caller never re-implements "what selected looks like".
]]
function MineUI.tile(parent, size, pos, accent)
	accent = accent or T.ACCENT
	local f = MineUI.card(parent, size, pos)
	local stroke = f:FindFirstChildOfClass("UIStroke")
	local function setOn(on)
		f.BackgroundColor3 = on and T.CARD_HI or T.CARD
		if stroke then
			stroke.Color = on and accent or T.LINE
			stroke.Thickness = on and 1.5 or 1
		end
	end
	setOn(false)
	return f, setOn
end

-- ------------------------------------------------------------------- text --

function MineUI.text(parent, str, size, color, font)
	return MineUI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = str or "",
		TextSize = math.max(T.TEXT_MIN, size or T.TEXT_BODY),
		TextColor3 = color or T.TEXT,
		Font = font or T.FONT_M,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 1, 0),
	}, parent)
end

function MineUI.title(parent, str, size)
	return MineUI.text(parent, str, size or T.TEXT_TITLE, T.TEXT, T.FONT)
end

function MineUI.muted(parent, str, size)
	return MineUI.text(parent, str, size or T.TEXT_MIN, T.MUTED, T.FONT_M)
end

--[[
	PILL: the rarity chip. Tinted fill, same-hue edge, text in the tint -- never
	white on a colour, which is the thing that makes a badge look cheap.
]]
function MineUI.pill(parent, str, tint, pos)
	local p = MineUI.new("Frame", {
		BackgroundColor3 = tint or T.ACCENT,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(math.max(64, #tostring(str) * 9 + 24), 24),
		Position = pos or UDim2.fromOffset(0, 0),
	}, parent)
	MineUI.round(p, 999)
	MineUI.edge(p, tint or T.ACCENT, 1)
	local l = MineUI.text(p, tostring(str), 13, tint or T.ACCENT, T.FONT)
	l.TextXAlignment = Enum.TextXAlignment.Center
	return p
end

--[[
	BUTTON: outline style, because the reference has exactly one filled button on
	screen and everything else is an outline. `primary` fills it in GOLD.
]]
function MineUI.button(parent, str, size, pos, primary, tint)
	local col = tint or (primary and T.GOLD or T.ACCENT)
	local b = MineUI.new("TextButton", {
		BackgroundColor3 = col,
		BackgroundTransparency = primary and 0.88 or 0.92,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Text = "",
		Size = size or UDim2.fromOffset(160, 44),
		Position = pos or UDim2.fromOffset(0, 0),
	}, parent)
	MineUI.round(b, 999)
	MineUI.edge(b, col, 2)
	local l = MineUI.text(b, tostring(str), 16, col, T.FONT)
	l.TextXAlignment = Enum.TextXAlignment.Center
	return b, l
end

--[[
	ICON: an ImageLabel from MineIcons, never a drawn shape.

	MineIcons carries 134 uploaded 256px PNGs and its header says exactly why:
	the set before it was "hand-drawn out of Frames and UICorners, which is why
	they read as placeholder art". Anything this kit draws as chrome goes through
	here so that mistake cannot be made a third time.
]]
function MineUI.icon(parent, image, px, pos, tint)
	return MineUI.new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = image or "",
		ImageColor3 = tint or Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(px or 24, px or 24),
		Position = pos or UDim2.fromOffset(0, 0),
		ScaleType = Enum.ScaleType.Fit,
	}, parent)
end

-- ------------------------------------------------------------- retrofit --
--[[
	ADOPT: make a panel that was NOT built with this kit look like it was.

	Owner, 2026-10-05: "I WANT ALL UIS TO HAVE THAT STYLE". Twenty-five modules
	build their own chrome with their own private mk(), and rewriting all of them
	by hand is a week of work and twenty-five chances to break a working panel.
	This is the other way: walk what a view already built and normalise the four
	things that carry the house style, leaving layout and meaning untouched.

	WHAT IT CHANGES
	  * a neutral surface gets the nearest theme surface colour
	  * every surface gets the kit's corner radius, if it has none
	  * every surface gets the lit hairline, if it has none
	  * default fonts become the theme faces
	  * near-white / near-grey text becomes TEXT / MUTED

	WHAT IT REFUSES TO TOUCH, and this is the important half:
	  * anything SATURATED. A coloured fill is carrying meaning -- rarity, a
	    currency, a progress bar, an affordable/blocked state -- and repainting
	    it would destroy information rather than style it. Saturation is measured,
	    not guessed at from a list of names that would go stale.
	  * size, position, layout, ZIndex. Style only; nothing moves.
	  * images. Icon art is MineIcons' job.
	  * anything tagged with the NoAdopt attribute, for the one-off that genuinely
	    needs to look different.

	Idempotent: an adopted instance is stamped, so re-running over a live tree is
	free and cannot double-stroke.
]]
local ADOPTED = "MineUIAdopted"

local function saturation(c)
	local mx = math.max(c.R, c.G, c.B)
	local mn = math.min(c.R, c.G, c.B)
	if mx <= 0 then
		return 0
	end
	return (mx - mn) / mx
end

-- Nearest theme surface by brightness, so a view's own three-step greyscale
-- lands on the theme's three-step indigo in the same order.
local function nearestSurface(c)
	local l = (c.R + c.G + c.B) / 3
	if l < 0.10 then
		return T.INK
	elseif l < 0.22 then
		return T.PANEL
	elseif l < 0.40 then
		return T.CARD
	end
	return T.CARD_HI
end

local DEFAULT_FONTS = {
	[Enum.Font.SourceSans] = true, [Enum.Font.SourceSansBold] = true,
	[Enum.Font.SourceSansSemibold] = true, [Enum.Font.SourceSansLight] = true,
	[Enum.Font.Legacy] = true, [Enum.Font.Arial] = true, [Enum.Font.ArialBold] = true,
	[Enum.Font.Gotham] = true, [Enum.Font.GothamMedium] = true,
	[Enum.Font.GothamBold] = true, [Enum.Font.GothamBlack] = true,
}

function MineUI.adoptOne(inst)
	if inst:GetAttribute(ADOPTED) or inst:GetAttribute("NoAdopt") then
		return false
	end
	local isSurface = inst:IsA("Frame") or inst:IsA("ScrollingFrame")
		or inst:IsA("TextButton") or inst:IsA("ImageButton")
	local isText = inst:IsA("TextLabel") or inst:IsA("TextButton")

	if isSurface and inst.BackgroundTransparency < 0.95 then
		local bg = inst.BackgroundColor3
		-- Saturated means it is carrying meaning. Leave it entirely alone.
		if saturation(bg) < 0.22 then
			inst.BackgroundColor3 = nearestSurface(bg)
		end
		if inst.BorderSizePixel ~= 0 then
			inst.BorderSizePixel = 0
		end
		if not inst:FindFirstChildOfClass("UICorner") then
			MineUI.round(inst, inst.AbsoluteSize.Y >= 90 and T.RADIUS_LG or T.RADIUS)
		end
		if not inst:FindFirstChildOfClass("UIStroke") then
			MineUI.edge(inst, T.LINE)
		end
	end

	if isText then
		if DEFAULT_FONTS[inst.Font] then
			inst.Font = inst.TextSize >= 18 and T.FONT or T.FONT_M
		end
		local tc = inst.TextColor3
		if saturation(tc) < 0.18 then
			local l = (tc.R + tc.G + tc.B) / 3
			inst.TextColor3 = (l > 0.72 and T.TEXT) or (l > 0.40 and T.MUTED) or T.FAINT
		end
	end

	inst:SetAttribute(ADOPTED, true)
	return true
end

function MineUI.adopt(root)
	if not root then
		return 0
	end
	local n = 0
	if MineUI.adoptOne(root) then
		n += 1
	end
	for _, d in ipairs(root:GetDescendants()) do
		if MineUI.adoptOne(d) then
			n += 1
		end
	end
	return n
end

--[[
	Adopt now, and keep adopting.

	Panels build lazily -- a view creates its rows the first time it opens -- so
	a single pass at startup would style the shell and miss everything inside it.
	DescendantAdded is deferred by a frame because a view typically creates a
	Frame and THEN sets its colours and children; adopting on the same frame
	would read values the view has not written yet.
]]
function MineUI.watch(root)
	if not root or root:GetAttribute("MineUIWatched") then
		return
	end
	root:SetAttribute("MineUIWatched", true)
	MineUI.adopt(root)
	root.DescendantAdded:Connect(function(d)
		task.defer(function()
			if d.Parent then
				MineUI.adoptOne(d)
			end
		end)
	end)
end

-- Horizontal or vertical flow with the kit's standard gap.
function MineUI.flow(parent, vertical, gap)
	return MineUI.new("UIListLayout", {
		FillDirection = vertical and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, gap or MineUI.GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, parent)
end

return MineUI
