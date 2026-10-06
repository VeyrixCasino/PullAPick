--[[
	MineTheme -- one palette and one type pair for the whole game.

	Before this, every screen invented its own: the shop was warm brown, the
	rune roller was blue-violet, the sockets tab beside it was warm brown again
	but two shades off, the inventory was neutral charcoal, the panel shells
	were a different neutral charcoal, and the client's "gold" was a dull tan
	while every other module's was bright. Five type families were in play at
	once. One click moved you between what looked like different games, and
	that is most of what "it doesn't look professional" means.

	THE HOUSE STYLE IS COOL DARK INDIGO WITH GOLD AND VIOLET.

	It was warm brown with a single gold accent -- the workshop look. Owner,
	2026-10-05, supplied a reference shop screen and asked for it to become the
	game's style: a deep indigo page, violet-lit panels, gold reserved for the
	title and the one primary action, cyan for tier and gems, violet for
	selection and rarity.

	Every value below is sampled from that reference rather than invented, which
	is the point -- the previous palette was five screens inventing their own and
	this is the one place that stops happening again.

	WHAT THIS FILE CAN AND CANNOT DO. Twenty-five modules read it, so a colour
	change here restyles the whole game at once. It does NOT restyle LAYOUT --
	the reference's left rail, hero card and tile row are view work on top of
	this, screen by screen.

	Add a colour here, not in a view. If a view needs a one-off, it should be a
	tint applied over a token, not a new constant.
]]

local MineTheme = {}

-- TYPE. Display face for anything you read at a glance: titles, prices,
-- counts, button captions. Body face for anything you actually read.
--
-- The display face was FredokaOne -- rounded and bubbly. The reference is a
-- clean geometric sans, so the display weight is BuilderSansBold now and the
-- rounding is carried by the CORNERS instead of the letterforms. Roblox has no
-- Poppins/Outfit, and BuilderSans is the closest thing it ships.
MineTheme.FONT = Enum.Font.BuilderSansBold
MineTheme.FONT_M = Enum.Font.BuilderSansMedium
MineTheme.FONT_B = Enum.Font.BuilderSansBold

-- SURFACES, darkest to lightest. INK is the page, PANEL is a window on it,
-- CARD is a row or tile, CARD_HI is that tile under the cursor or selected.
MineTheme.INK = Color3.fromRGB(11, 10, 26)
MineTheme.PANEL = Color3.fromRGB(23, 19, 51)
MineTheme.CARD = Color3.fromRGB(34, 28, 78)
MineTheme.CARD_HI = Color3.fromRGB(58, 42, 124)
MineTheme.LINE = Color3.fromRGB(58, 53, 112)
MineTheme.DEAD = Color3.fromRGB(45, 42, 85)

-- The violet the reference lights every panel edge and selection with. GOLD is
-- still the primary accent -- the title and the one call to action -- and this
-- is the SECONDARY: selection, rarity, focus, the glow on an active tab.
MineTheme.ACCENT = Color3.fromRGB(168, 85, 247)
MineTheme.ACCENT_DIM = Color3.fromRGB(124, 58, 237)
-- Panel edges in the reference are a lit hairline, not a neutral grey.
MineTheme.EDGE = Color3.fromRGB(75, 63, 147)

-- INK-adjacent aliases, so a view that thinks in BG/BG2/BG3 can map straight
-- across without renaming every use site.
MineTheme.BG = MineTheme.PANEL
MineTheme.BG2 = MineTheme.CARD
MineTheme.BG3 = MineTheme.INK

-- TEXT. Cool now, to sit on indigo rather than brown.
MineTheme.TEXT = Color3.fromRGB(236, 234, 255)
MineTheme.MUTED = Color3.fromRGB(154, 149, 201)
MineTheme.FAINT = Color3.fromRGB(106, 100, 150)

-- CURRENCIES. These are the only colours allowed to mean a specific thing, and
-- they must match the icons and the floating pickup text.
MineTheme.GOLD = Color3.fromRGB(255, 194, 77)   -- coins, and the primary accent
MineTheme.GEM = Color3.fromRGB(72, 214, 255)
MineTheme.DUST = Color3.fromRGB(192, 132, 252)
MineTheme.CREDIT = Color3.fromRGB(196, 162, 255)

-- STATE.
MineTheme.GREEN = Color3.fromRGB(112, 226, 148) -- affordable, ready, owned
MineTheme.RED = Color3.fromRGB(255, 122, 122)   -- blocked, cannot afford
MineTheme.GOOD = MineTheme.GREEN
MineTheme.BAD = MineTheme.RED

-- Text that sits on top of a GOLD fill. Gold on white is unreadable; every
-- selected chip in the game needs this and three of them had hand-picked it.
MineTheme.ON_GOLD = Color3.fromRGB(38, 28, 12)

-- SHAPE. Radii and stroke weights, so corners stop drifting panel to panel.
MineTheme.RADIUS = 10
MineTheme.RADIUS_SM = 8
MineTheme.RADIUS_LG = 14
MineTheme.STROKE = 1.5

-- The smallest text the game is allowed to draw. Below this it is decoration,
-- not a label, and on a phone it is nothing at all.
MineTheme.TEXT_MIN = 12
MineTheme.TEXT_BODY = 14
MineTheme.TEXT_TITLE = 22

return MineTheme
