--[[
	PetShowcaseBuilder -- builds workspace.PetShowcase: every pet in the game on
	a plinth, sorted, with a name tag that only shows when you walk up to it.

	Owner, 2026-10-10: "add new pets to the pet display, and sort them all
	(proximity name tags remember that tho)".

	The old PetShowcase was a hand-built rack in the place file and was deleted
	with the other authoring racks in d57fedc. This rebuilds it from the roster,
	so it can never drift from the game again: run it after any pet change.

	Studio, Edit mode, command bar:
		require(game.ServerStorage.PetShowcaseBuilder).build()

	It is AUTHORING ONLY. MineServer destroys workspace.PetShowcase when a live
	server starts (its SHOWCASE list), so players never load it.

	Layout: one block per zone (meadow .. primordium), then Event Horizon, then
	the Halloween bodies, then anything unzoned. Inside a block, one row per
	tier (Common at the front), pets A to Z. Each block's sign shows the zone's
	power step and its Mythic / Divine / Exotic buff set.
]]

local M = {}

M.ORIGIN = Vector3.new(3000, 0, 0) -- far from the world; nothing else is out here
M.SPACING = 6 -- studs between pets in a row
M.ROW_GAP = 8 -- studs between tier rows
M.BLOCK_GAP = 30 -- studs between zone blocks
M.TAG_DISTANCE = 22 -- a pet's tag shows inside this many studs (proximity)

local TIERS = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic" }

-- Studio's command bar caches a module for the whole session, so a second run
-- after an edit would build from stale code. Requiring a fresh clone avoids it.
local function fresh(mod)
	local copy = mod:Clone()
	copy.Name = mod.Name .. "_showcase"
	copy.Parent = mod.Parent
	local ok, result = pcall(require, copy)
	copy:Destroy()
	if not ok then
		error(result)
	end
	return result
end

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.35
	for k, v in pairs(props) do
		l[k] = v
	end
	l.Parent = parent
	return l
end

-- A real banner over the block's front edge, facing the aisle. Not a
-- billboard: eleven of those float through each other from across the rack.
local function sign(parent, at, width, title, sub)
	local board = part({
		Name = "Banner",
		Size = Vector3.new(width, 9, 0.6),
		CFrame = CFrame.new(at),
		Color = Color3.fromRGB(28, 22, 48),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	}, parent)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "BannerGui"
	sg.Face = Enum.NormalId.Front -- -Z, towards the aisle
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	-- TextScaled stops at 100 px, so keep a stud near 10 px or the title is a speck.
	sg.PixelsPerStud = 10
	sg.LightInfluence = 0
	sg.Parent = board
	label(sg, { Text = title, Size = UDim2.new(1, 0, 0.62, 0), TextColor3 = Color3.fromRGB(255, 220, 120) })
	label(sg, { Text = sub or "", Size = UDim2.new(0.96, 0, 0.34, 0), Position = UDim2.fromScale(0.02, 0.62), Font = Enum.Font.GothamBold })
	return board
end

-- "+34% Mine Speed, +12% Swing Rate", as the player sees it at Normal PL1.
local function kitText(kit, tier, Stats, Cfg)
	if type(kit) ~= "table" then
		return ""
	end
	local mult = (Cfg.RARITY_MULT and Cfg.RARITY_MULT[tier]) or 1
	local keys = {}
	for stat in pairs(kit) do
		table.insert(keys, stat)
	end
	table.sort(keys, function(a, b)
		return (kit[a] * ((Stats.STATS[a] or {}).weight or 1)) > (kit[b] * ((Stats.STATS[b] or {}).weight or 1))
	end)
	local out = {}
	for _, stat in ipairs(keys) do
		local pct = kit[stat] * 100 * mult
		local name = (Stats.STATS[stat] and Stats.STATS[stat].label) or stat
		table.insert(out, string.format(pct >= 10 and "+%.0f%% %s" or "+%.1f%% %s", pct, name))
	end
	return table.concat(out, ", ")
end

