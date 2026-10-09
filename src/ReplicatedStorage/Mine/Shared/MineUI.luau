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

local TweenService = game:GetService("TweenService")

local shared = script.Parent
local T = require(shared:WaitForChild("MineTheme"))

local MineUI = {}

MineUI.PAD = 14
MineUI.GAP = 12

-- ------------------------------------------------------------------ motion --
-- One tween helper for the whole UI, so "juice" is a one-liner and no view
-- needs its own TweenService boilerplate. Returns the Tween.
function MineUI.tween(inst, seconds, props, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(
		seconds or 0.15,
		style or Enum.EasingStyle.Quad,
		dir or Enum.EasingDirection.Out
	), props)
	t:Play()
	return t
end

--[[
	ONE UISCALE PER INSTANCE, SHARED BY EVERY EFFECT.

	Roblox applies only the FIRST UIScale under a GuiObject and silently ignores
	the rest (measured in Studio, 2026-10-08). The first cut of this kit gave
	pop, juice and pulse a UIScale each, so on a button that had all three only
	one worked. The claim button's pulse, for example, never moved.

	So each effect is a CHANNEL: a NumberValue under one shared "FxScale". The
	scale is the product of every channel, so a pulsing button can still squash
	when pressed and pop when it changes. Scaling through a UIScale rather than
	Size means none of it ever fights a layout that owns Size or Position.

	If the instance already carries someone else's UIScale, ours would be
	ignored anyway, so the effect quietly does nothing rather than fight it.
]]
local function channel(inst, name)
	local s = inst:FindFirstChild("FxScale")
	if not s then
		if inst:FindFirstChildOfClass("UIScale") then
			return nil
		end
		s = Instance.new("UIScale")
		s.Name = "FxScale"
		s.Parent = inst
	end
	local v = s:FindFirstChild(name)
	if not v then
		v = Instance.new("NumberValue")
		v.Name = name
		v.Value = 1
		v.Changed:Connect(function()
			local p = 1
			for _, c in ipairs(s:GetChildren()) do
				if c:IsA("NumberValue") then
					p *= c.Value
				end
			end
			s.Scale = p
		end)
		v.Parent = s
	end
	return v
end

