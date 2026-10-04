-- MineIcons: the game's icon set.
--
-- These were hand-drawn out of Frames and UICorners, which is why they read as
-- placeholder art. They are now real 256px PNGs, authored as SVG in
-- scratchpad/icons.html, rendered in a browser and uploaded to Roblox. To change
-- one: edit that file, reload it (it re-saves every PNG), re-upload, and paste
-- the new id here.
--
-- Style rules, so additions match:
--   * one dark outline (#241a33), saturated flat fill, a single top highlight
--   * the SHAPE must be a coloured fill, never the outline -- a dark line on a
--     dark dock is invisible, which is exactly how the first pass lost the
--     branches on `skills` and the arrow on `merge`
--   * readable at 40px on a busy background; that is the only test that matters
local MineIcons = {}

MineIcons.IMAGES = {
	-- experience / loading mark (v4 hype clickbait; v2 still-life kept as logo)
	game = "rbxassetid://88438205722708",
	logo = "rbxassetid://72359399788911",
	thumb = "rbxassetid://138387937080354",
	-- Pack drop-rate inspect (exact circle-i cutout, transparent BG)
	info = "rbxassetid://128921065698210",
	-- Enchanter dock / panel (purple gold-star book cutout)
	enchanter = "rbxassetid://126681136084494",
	-- panels / NPCs (backgroundless re-upload Sep 2026)
	shop = "rbxassetid://91350236877416",
	binder = "rbxassetid://116171966355625",
	dust = "rbxassetid://82545245834050",
	zones = "rbxassetid://125496889420424",
	-- Transparent mine-entrance cutout (chest / pit markers).
	mine = "rbxassetid://100381132251143",
	mine_entrance = "rbxassetid://100381132251143",
	skills = "rbxassetid://77091684955325", -- Jobs dock: job_board_icon.png (transparent re-upload)
	-- Job Board dock (was skills). Same art as MineClient ICONS.skills.
	jobs = "rbxassetid://77091684955325", -- job_board_icon.png
	rebirth = "rbxassetid://120888749281068",
	merge = "rbxassetid://107421662141707",
	-- currencies
	coins = "rbxassetid://102189900236414",
	gems = "rbxassetid://76026876336110",
	-- Transparent cutout (was JPEG with baked checkerboard: 103790757889362).
	tokens = "rbxassetid://75674673384288",
	credits = "rbxassetid://94307232671682",
	credit_handful = "rbxassetid://83194524418120",
	credit_starter = "rbxassetid://111821940203483",
	credit_pocket = "rbxassetid://81945984433737",
	credit_pouch = "rbxassetid://136749825863793",
	credit_sack = "rbxassetid://87948711465516",
	credit_crate = "rbxassetid://118952009409330",
	credit_vault = "rbxassetid://117447901452563",
	credit_treasury = "rbxassetid://94754649897464",
	credit_hoard = "rbxassetid://117447901452563",
	stardust = "rbxassetid://92999366083828",
	-- gear / tools
	backpack = "rbxassetid://122765964538534",
	pickaxe = "rbxassetid://122679222121596",
	drill = "rbxassetid://101772239835917",
	ranged = "rbxassetid://129907983283511",
	explosive = "rbxassetid://110152072065351",
	-- loot
	chest = "rbxassetid://140392421395756",
	pack = "rbxassetid://78776652788430",	-- Battle Pass identities (transparent cutouts, 2026-09-15).
	battlepass = "rbxassetid://138154627806679",
	lunar_pick = "rbxassetid://102279387247666",
	bp_eclipse = "rbxassetid://127967739699405",
	lunar_eclipse = "rbxassetid://129660435431703",
	lucky_block = "rbxassetid://86826521518359",
	super_lucky_block = "rbxassetid://130589291505484",
	godly_lucky_block = "rbxassetid://75196830544563",
	white = "rbxassetid://106962099946649",
	black = "rbxassetid://81436312874901",
	omni = "rbxassetid://127673343142946",

	-- Mine For Cards zone chests (transparent cutouts, 2026-09-14).
	meadow_topsoil = "rbxassetid://75273725928911",
	meadow_rootbox = "rbxassetid://87449388931630",
	meadow_loam_vault = "rbxassetid://89886894814983",
	meadow_sunrise = "rbxassetid://111899177086662",
	meadow_sod_crate = "rbxassetid://103058341008938",
	meadow_briar = "rbxassetid://102968037282774",
	meadow_hillock = "rbxassetid://99194769014131",
	meadow_age_s1 = "rbxassetid://77699128179465",
	meadow_age_s2 = "rbxassetid://70573648623917",
	greyvein_flagstone = "rbxassetid://78250356535007",
	greyvein_shale = "rbxassetid://71386600786442",
	greyvein_granite = "rbxassetid://83461121153486",
	greyvein_quarry = "rbxassetid://115082819888558",
	greyvein_chisel = "rbxassetid://116281641418487",
	greyvein_bedrock = "rbxassetid://95372704370182",
	greyvein_age_s1 = "rbxassetid://87424065759769",
	greyvein_age_s2 = "rbxassetid://70596003873414",
	seam_cobble = "rbxassetid://71361320198701",
	seam_slate = "rbxassetid://99428451618526",
	seam_mist = "rbxassetid://100194898710319",
	seam_spark = "rbxassetid://110589305435085",
	seam_crimson = "rbxassetid://121783335262996",
	seam_shadow = "rbxassetid://102790204996835",
	seam_rift = "rbxassetid://86051085829420",
	seam_star = "rbxassetid://99179545453017",
	seam_myth = "rbxassetid://136976859620497",
	seam_prime = "rbxassetid://91494280453752",
	mist_tide = "rbxassetid://114785711804954",
	mist_kelp = "rbxassetid://115819177294777",
	mist_reef = "rbxassetid://113108004375395",
	mist_brine = "rbxassetid://122095091669664",
	mist_coral = "rbxassetid://135263777379598",
	mist_age_s1 = "rbxassetid://125817681039849",
	mist_age_s2 = "rbxassetid://111594426483395",
	arc_coil = "rbxassetid://109775321470611",
	arc_spark = "rbxassetid://74500039179564",
	arc_core = "rbxassetid://106109208773995",
	arc_wire = "rbxassetid://74765664582160",
	arc_flux = "rbxassetid://120572119705391",
	arc_age_s1 = "rbxassetid://129913052364478",
	arc_age_s2 = "rbxassetid://92627805053555",
	blood_ember = "rbxassetid://95865055855295",
	blood_fang = "rbxassetid://135127600322685",
	blood_lunar = "rbxassetid://85500657030939",
	blood_ash = "rbxassetid://84592725218489",
	blood_veil = "rbxassetid://101808580454102",
	blood_age_s1 = "rbxassetid://138435560890345",
	blood_age_s2 = "rbxassetid://117303520365148",
	ecl_umbral = "rbxassetid://130391206793603",
	ecl_void = "rbxassetid://138924067230770",
	ecl_nocturne = "rbxassetid://124888611238540",
	ecl_shade = "rbxassetid://139569343103752",
	ecl_penumbra = "rbxassetid://120459870014097",
	ecl_age_s1 = "rbxassetid://127183360954547",
	ecl_age_s2 = "rbxassetid://70397396002182",
	rift_tear = "rbxassetid://104818275288640",
	rift_scar = "rbxassetid://139912923607562",
	rift_gate = "rbxassetid://74037324535139",
	rift_fracture = "rbxassetid://92751528090885",
	rift_warp = "rbxassetid://83241052765534",
	rift_age_s1 = "rbxassetid://130688813745687",
	rift_age_s2 = "rbxassetid://117858512642722",
	star_dust = "rbxassetid://73248960067944",
	star_comet = "rbxassetid://102751348005380",
	star_nova = "rbxassetid://112218938721826",
	star_orbit = "rbxassetid://93050153606838",
	star_meteor = "rbxassetid://75278314398134",
	star_age_s1 = "rbxassetid://121363783369949",
	star_age_s2 = "rbxassetid://120447517390790",
	myth_shard = "rbxassetid://83787228582255",
	myth_lattice = "rbxassetid://117088655444966",
	myth_prism = "rbxassetid://77384096463490",
	myth_gleam = "rbxassetid://70558272692676",
	myth_aether = "rbxassetid://103399703521987",
	myth_age_s1 = "rbxassetid://110147771223292",
	myth_age_s2 = "rbxassetid://94226007723514",
	prime_seed = "rbxassetid://135998587126986",
	prime_bone = "rbxassetid://97391730496966",
	prime_ash = "rbxassetid://122832173007459",
	prime_ember = "rbxassetid://115222015562038",
	prime_heart = "rbxassetid://117570504990156",
	prime_age_s1 = "rbxassetid://116770359088194",
	prime_age_s2 = "rbxassetid://104974289250633",
	hz_event = "rbxassetid://129321456287153",
	hz_singularity = "rbxassetid://108332081322943",
	hz_horizon = "rbxassetid://78687757910741",
	hz_pulse = "rbxassetid://135032299420477",
	hz_collapse = "rbxassetid://107401304269161",
}

-- Old names kept working so nothing has to be renamed at every call site.
MineIcons.ALIAS = {

	--[[
		STAND-INS, until their own art lands.

		A summon row with no picture reads as a broken row, so each of these
		points at the closest thing the game already owns. Replace the entry in
		IMAGES with a real upload and the alias stops mattering:
		  rune    a rune summon
		  temper  the Temperament Case  (`case` is the same picture)
		Hats and faces need nothing: they are real catalog items and show their
		own thumbnail (MineHats.thumb).
	]]
	rune = "skills",
	temper = "credit_crate",
	case = "credit_crate",
	hat = "pack",
	face = "pack",	cart = "shop",
	card = "binder",
	coin = "coins",
	gem = "gems",
	token = "tokens",
	temperTokens = "tokens",
	temper_token = "tokens",
	stardust = "dust",
	zone = "zones",
	prestige = "rebirth",
	tool = "pickaxe",
	crate = "chest",
	scroll = "white",

	-- merge has its own art now (still falls back to binder if missing)

	-- Stat glyphs. Approximate on purpose: stats get proper treatment with the
	-- pet card work, and a close icon beats a grey dot in the meantime.
	mineSpeed = "pickaxe",
	swingSec = "pickaxe",
	swingRate = "pickaxe",
	dirtBreak = "drill",
	blastRadius = "explosive",
	blastChance = "chest",
	rareOre = "gems",
	gemFind = "gems",
	coinBonus = "coins",
	luck = "credits",
	chestLuck = "chest",
	walkSpeed = "ranged",
	echo = "skills",
	zap = "skills",
	autoMine = "skills",
	backpackStat = "backpack",
}

function MineIcons.resolve(id)
	id = tostring(id or "")
	if id == "" then
		return nil
	end
	if MineIcons.IMAGES[id] then
		return id
	end
	local aliased = MineIcons.ALIAS[id]
	if aliased and MineIcons.IMAGES[aliased] then
		return aliased
	end
	-- Every tool id maps to a family glyph so shop / bag / dex never show a blank.
	local lower = string.lower(id)
	if lower:find("drill", 1, true) or lower:find("bore", 1, true) or lower:find("auger", 1, true) then
		return MineIcons.IMAGES.drill and "drill" or nil
	end
	if lower:find("bomb", 1, true) or lower:find("explosive", 1, true) or lower:find("charge", 1, true)
		or lower:find("blast", 1, true) or lower:find("nuke", 1, true) or lower:find("singularity", 1, true) then
		return MineIcons.IMAGES.explosive and "explosive" or nil
	end
	if lower:find("pick", 1, true) or lower:find("axe", 1, true) or lower:find("haft", 1, true)
		or lower:find("edge", 1, true) or lower:find("spear", 1, true) or lower:find("lunar", 1, true) then
		return MineIcons.IMAGES.pickaxe and "pickaxe" or nil
	end
	if lower:find("bag", 1, true) or lower:find("pack", 1, true) or lower:find("rig", 1, true) then
		return MineIcons.IMAGES.backpack and "backpack" or nil
	end
	return nil
end

function MineIcons.image(id)
	local key = MineIcons.resolve(id)
	if not key then
		return nil
	end
	local url = MineIcons.IMAGES[key]
	if type(url) ~= "string" or url == "" then
		return nil
	end
	return url
end

--[[
	Fills `parent` with an icon, centred. Same signature and return as the old
	vector version, so every existing call site keeps working.
]]
function MineIcons.draw(parent, id, scale)
	local holder = Instance.new("ImageLabel")
	holder.Name = "Icon_" .. tostring(id)
	holder.BackgroundTransparency = 1
	holder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	holder.BorderSizePixel = 0
	holder.Size = UDim2.fromScale(scale or 1, scale or 1)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.ScaleType = Enum.ScaleType.Fit
	holder.ZIndex = (parent :: any).ZIndex or 1
	holder.Active = false
	holder.Selectable = false

	local img = MineIcons.image(id)
	if img then
		holder.Image = img
	else
		-- Loud on purpose. A missing icon should be obvious in testing rather
		-- than quietly shipping as a grey smudge.
		holder.Image = ""
		holder.BackgroundTransparency = 0.25
		holder.BackgroundColor3 = Color3.fromRGB(255, 60, 140)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = holder
		warn("[MineIcons] no image for '" .. tostring(id) .. "'")
	end
	holder.Parent = parent
	return holder
end

-- Absolute placement, for callers that position icons themselves.
function MineIcons.icon(parent, id, size, position, anchor)
	local holder = MineIcons.draw(parent, id, 1)
	holder.Size = size or UDim2.fromOffset(32, 32)
	holder.Position = position or UDim2.fromOffset(0, 0)
	holder.AnchorPoint = anchor or Vector2.new(0, 0)
	return holder
end

--[[
	Icon + amount in a horizontal chip so prices read as "how many of what".
	opts: position, anchor, size, iconSize, gap, textSize, textColor, font, zIndex
]]
function MineIcons.priceChip(parent, currencyId, amountText, opts)
	opts = opts or {}
	local z = opts.zIndex or ((typeof(parent) == "Instance" and parent:IsA("GuiObject") and parent.ZIndex) or 1) + 1
	local iconSize = opts.iconSize or 18
	local row = Instance.new("Frame")
	row.Name = "PriceChip"
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = opts.size or UDim2.fromOffset(0, iconSize)
	row.Position = opts.position or UDim2.fromOffset(0, 0)
	row.AnchorPoint = opts.anchor or Vector2.new(0, 0)
	row.ZIndex = z
	row.Parent = parent

	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.VerticalAlignment = Enum.VerticalAlignment.Center
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, opts.gap or 4)
	lay.Parent = row

	local iconHost = Instance.new("Frame")
	iconHost.Name = "IconHost"
	iconHost.BackgroundTransparency = 1
	iconHost.BorderSizePixel = 0
	iconHost.Size = UDim2.fromOffset(iconSize, iconSize)
	iconHost.LayoutOrder = 1
	iconHost.ZIndex = z
	iconHost.Parent = row
	MineIcons.draw(iconHost, currencyId, 1)

	local lab = Instance.new("TextLabel")
	lab.Name = "Amount"
	lab.BackgroundTransparency = 1
	lab.BorderSizePixel = 0
	lab.Font = opts.font or Enum.Font.GothamMedium
	lab.TextSize = opts.textSize or 14
	lab.TextColor3 = opts.textColor or Color3.fromRGB(255, 255, 255)
	lab.TextXAlignment = Enum.TextXAlignment.Left
	lab.TextYAlignment = Enum.TextYAlignment.Center
	lab.Text = tostring(amountText)
	lab.AutomaticSize = Enum.AutomaticSize.X
	lab.Size = UDim2.fromOffset(0, iconSize)
	lab.LayoutOrder = 2
	lab.ZIndex = z
	lab.Parent = row
	return row, lab
end

function MineIcons.list()
	local out = {}
	for name in pairs(MineIcons.IMAGES) do
		table.insert(out, name)
	end
	table.sort(out)
	return out
end

return MineIcons
