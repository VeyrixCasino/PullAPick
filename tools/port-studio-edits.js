// Port this session's Studio-only edits into the Rojo source, so the files are
// the superset and a Rojo push cannot silently revert them.
const fs = require("fs"), path = require("path");
const R = path.join(__dirname, "..", "src");
const CFG = path.join(R, "ReplicatedStorage/Mine/Shared/MineConfig.luau");
const MS = path.join(R, "ServerScriptService/Mine/MineServer.server.luau");
const MC = path.join(R, "StarterPlayer/StarterPlayerScripts/MineClient.client.luau");

function edit(file, fn) {
  const before = fs.readFileSync(file, "utf8");
  const after = fn(before);
  if (after === before) throw new Error("no change: " + file);
  fs.writeFileSync(file, after);
  console.log("ok " + path.basename(file));
}
function one(s, old, nw) {
  const n = s.split(old).length - 1;
  if (n !== 1) throw new Error("count " + n + " for " + old.slice(0, 60));
  return s.replace(old, nw);
}

// 1. mine pushed back: radius 200 -> 300
edit(CFG, s => one(s,
`		-- Sit the starter pit on the lobby lawn's +Z edge so spawn-to-mine
		-- is a short walk, not a 270-stud hike. \`island\` is smaller than the
		-- far-zone plates so the dirt does not swallow the shops.
		radius = 200,`,
`		-- Sit the starter pit out on the lobby lawn's +Z side so spawn-to-mine
		-- is a walk, not a teleport. \`island\` is smaller than the far-zone
		-- plates so the dirt does not swallow the shops.
		--
		-- Was 200, which put the island edge at Z 128 against a lobby deck
		-- that ends at 135 -- the two overlapped, and WorldBuilder's gate
		-- (origin - dir * (island - 8)) landed at Z 136, right on the deck
		-- rim. The pit's near edge was also being clipped by LOBBY_MAX.Z=150.
		-- At 300 the gate sits at 236 and the island starts at 228, clear of
		-- both, and the approach reads as a road instead of a doorstep.
		radius = 300,`));

// 2. name the ore on the block itself
edit(MS, s => one(s,
`		part:SetAttribute("OreTier", oreDef.tier)`,
`		part:SetAttribute("OreTier", oreDef.tier)
		--[==[
			Name the ore on the block itself.

			The server has always stamped OreId / OreName / OreTier onto the
			part and nothing has ever read them -- the client has no ore
			awareness at all. So 121 ores share one palette and, in the wall,
			a Cobalt vein and a Niobium one are the same blue cube. Colour
			cannot carry identity at this roster size; the name has to.

			MaxDistance keeps it on the block you are standing at instead of
			papering the whole shaft with floating text, and the tier line is
			tinted the ore's own colour so the two read as one object.
		]==]
		local tag = Instance.new("BillboardGui")
		tag.Name = "OreTag"
		tag.Size = UDim2.fromOffset(150, 34)
		tag.StudsOffsetWorldSpace = Vector3.new(0, size * 0.75, 0)
		tag.MaxDistance = 42
		tag.Parent = part
		local nameLbl = Instance.new("TextLabel")
		nameLbl.BackgroundTransparency = 1
		nameLbl.Size = UDim2.new(1, 0, 0, 20)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 15
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.TextStrokeTransparency = 0.35
		nameLbl.Text = tostring(oreDef.name)
		nameLbl.Parent = tag
		local tierLbl = Instance.new("TextLabel")
		tierLbl.BackgroundTransparency = 1
		tierLbl.Position = UDim2.fromOffset(0, 19)
		tierLbl.Size = UDim2.new(1, 0, 0, 14)
		tierLbl.Font = Enum.Font.Gotham
		tierLbl.TextSize = 11
		tierLbl.TextColor3 = oreDef.color
		tierLbl.TextStrokeTransparency = 0.5
		tierLbl.Text = "tier " .. tostring(oreDef.tier)
		tierLbl.Parent = tag`));

// 3 + 4. client: ore on the block card, tier on pack rows
edit(MC, s => {
  // block card: ore must be checked BEFORE the section branch
  s = one(s,
`		if section and target:GetAttribute("Kind") ~= "chest" and target:GetAttribute("Kind") ~= "fossil" then`,
`		--[[
			An ore block carries a SectionName like every other block, so it used to
			fall into the section branch below and the card read "Clayfall | L312" --
			the one thing it could not tell you was which of the 121 ores you were
			standing in front of. Ore is checked FIRST for that reason; the section
			is still on screen in the depth HUD, the ore's identity was nowhere.
		]]
		local oreName = target:GetAttribute("OreName")
		if kind == "ore" and oreName then
			local oreTier = tonumber(target:GetAttribute("OreTier"))
			hoverName.Text = oreTier
				and string.format("%s  |  tier %d", tostring(oreName), oreTier)
				or tostring(oreName)
		elseif section and target:GetAttribute("Kind") ~= "chest" and target:GetAttribute("Kind") ~= "fossil" then`);

  // pack scrap tile: tier in the subtitle
  s = one(s,
`		local PacksMod = require(shared:WaitForChild("MinePackConfig"))`,
`		local PacksMod = require(shared:WaitForChild("MinePackConfig"))
		--[==[
			Ore packs carry their ore's tier, and at 121 ores the name alone
			does not place one: "Magnetite Ore Pack" says nothing about whether
			that is an early find or a deep one. The tier does, so it rides on
			the subtitle where the generic "Unopened pack" used to sit.
		]==]
		local ZonePacks
		pcall(function()
			ZonePacks = require(shared:WaitForChild("MineZonePacks"))
		end)
		local function packSub(pk)
			local def = ZonePacks and ZonePacks.get and ZonePacks.get(pk.packId)
			if def and def.kind == "ore" and def.tier then
				return "Ore pack  |  tier " .. tostring(def.tier)
			end
			return "Unopened pack"
		end`);
  s = one(s, `					name = pk.packName or pk.packId or pk.setId or ("Pack " .. idx),`,
              `					name = pk.packName or pk.packId or pk.setId or ("Pack " .. idx),\n					sub = packSub(pk),`);
  s = one(s, `			tile(i, tostring(row.name), "Unopened pack",`,
              `			tile(i, tostring(row.name), tostring(row.sub or "Unopened pack"),`);

  // dust shop row: tier alongside the name
  s = one(s, `			local name = (def and def.name) or tostring(offer.id)`,
`			local name = (def and def.name) or tostring(offer.id)
			-- 121 ores on the roster: the tier is what places a pack.
			local tierBit = (def and def.kind == "ore" and def.tier)
				and ("  |  tier " .. tostring(def.tier)) or ""`);
  s = one(s, `				Text = string.format("%s    %s dust", name, tostring(offer.price or "?")),`,
              `				Text = string.format("%s%s    %s dust", name, tierBit, tostring(offer.price or "?")),`);
  return s;
});
console.log("all four Studio edits ported");
