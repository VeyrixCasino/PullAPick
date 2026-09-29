// Put the 3D tools back on screen, draw a real backdrop, and show every currency.
//
// THE BUG. The shop rendered nothing but a flat background. `shopBg` is an
// opaque ImageLabel at ZIndex 80 carrying a zone painting, and the ScreenGui
// runs ZIndexBehavior.Sibling (MineClient.client.luau:82) -- so among root's
// children it draws AFTER, and therefore over, every sibling with a lower
// ZIndex. Three things sat below it:
//
//     Preview (the 3D stage)   ZIndex 2   <- the tools
//     Tabs    (the tab strip)  ZIndex 41  <- the browse/sort options
//     TemperPicker             ZIndex 70
//
// All three were painted over by one plate. That is why the tools vanished AND
// why the sort options went with them; it was never a camera or a model fault.
//
// The plate also has to go because it was asked for twice. What replaces it is
// drawn, not photographed, and every layer of it stays under ZIndex 4.
const fs = require("fs"), path = require("path");
const F = path.join(__dirname, "..", "src/ReplicatedStorage/Mine/Shared/MineShopView.luau");
const raw = fs.readFileSync(F, "utf8");
const crlf = raw.indexOf("\r\n") >= 0;
let s = raw.split("\r\n").join("\n");

function one(old, nw) {
  const n = s.split(old).length - 1;
  if (n !== 1) throw new Error("expected 1 match, got " + n + " for: " + old.slice(0, 80));
  s = s.replace(old, nw);
}
// Replace an inclusive span, so leading whitespace inside it never has to be
// reproduced byte for byte in this file.
function block(startNeedle, endNeedle, nw) {
  const a = s.indexOf(startNeedle);
  if (a < 0) throw new Error("start not found: " + startNeedle);
  if (s.indexOf(startNeedle, a + 1) >= 0) throw new Error("start not unique: " + startNeedle);
  const b = s.indexOf(endNeedle, a + startNeedle.length);
  if (b < 0) throw new Error("end not found after start: " + endNeedle);
  s = s.slice(0, a) + nw + s.slice(b + endNeedle.length);
}

// ---------------------------------------------------------------- 1. the plate
one(`local ShopBgArt = require(shared:WaitForChild("MineShopBackgrounds"))\n`, "");

one(`		-- Surface blacksmith uses the zone's surface shop painting.
		ShopBgArt.apply(shopBg, state.zoneId or "meadow", 0)
`, "");

block(`	-- Full-bleed theme plate.`, `	}, veil)`,
`	--[[
		THE BACKDROP IS DRAWN, NOT PHOTOGRAPHED.

		What used to be here was \`shopBg\`: an OPAQUE ImageLabel at ZIndex 80
		holding a zone painting. This ScreenGui runs ZIndexBehavior.Sibling, so
		among root's children that plate drew over every sibling beneath it --
		the 3D stage at 2, the tab strip at 41 and the temperament picker at 70.
		One plate is why the shop showed a background and nothing else, and why
		the sort options disappeared along with the tools.

		Three cheap layers replace it, none above ZIndex 3, so the stage and
		every control are unambiguously in front:

		  1. a vertical gradient, cold night at the top falling into forge
		     ember at the bottom, so the room has a floor without a floor being
		     modelled;
		  2. a soft warm disc low and centred, where the plinth stands, so the
		     tool reads as lit by the hearth rather than pasted on a gradient;
		  3. a vignette that pulls the corners down and puts the eye on the
		     pedestal.

		No image means nothing to load, nothing to own, and no zone whose
		painting is missing.
	]]
	local backdrop = mk("Frame", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 22, 34),
		ZIndex = 1,
		BorderSizePixel = 0,
	}, root)
	mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(9, 11, 20)),
			ColorSequenceKeypoint.new(0.42, Color3.fromRGB(24, 23, 33)),
			ColorSequenceKeypoint.new(0.76, Color3.fromRGB(56, 36, 29)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(88, 50, 27)),
		}),
		Rotation = 90,
	}, backdrop)

	local glow = mk("Frame", {
		Name = "ForgeGlow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.76),
		Size = UDim2.fromScale(0.92, 0.66),
		BackgroundColor3 = Color3.fromRGB(255, 152, 64),
		BackgroundTransparency = 0.8,
		ZIndex = 2,
		BorderSizePixel = 0,
	}, root)
	mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, glow)
	mk("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.55, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 90,
	}, glow)

	local vignette = mk("Frame", {
		Name = "Vignette",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(4, 5, 10),
		BackgroundTransparency = 0.5,
		ZIndex = 3,
		BorderSizePixel = 0,
	}, root)
	mk("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.45, 0.95),
			NumberSequenceKeypoint.new(1, 0.1),
		}),
		Rotation = 90,
	}, vignette)`);

