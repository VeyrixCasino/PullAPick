--[[
	MineTheme -- one palette and one type pair for the whole game.

	Before this, every screen invented its own: the shop was warm brown, the
	rune roller was blue-violet, the sockets tab beside it was warm brown again
	but two shades off, the inventory was neutral charcoal, the panel shells
	were a different neutral charcoal, and the client's "gold" was a dull tan
	while every other module's was bright. Five type families were in play at
	once. One click moved you between what looked like different games, and
	that is most of what "it doesn't look professional" means.

	The house style is warm dark with a gold accent -- the workshop look, which
	is the screen that already worked -- with FredokaOne carrying every number
	and title and BuilderSans carrying prose.

	Add a colour here, not in a view. If a view needs a one-off, it should be a
	tint applied over a token, not a new constant.
]]

local MineTheme = {}

-- TYPE. Display face for anything you read at a glance: titles, prices,
-- counts, button captions. Body face for anything you actually read.
MineTheme.FONT = Enum.Font.FredokaOne
MineTheme.FONT_M = Enum.Font.BuilderSansMedium
MineTheme.FONT_B = Enum.Font.BuilderSansBold

-- SURFACES, darkest to lightest. INK is the page, PANEL is a window on it,
-- CARD is a row or tile, CARD_HI is that tile under the cursor or selected.
MineTheme.INK = Color3.fromRGB(26, 21, 18)
MineTheme.PANEL = Color3.fromRGB(38, 30, 25)
MineTheme.CARD = Color3.fromRGB(54, 42, 34)
MineTheme.CARD_HI = Color3.fromRGB(78, 60, 46)
MineTheme.LINE = Color3.fromRGB(92, 72, 56)
MineTheme.DEAD = Color3.fromRGB(58, 52, 48)

-- INK-adjacent aliases, so a view that thinks in BG/BG2/BG3 can map straight
-- across without renaming every use site.
MineTheme.BG = MineTheme.PANEL
MineTheme.BG2 = MineTheme.CARD
MineTheme.BG3 = MineTheme.INK

-- TEXT.
MineTheme.TEXT = Color3.fromRGB(248, 240, 228)
MineTheme.MUTED = Color3.fromRGB(186, 168, 148)
MineTheme.FAINT = Color3.fromRGB(126, 112, 98)

-- CURRENCIES. These are the only colours allowed to mean a specific thing, and
-- they must match the icons and the floating pickup text.
MineTheme.GOLD = Color3.fromRGB(255, 206, 92)   -- coins, and the primary accent
MineTheme.GEM = Color3.fromRGB(122, 226, 255)
MineTheme.DUST = Color3.fromRGB(210, 160, 255)
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