--[[
	POP: a quick overshoot-and-settle. Use it when a number changes, a thing
	becomes claimable, a toast lands. `amount` is the peak scale (default 1.18);
	below 1 it springs IN from smaller, which is how a window opens.
]]
function MineUI.pop(inst, amount)
	local v = channel(inst, "pop")
	if not v then
		return
	end
	v.Value = amount or 1.18
	MineUI.tween(v, 0.28, { Value = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

--[[
	Pop a TextLabel every time its text changes, except the first set. Safe to
	call twice on the same label.
]]
function MineUI.popNumber(label, amount)
	if label:GetAttribute("PopNumber") then
		return
	end
	label:SetAttribute("PopNumber", true)
	local last = label.Text
	label:GetPropertyChangedSignal("Text"):Connect(function()
		if label.Text ~= last then
			last = label.Text
			if label.Visible then
				MineUI.pop(label, amount)
			end
		end
	end)
end

--[[
	JUICE: tactile feedback for any button. Hover grows, press squashes, release
	bounces back. Touch has no hover, so the press squash is what phones feel.
	Idempotent.
]]
function MineUI.juice(btn, grow)
	if btn:GetAttribute("Juiced") then
		return btn
	end
	btn:SetAttribute("Juiced", true)
	local v = channel(btn, "juice")
	if not v then
		return btn
	end
	local over, down = false, false
	local function settle()
		local target = (down and 0.93) or (over and (grow or 1.07)) or 1
		MineUI.tween(v, down and 0.07 or 0.2, { Value = target },
			down and Enum.EasingStyle.Quad or Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	btn.MouseEnter:Connect(function() over = true settle() end)
	btn.MouseLeave:Connect(function() over = false down = false settle() end)
	btn.MouseButton1Down:Connect(function() down = true settle() end)
	btn.MouseButton1Up:Connect(function() down = false settle() end)
	return btn
end

--[[
	PULSE: a looping "look at me" throb for anything claimable. Returns a stop
	function; calling it settles the scale back to 1.
]]
function MineUI.pulse(inst, amount, period)
	local v = channel(inst, "pulse")
	if not v then
		return function() end
	end
	local alive = true
	local half = (period or 0.7) / 2
	task.spawn(function()
		while alive and inst.Parent do
			MineUI.tween(v, half, { Value = amount or 1.08 }, Enum.EasingStyle.Sine)
			task.wait(half)
			if not alive then break end
			MineUI.tween(v, half, { Value = 1 }, Enum.EasingStyle.Sine)
			task.wait(half)
		end
		if v.Parent then
			MineUI.tween(v, 0.15, { Value = 1 })
		end
	end)
	return function() alive = false end
end

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

--[[
	CANDY: the chunky look. Fat near-black outline and a bright top-to-bottom
	gradient. `key` is a T.CANDY name ("gold", "green", ...) or a Color3, from
	which a light/dark pair is derived. Pass gloss = true for an optional top
	highlight (a child Frame, so call this before adding text children).
]]
local function shade(c, k)
	return Color3.new(
		math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end

function MineUI.candy(inst, key, thickness, gloss)
	local pair = type(key) == "string" and T.CANDY[key] or nil
	if not pair then
		local c = typeof(key) == "Color3" and key or T.ACCENT
		pair = { shade(c, 1.25), shade(c, 0.78) }
	end
	inst.BackgroundColor3 = Color3.new(1, 1, 1)
	inst.BackgroundTransparency = 0
	MineUI.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(pair[1], pair[2]),
	}, inst)
	MineUI.new("UIStroke", {
		Color = T.OUTLINE,
		Thickness = thickness or T.STROKE_CHUNKY,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, inst)
	-- Gloss is opt-in. Owner, 2026-10-08, on the dock: "get rid of that weird
	-- bubble that takes up half the icon". The gradient carries the candy look.
	if gloss == true then
		local g = MineUI.new("Frame", {
			Name = "Gloss",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.78,
			BorderSizePixel = 0,
			Position = UDim2.new(0.06, 0, 0, 3),
			Size = UDim2.new(0.88, 0, 0.38, 0),
			Active = false,
		}, inst)
		MineUI.round(g, 999)
	end
	-- Stamp it so MineUI.adopt neither restyles nor double-strokes this surface.
	inst:SetAttribute("MineUIAdopted", true)
	return inst
end

--[[
	CANDY TINT: the same chunky look, but the hue stays in BackgroundColor3, so
	code that recolours the surface at runtime (SELL green / SURFACE gold, a bar
	that turns green when ready) keeps working. The gradient only shades.
]]
function MineUI.candyTint(inst, thickness, gloss)
	inst.BackgroundTransparency = 0
	MineUI.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.72, 0.72, 0.72)),
	}, inst)
	if thickness ~= 0 then
		MineUI.new("UIStroke", {
			Color = T.OUTLINE,
			Thickness = thickness or T.STROKE_CHUNKY,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, inst)
	end
	if gloss == true then
		local g = MineUI.new("Frame", {
			Name = "Gloss",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			Position = UDim2.new(0.05, 0, 0, 3),
			Size = UDim2.new(0.9, 0, 0.36, 0),
			Active = false,
			ZIndex = inst.ZIndex,
		}, inst)
		MineUI.round(g, 999)
	end
	inst:SetAttribute("MineUIAdopted", true)
	return inst
end

-- White text with a dark outline: readable on any candy colour, at any size.
function MineUI.outlineText(label, thickness)
	MineUI.new("UIStroke", {
		Color = T.OUTLINE,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
	}, label)
	label.TextColor3 = T.ON_CANDY
	return label
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
	MineUI.round(f, T.RADIUS_LG + 4)
	MineUI.edge(f, T.EDGE, 3)
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
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(math.max(72, #tostring(str) * 10 + 28), 28),
		Position = pos or UDim2.fromOffset(0, 0),
	}, parent)
	MineUI.round(p, 999)
	MineUI.candy(p, tint or T.ACCENT, 2)
	local l = MineUI.text(p, tostring(str), 14, T.ON_CANDY, T.FONT)
	l.TextXAlignment = Enum.TextXAlignment.Center
	MineUI.outlineText(l, 1.5)
	return p
end

--[[
	BUTTON: a chunky candy button. `primary` is GOLD (the one call to action);
	otherwise `tint` (a T.CANDY key or Color3), else violet. Juiced: hover grows,
	press squashes. Returns the button and its label.
]]
function MineUI.button(parent, str, size, pos, primary, tint)
	local key = tint or (primary and "gold" or "purple")
	local b = MineUI.new("TextButton", {
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Size = size or UDim2.fromOffset(180, 52),
		Position = pos or UDim2.fromOffset(0, 0),
	}, parent)
	MineUI.round(b, 16)
	MineUI.candy(b, key)
	local l = MineUI.text(b, tostring(str), 20, T.ON_CANDY, T.FONT)
	l.TextXAlignment = Enum.TextXAlignment.Center
	MineUI.outlineText(l, 2)
	MineUI.juice(b)
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
