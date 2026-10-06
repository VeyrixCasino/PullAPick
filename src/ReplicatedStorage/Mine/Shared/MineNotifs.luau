--[[
	MineNotifs -- red dots / number badges for unfinished claimables.

	count == 1  -> plain red dot
	count > 1   -> number badge
	count == 0  -> hide
]]

local MineNotifs = {}

-- The pass track itself: rungs where free deliberately pays nothing must not
-- count as "claimable" or the badge inflates and can never be cleared.
local Scrolls = require(script.Parent:WaitForChild("MineScrolls"))

local function mkBadge(parent)
	local existing = parent:FindFirstChild("NotifBadge")
	if existing then
		return existing
	end
	local b = Instance.new("Frame")
	b.Name = "NotifBadge"
	b.AnchorPoint = Vector2.new(1, 0)
	-- Sits ON the top-right corner, half outside the plate, the way a
	-- notification badge is expected to read. It used to be inset two pixels
	-- INSIDE the plate, which made it look like part of the button's label
	-- rather than a badge attached to it.
	--
	-- Hanging outside only works if the plate does not clip, so clear that
	-- here: a button carrying a badge never wants its badge cropped.
	b.Position = UDim2.new(1, 6, 0, -6)
	-- ClipsDescendants, with the s. It was ClipDescendants here and nowhere
	-- else in the codebase, so every badge threw "ClipDescendants is not a
	-- valid member of TextButton" on creation -- a real error on every client
	-- load, which meant the badge never got its clipping cleared either.
	if parent:IsA("GuiObject") and parent.ClipsDescendants then
		parent.ClipsDescendants = false
	end
	b.Size = UDim2.fromOffset(18, 18)
	b.BackgroundColor3 = Color3.fromRGB(220, 48, 48)
	b.BorderSizePixel = 0
	b.ZIndex = 80
	b.Visible = false
	b.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = b
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Count"
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.BuilderSansBold
	lbl.TextSize = 11
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Text = ""
	lbl.ZIndex = 81
	lbl.Parent = b
	return b
end

function MineNotifs.set(parent, count)
	if not parent then
		return
	end
	count = math.floor(tonumber(count) or 0)
	local b = mkBadge(parent)
	if count <= 0 then
		b.Visible = false
		return
	end
	b.Visible = true
	local lbl = b:FindFirstChild("Count")
	if count == 1 then
		b.Size = UDim2.fromOffset(12, 12)
		if lbl then
			lbl.Text = ""
		end
	else
		-- Wider for 2 digits so "25" stays inside the cell instead of spilling
		-- into the dock button below.
		local w = (count >= 10) and 22 or 18
		b.Size = UDim2.fromOffset(w, 18)
		if lbl then
			lbl.Text = count > 99 and "99+" or tostring(count)
		end
	end
end

-- Counts claimable things from a snapshot (+ optional mergeReady count).
function MineNotifs.counts(snap, extra)
	extra = extra or {}
	local out = {
		merge = math.max(0, math.floor(tonumber(extra.mergeReady) or 0)),
		pass = 0,
		daily = 0,
		quest = 0,
		milestone = 0,
		contract = 0,
	}
	if type(snap) ~= "table" then
		return out
	end
	local pass = snap.pass
	if type(pass) == "table" then
		local tier = math.floor(tonumber(pass.tier) or 0)
		local owned = pass.owned and true or false
		local free = pass.free or {}
		local prem = pass.prem or {}
		for n = 1, math.floor(tonumber(pass.tiers) or 10) do
			local row = Scrolls.PASS_TRACK and Scrolls.PASS_TRACK[n]
			if tier >= n and row then
				if row.free and not (free[n] or free[tostring(n)]) then
					out.pass += 1
				end
				if owned and row.premium and not (prem[n] or prem[tostring(n)]) then
					out.pass += 1
				end
			end
		end
	end
	if type(snap.daily) == "table" and snap.daily.ready then
		out.daily += 1
	end
	for _, q in ipairs(snap.dailyQuests or {}) do
		if q.ready then
			out.daily += 1
		end
	end
	if type(snap.quest) == "table" and snap.quest.ready then
		out.quest += 1
	end
	for _, m in ipairs(snap.milestones or {}) do
		if m.ready then
			out.milestone += 1
		end
	end
	for _, c in ipairs(snap.contracts or {}) do
		if c.ready then
			out.contract += 1
		end
	end
	local nPacks = (type(snap.packs) == "table") and #snap.packs or 0
	local u = snap.upgrades
	local nUp = u and ((tonumber(u.gear) or 0) + (tonumber(u.pets) or 0)) or 0
	-- The pass has its own dock button now, so its count rides that badge;
	-- merge / packs / upgrades live inside Inventory, so they share one dock badge.
	-- (A second UpgradeBadge used to stack on NotifBadge and cover the icon.)
	out.inventory = out.daily + out.quest + out.milestone + out.contract + out.merge + nPacks + nUp
	return out
end

-- Apply badges to dock buttons keyed by label Text, and optional inventory rail.
function MineNotifs.apply(snap, hooks)
	hooks = hooks or {}
	local counts = MineNotifs.counts(snap, hooks)
	if hooks.dock then
		local byLabel = {}
		for _, child in ipairs(hooks.dock:GetChildren()) do
			if child:IsA("GuiButton") then
				for _, d in ipairs(child:GetDescendants()) do
					if d:IsA("TextLabel") and d.Text ~= "" and not byLabel[d.Text] then
						byLabel[d.Text] = child
						break
					end
				end
			end
		end
		MineNotifs.set(byLabel["Merge"], counts.merge)
		MineNotifs.set(byLabel["Pass"], counts.pass)
		MineNotifs.set(byLabel["Inventory"], counts.inventory)
	end
	if hooks.setRail then
		hooks.setRail({
			pass = counts.pass,
			daily = counts.daily,
			milestone = counts.milestone,
			inventory = 0,
		})
	end
	return counts
end

return MineNotifs