// -------------------------------------------- 2. the stage sits above the art
one(`		LightDirection = Vector3.new(-0.4, -1, -0.55),
		ZIndex = 2,
		BorderSizePixel = 0,
	}, root)`,
`		LightDirection = Vector3.new(-0.4, -1, -0.55),
		-- Above the three backdrop layers (1-3), below every control (41+).
		-- This was 2, i.e. under the old background plate, which is what made
		-- the tools invisible.
		ZIndex = 5,
		BorderSizePixel = 0,
	}, root)`);

// ------------------------------------- 3. nothing may hide under the backdrop
one(`		Name = "Tabs", Position = UDim2.fromOffset(0, 84), Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1, ZIndex = 41,`,
`		Name = "Tabs", Position = UDim2.fromOffset(0, 98), Size = UDim2.new(1, 0, 0, 44),
		-- Was 41: under the old ZIndex-80 plate, so the whole browse row was
		-- painted over. Above the stage now, where a tab strip belongs.
		BackgroundTransparency = 1, ZIndex = 84,`);

one(`		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(580, 440),
		BackgroundColor3 = INK, ZIndex = 70,`,
`		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(580, 440),
		-- Was 70, i.e. behind the old plate: a modal nothing could see. It has
		-- to outrank the header (90) and the temperament bar (85) it opens from.
		BackgroundColor3 = INK, ZIndex = 92,`);

// ------------------------------------------------ 4. a distance always exists
one(`		shown:SetAttribute("Radius", radius)`,
`		shown:SetAttribute("Radius", radius)
		--[[
			A DISTANCE THAT IS ALWAYS SET.

			frameStage() does the real fitting, but it returns early while the
			panel has no pixels -- and on the frame the shop opens,
			vp.AbsoluteSize is (0, 0). Dist was written ONLY in there, so the
			render loop fell through to \`or 6\`: six studs from the middle of a
			plinth eighteen across, which is a camera inside the pedestal.

			Seeded from the radius alone here, so the first frame already looks
			at the tool from outside it and frameStage only ever refines this.
		]]
		shown:SetAttribute("Dist",
			radius / math.max(0.05, math.sin(math.rad(cam.FieldOfView) * 0.5)) * FIT_MARGIN)`);

// -------------------------------------------- 5. the header, and the logo down
one(`		Name = "Header", Size = UDim2.new(1, 0, 0, 64),`,
`		-- 64 -> 78: the title sat 11px off the top edge, crowding it. The extra
		-- height is what the logo moves down into rather than overlapping the
		-- blurb underneath it.
		Name = "Header", Size = UDim2.new(1, 0, 0, 78),`);

one(`		BackgroundTransparency = 1, Position = UDim2.fromOffset(26, 11),
		Size = UDim2.fromOffset(340, 30), Font = FONT, TextSize = 26, TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "BLACKSMITH", ZIndex = 83,`,
`		BackgroundTransparency = 1, Position = UDim2.fromOffset(26, 22),
		Size = UDim2.fromOffset(340, 30), Font = FONT, TextSize = 26, TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "BLACKSMITH", ZIndex = 86,`);

one(`		BackgroundTransparency = 1, Position = UDim2.fromOffset(26, 39),
		Size = UDim2.fromOffset(560, 20), Font = FONT_M, TextSize = 14, TextColor3 = MUTED,`,
`		BackgroundTransparency = 1, Position = UDim2.fromOffset(26, 50),
		Size = UDim2.fromOffset(560, 20), Font = FONT_M, TextSize = 14, TextColor3 = MUTED,`);

