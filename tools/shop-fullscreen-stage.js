// Make the shop's 3D preview the whole screen, with the UI floating over it.
//
// The viewport was a child of `card` sized 1 x 0.62 of it, with a solid dark
// backdrop painted three separate times -- the last write winning. That box was
// the thing making the shop read as a window rather than a stage.
const fs = require("fs"), path = require("path");
const F = path.join(__dirname, "..", "src/ReplicatedStorage/Mine/Shared/MineShopView.luau");
const raw = fs.readFileSync(F, "utf8");
const crlf = raw.indexOf("\r\n") >= 0;
let s = raw.split("\r\n").join("\n");
function one(old, nw) {
  const n = s.split(old).length - 1;
  if (n !== 1) throw new Error("count " + n + " for: " + old.slice(0, 70));
  s = s.replace(old, nw);
}

// ---------- 1. the viewport becomes the bottom layer of the whole panel ----------
one(`	-- Clear viewport so the shop background shows around the tool/pedestal.
	local vp = mk("ViewportFrame", {
		Name = "Preview",
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 0.72),
		BackgroundColor3 = Color3.fromRGB(14, 18, 26),
		BackgroundTransparency = 0.4,
		Ambient = Color3.fromRGB(170, 178, 198),
		LightColor = Color3.fromRGB(255, 248, 230),
		LightDirection = Vector3.new(-0.4, -1, -0.55),
		ZIndex = 84,
		BorderSizePixel = 0,
	}, card)`,
`	--[[
		THE STAGE IS THE SCREEN.

		This used to be a 1 x 0.62 box inside \`card\` with a solid backdrop, so
		the shop read as a window with a picture in it. It is the bottom layer of
		the whole panel now: edge to edge, no backdrop, no chrome, parented to
		\`root\` rather than \`card\` so the card's own bounds cannot clip it.

		Everything else in the shop draws on top. ZIndex 2 leaves room for a
		backdrop beneath if one is ever wanted, and every control already sits in
		the 80s and above.
	]]
	local vp = mk("ViewportFrame", {
		Name = "Preview",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 178, 198),
		LightColor = Color3.fromRGB(255, 248, 230),
		LightDirection = Vector3.new(-0.4, -1, -0.55),
		ZIndex = 2,
		BorderSizePixel = 0,
	}, root)`);

// ---------- 2. stop repainting the backdrop further down ----------
one(`	vp.Position = UDim2.fromScale(0, 0)
	vp.Size = UDim2.fromScale(1, 0.62)
	vp.BackgroundTransparency = 1
`, "");

one(`	vp.BackgroundColor3 = Color3.fromRGB(34, 26, 22)
	vp.BackgroundTransparency = 0
`, `	-- No backdrop, ever. The shop's own background art is what sits behind the
	-- pedestal; painting a colour here is what produced the dark rectangle.
	vp.BackgroundTransparency = 1
`);

// ---------- 3. the ground disc must never show its rim ----------
one(`		-- Soft ground disc so the pedestal doesn't float in the void.
		local ground = slab(Vector3.new(36, 0.4, 36),
			CFrame.new(0, -14.0, 0),
			Color3.fromRGB(28, 32, 40), Enum.Material.SmoothPlastic)
		ground.Name = "GroundDisc"
		ground.Transparency = 0.35`,
`		--[[
			No ground slab.

			At 36 studs it fitted inside the old letterbox, but full screen its
			rim crosses the frame as a hard horizon line -- a floating slab edge
			with nothing under it. Growing it only moves the edge further out;
			at some aspect ratio it always reappears. The plinth alone reads as
			an object on a surface, so the slab goes.
		]]`);

