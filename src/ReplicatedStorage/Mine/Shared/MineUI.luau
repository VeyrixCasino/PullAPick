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