// ------------------------------------------------------------- 6. five wallets
block(`	local function chip(x, tint, name)`, `	local creditLbl = chip(-382, CREDIT, "CreditDot")`,
`	--[[
		THE WALLET SHOWS WHAT THIS BUILDING SPENDS.

		Three chips, and two of the currencies the blacksmith actually takes
		were not among them: stardust pays for tool levels and temperament
		tokens pay for rolls, so a player had to leave the shop to find out
		whether they could afford what was in front of them.

		The old chips were pinned at hard-coded offsets (-74, -228, -382). Two
		more at that pitch would run under the BLACKSMITH title, so the row is a
		right-aligned UIListLayout instead: chips place themselves, the row grows
		leftward, and a sixth currency later costs no arithmetic.

		The tinted circle is gone. Every one of these has real art in MineIcons
		-- the same source Icons.priceChip already draws from everywhere else in
		the game -- so a coloured dot here was the odd one out.
	]]
	local DUST_TINT = Color3.fromRGB(178, 150, 255)
	local TOKEN_TINT = Color3.fromRGB(255, 178, 94)

	local wallet = mk("Frame", {
		Name = "Wallet",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -84, 0, 19),
		Size = UDim2.fromOffset(716, 40),
		BackgroundTransparency = 1,
		ZIndex = 86,
	}, header)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, wallet)

	local function chip(order, tint, iconId, name)
		local f = mk("Frame", {
			Name = name,
			Size = UDim2.fromOffset(132, 40),
			BackgroundColor3 = Color3.fromRGB(32, 37, 56),
			BackgroundTransparency = 0.05,
			LayoutOrder = order,
			ZIndex = 86,
			BorderSizePixel = 0,
		}, wallet)
		round(f, 12)
		stroke(f, 1.5, tint, 0.45)
		-- Icons.draw returns a holder whose ZIndex defaults low; the chip is at
		-- 86, so anything inside it has to be raised or the art hides behind the
		-- chip's own fill.
		local ok, holder = pcall(function()
			return Icons.icon(f, iconId, UDim2.fromOffset(26, 26), UDim2.fromOffset(7, 7))
		end)
		if ok and holder then
			holder.ZIndex = 87
			for _, d in ipairs(holder:GetDescendants()) do
				if d:IsA("GuiObject") then
					d.ZIndex = 87
				end
			end
		else
			-- No art for this id: fall back to the old dot rather than a blank.
			local dot = mk("Frame", {
				Position = UDim2.fromOffset(9, 11), Size = UDim2.fromOffset(18, 18),
				BackgroundColor3 = tint, ZIndex = 87, BorderSizePixel = 0,
			}, f)
			round(dot, 9)
		end
		return mk("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(40, 0),
			Size = UDim2.new(1, -48, 1, 0), Font = FONT, TextSize = 16, TextColor3 = TEXT,
			TextXAlignment = Enum.TextXAlignment.Left, Text = "0", ZIndex = 87,
		}, f)
	end
	local coinLbl = chip(1, GOLD, "coins", "Coins")
	local gemLbl = chip(2, GEM, "gems", "Gems")
	local dustLbl = chip(3, DUST_TINT, "dust", "Stardust")
	local tokenLbl = chip(4, TOKEN_TINT, "tokens", "Tokens")
	local creditLbl = chip(5, CREDIT, "credits", "Credits")`);

one(`		creditLbl.Text = money(state.credits or 0)
		coinLbl.Text = money(state.coins or 0)
		gemLbl.Text = money(state.gems or 0)`,
`		creditLbl.Text = money(state.credits or 0)
		coinLbl.Text = money(state.coins or 0)
		gemLbl.Text = money(state.gems or 0)
		dustLbl.Text = money(state.dust or 0)
		tokenLbl.Text = money(state.tokens or 0)`);

one(`		state.coins = snapshot.coins or 0
		state.gems = snapshot.gems or 0`,
`		state.coins = snapshot.coins or 0
		state.gems = snapshot.gems or 0
		state.dust = snapshot.dust or 0
		-- Temperament tokens ride in the skills payload, not at the top level
		-- (MineServer builds them as skillEarned + skillBought - burned - spent).
		state.tokens = snapshot.tokens
			or (snapshot.skills and snapshot.skills.tokens)
			or 0`);

one(`	local state = { coins = 0, gems = 0, credits = 0,`,
`	local state = { coins = 0, gems = 0, credits = 0, dust = 0, tokens = 0,`);

fs.writeFileSync(F, crlf ? s.split("\n").join("\r\n") : s);
console.log("stage restored above the backdrop; plate removed; wallet is five chips");