// ---------- 4. aspect-aware framing, centred in the free band ----------
one(`		local reach = math.max(size.X, size.Y, size.Z)
		shown:SetAttribute("Dist", reach * 1.30 + 3.6)
		shown:SetAttribute("Cx", centre.Position.X)
		shown:SetAttribute("Cy", centre.Position.Y)
		shown:SetAttribute("Cz", centre.Position.Z)`,
`		--[[
			Radius, not longest side.

			Distance is fitted against the bounding SPHERE of the plinth plus the
			tool, because the camera orbits: a pick that fits the frame face-on
			swings wider when you drag it side-on, and fitting the longest edge
			alone crops it mid-turn.

			The plinth is 18 studs across and sits 13 below the origin, so it has
			to be in the box or the pedestal falls out of frame on tall screens.
		]]
		local half = size * 0.5
		local toTop = math.max(math.abs(centre.Position.Y + half.Y), 1)
		local plinthReach = math.sqrt(9 * 9 + 14 * 14)
		local radius = math.max(half.Magnitude, toTop, plinthReach)
		shown:SetAttribute("Radius", radius)
		shown:SetAttribute("Cx", centre.Position.X)
		shown:SetAttribute("Cy", centre.Position.Y)
		shown:SetAttribute("Cz", centre.Position.Z)
		frameStage()`);

// ---------- 5. the framing pass itself, before setModel uses it ----------
one(`	local rows -- forward-declared: setModel below calls it, definition is further down
	local shown, sway = nil, 0`,
`	local rows -- forward-declared: setModel below calls it, definition is further down
	local shown, sway = nil, 0

	--[[
		FRAMING.

		Two jobs, both driven off the real pixel shape rather than constants.

		Distance: a ViewportFrame's FieldOfView is VERTICAL, so on a portrait
		phone the horizontal angle is much narrower and a box fitted to the
		vertical FOV runs off the sides. Horizontal FOV is
		2*atan(tan(v/2) * aspect); fitting against the SMALLER of the two means a
		narrow screen zooms out instead of cropping the tool.

		Height: the tool must not sit behind the name, price, stats or BUY. The
		free band is measured from the real AbsolutePosition of the header and of
		the topmost thing in the bottom stack, and the camera target is nudged so
		the pedestal lands in the middle of THAT, not the middle of the screen.
	]]
	local FIT_MARGIN = 1.15
	local aimOffsetY = 0

	local function frameStage()
		local px = vp.AbsoluteSize
		if px.X < 2 or px.Y < 2 then
			return
		end
		local aspect = px.X / math.max(1, px.Y)
		local vFov = math.rad(cam.FieldOfView)
		local hFov = 2 * math.atan(math.tan(vFov * 0.5) * aspect)
		local fov = math.min(vFov, hFov)

		local radius = (shown and shown:GetAttribute("Radius")) or 12
		local dist = radius / math.max(0.05, math.sin(fov * 0.5)) * FIT_MARGIN
		if shown then
			shown:SetAttribute("Dist", dist)
		end

		-- The band the stage may actually use, in pixels down the panel.
		local top = header.AbsoluteSize.Y
		local bottomY = px.Y
		for _, gui in ipairs({ nameLbl, priceLbl, statRow, action, temperBar }) do
			if gui and gui.Visible and gui.AbsoluteSize.Y > 0 then
				local y = gui.AbsolutePosition.Y - vp.AbsolutePosition.Y
				if y > top and y < bottomY then
					bottomY = y
				end
			end
		end
		local bandMid = (top + bottomY) * 0.5
		local screenMid = px.Y * 0.5
		-- Pixels off centre -> world units at the subject's distance.
		local worldPerPx = (2 * dist * math.tan(vFov * 0.5)) / math.max(1, px.Y)
		aimOffsetY = (screenMid - bandMid) * worldPerPx
	end

	vp:GetPropertyChangedSignal("AbsoluteSize"):Connect(frameStage)`);

// ---------- 6. the render loop honours the offset ----------
one(`		cam.CFrame = CFrame.new(centre)
			* CFrame.Angles(0, a, 0) * CFrame.Angles(hero.pitch, 0, 0)
			* CFrame.new(0, 0, shown:GetAttribute("Dist") or 6)`,
`		-- aimOffsetY slides the subject down the frame so it sits in the gap
		-- between the header and the name/stats/BUY stack, not the screen middle.
		cam.CFrame = CFrame.new(centre + Vector3.new(0, aimOffsetY, 0))
			* CFrame.Angles(0, a, 0) * CFrame.Angles(hero.pitch, 0, 0)
			* CFrame.new(0, 0, shown:GetAttribute("Dist") or 6)`);

// ---------- 7. re-frame whenever the furniture moves ----------
one(`	refit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end`,
`	refit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end`);

fs.writeFileSync(F, crlf ? s.split("\n").join("\r\n") : s);
console.log("shop stage is full screen; backdrop and ground slab removed");