local function nameTag(model, pet, kitLine, roleText, colour)
	local bb = Instance.new("BillboardGui")
	bb.Name = "PetTag"
	bb.Size = UDim2.fromOffset(190, 74)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.MaxDistance = M.TAG_DISTANCE
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.Adornee = model.PrimaryPart
	bb.Parent = model
	label(bb, { Text = pet.name, Size = UDim2.new(1, 0, 0.36, 0), TextColor3 = colour })
	label(bb, {
		Text = (pet.animal or "") .. "  ·  " .. pet.tier,
		Size = UDim2.new(1, 0, 0.22, 0),
		Position = UDim2.fromScale(0, 0.36),
		Font = Enum.Font.GothamBold,
	})
	label(bb, {
		Text = (roleText ~= "" and (roleText .. ": ") or "") .. kitLine,
		Size = UDim2.new(1, 0, 0.36, 0),
		Position = UDim2.fromScale(0, 0.6),
		Font = Enum.Font.GothamMedium,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(210, 230, 255),
	})
end

function M.build(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
	--[[
		The roster, the kits and the factory each require MineZonePets by name,
		and the command bar would hand them the copy it cached earlier in the
		session -- so a pet generated since then would be missing, or render as
		a fox. For the length of the loads, a fresh copy of the zone data stands
		in under the real name; the original is put back straight after.
	]]
	local zoneData = shared:FindFirstChild("MineZonePets")
	local stand = zoneData and zoneData:Clone()
	if stand then
		zoneData.Name = "MineZonePets_held"
		stand.Parent = shared
	end
	local ok, loaded = pcall(function()
		return {
			Roster = fresh(shared.MinePetRoster),
			PMF = fresh(shared.PetModelFactory),
			Boosts = fresh(shared.MinePetBoosts),
			Zones = fresh(shared.MineZonePets),
		}
	end)
	if stand then
		stand:Destroy()
		zoneData.Name = "MineZonePets"
	end
	if not ok then
		error(loaded)
	end
	local Roster, PMF, Boosts, Zones = loaded.Roster, loaded.PMF, loaded.Boosts, loaded.Zones
	local Stats = require(shared.MineStats)
	local Cfg = require(shared.MineConfig)

	local old = workspace:FindFirstChild("PetShowcase")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "PetShowcase"
	root.Parent = workspace

	-- Groups, in display order.
	local groups = {}
	local byZone = {}
	for i, zoneId in ipairs(Zones.ZONE_ORDER) do
		local buff = Zones.ZONE_BUFFS[zoneId] or {}
		local g = {
			id = zoneId,
			title = string.upper(zoneId),
			sub = string.format("Zone %d  ·  power x%.2f  ·  Mythic/Divine/Exotic: %s (%s)",
				i, Zones.zoneMult(zoneId), buff.name or "?", buff.desc or ""),
			pets = {},
		}
		table.insert(groups, g)
		byZone[zoneId] = g
	end
	local eh = {
		id = "bigbang",
		title = "EVENT HORIZON",
		sub = string.format("Zone 11  ·  power x%.2f  ·  their own 73, each with its own stat mix", Zones.zoneMult(Zones.EVENT_ZONE)),
		pets = {},
	}
	local holidayPets = {}
	local other = { id = "other", title = "NO ZONE", sub = "Pets with no zone pot (should be empty)", pets = {} }
	for _, pet in ipairs(Roster.PETS) do
		-- Ask the zone data directly: it is required fresh above, the roster's own
		-- copy may be a cached one from earlier in the Studio session.
		local zone = Zones.zoneOf(pet.name) or pet.zone
		if Zones.HOLIDAY and Zones.HOLIDAY[pet.name] then
			table.insert(holidayPets, pet)
		elseif zone and byZone[zone] then
			table.insert(byZone[zone].pets, pet)
		elseif zone == Zones.EVENT_ZONE or pet.tierVia == "eh" then
			table.insert(eh.pets, pet)
		else
			table.insert(other.pets, pet)
		end
	end
	table.insert(groups, eh)
	-- Holiday bodies with no roster pet yet: one of each, so they can be judged.
	-- Holiday pets are in no pot and no random roll; only a {Holiday} {year} Pack gives one.
	table.insert(groups, {
		id = "holiday",
		title = "HOLIDAY PETS",
		sub = "Not in the game: only from a {Holiday} {year} Pack (owner, 2026-10-10)",
		pets = holidayPets,
	})
	local holiday = { id = "halloween", title = "HALLOWEEN BODIES", sub = "Bodies only, not pets yet", pets = {}, bodies = true }
	for _, species in ipairs(PMF.HALLOWEEN or {}) do
		table.insert(holiday.pets, { name = species, species = species, tier = "Epic", animal = "" })
	end
	if #holiday.pets > 0 then
		table.insert(groups, holiday)
	end
	if #other.pets > 0 then
		table.insert(groups, other)
	end

	local rank = {}
	for i, t in ipairs(TIERS) do
		rank[t] = i
	end
	local z = 0
	local count = 0
	for _, g in ipairs(groups) do
		table.sort(g.pets, function(a, b)
			if rank[a.tier] ~= rank[b.tier] then
				return (rank[a.tier] or 99) < (rank[b.tier] or 99)
			end
			return a.name < b.name
		end)
		local block = Instance.new("Folder")
		block.Name = g.id
		-- Rows by tier.
		local rows, order = {}, {}
		for _, pet in ipairs(g.pets) do
			if not rows[pet.tier] then
				rows[pet.tier] = {}
				table.insert(order, pet.tier)
			end
			table.insert(rows[pet.tier], pet)
		end
		local widest = 0
		for _, t in ipairs(order) do
			widest = math.max(widest, #rows[t])
		end
		local depth = #order * M.ROW_GAP
		local base = M.ORIGIN + Vector3.new(0, 0, z)
		part({
			Name = "Floor",
			Size = Vector3.new(widest * M.SPACING + 24, 1, depth + 16),
			CFrame = CFrame.new(base + Vector3.new((widest * M.SPACING) / 2 - 2, -0.5, depth / 2 + 2)),
			Color = Color3.fromRGB(46, 40, 70),
			Material = Enum.Material.SmoothPlastic,
		}, block)
		local span = math.max(widest * M.SPACING, 40)
		sign(block, base + Vector3.new(span / 2 - 3, 17, -4), span, g.title, g.sub)
		for r, tier in ipairs(order) do
			local colour = Roster.color(tier)
			local rowZ = (r - 1) * M.ROW_GAP + 4
			local tierSign = part({
				Name = tier .. "Label",
				Size = Vector3.new(1, 1, 1),
				Transparency = 1,
				CanCollide = false,
				CFrame = CFrame.new(base + Vector3.new(-6, 0, rowZ)),
			}, block)
			local tb = Instance.new("BillboardGui")
			tb.Size = UDim2.fromOffset(150, 34)
			tb.StudsOffset = Vector3.new(0, 1.5, 0)
			tb.MaxDistance = 60 -- proximity, like the pet tags
			tb.LightInfluence = 0
			tb.Adornee = tierSign
			tb.Parent = tierSign
			label(tb, { Text = string.upper(tier) .. "  " .. #rows[tier], Size = UDim2.fromScale(1, 1), TextColor3 = colour })
			for c, pet in ipairs(rows[tier]) do
				local at = base + Vector3.new((c - 1) * M.SPACING, 0, rowZ)
				part({
					Name = "Plinth",
					Size = Vector3.new(3.4, 0.6, 3.4),
					CFrame = CFrame.new(at + Vector3.new(0, 0.3, 0)),
					Color = colour,
					Material = Enum.Material.SmoothPlastic,
				}, block)
				local ok, model = pcall(function()
					if g.bodies then
						return PMF.build({ species = pet.species, rarity = "Common", name = pet.name })
					end
					return PMF.build({ animal = pet.animal, rarity = pet.tier, name = pet.name })
				end)
				if ok and model then
					local _, size = model:GetBoundingBox()
					-- Face the aisle at the front of the block (towards -Z).
					model:PivotTo(CFrame.new(at + Vector3.new(0, 0.6 + size.Y / 2, 0)) * CFrame.Angles(0, math.pi, 0))
					local kit = Boosts.boostsFor(pet.name)
					local role = (Zones.ROLE and Zones.ROLE[pet.name]) or ""
					nameTag(model, pet, g.bodies and "" or kitText(kit, pet.tier, Stats, Cfg), role, colour)
					model.Parent = block
					count += 1
				else
					warn("[PetShowcase] could not build " .. tostring(pet.name) .. ": " .. tostring(model))
				end
			end
		end
		block.Parent = root -- one block at a time, so no single insert is huge
		z += depth + 16 + M.BLOCK_GAP
		task.wait()
	end
	print(string.format("[PetShowcase] %d pets in %d groups at %s", count, #groups, tostring(M.ORIGIN)))
	return root, count
end

return M
