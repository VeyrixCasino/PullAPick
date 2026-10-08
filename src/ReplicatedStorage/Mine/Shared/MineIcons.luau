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


-- ------------------------------------------------ forged tool skins --
--[[
	ONE SKIN PER ORE TIER, FOR ALL THREE FORGED FAMILIES.

	Owner, 2026-10-05: "apply the skins to each tool", and on the sheets:
	"1st is wooden, then its in order, last one is admin drill, hand gernade
	and pickaxe".

	Every forged tool used to draw ONE picture per family, so a Stone Pickaxe
	and an Oganesson Pickaxe were the same icon and the whole ladder looked
	identical in the bar, the Forge and the inventory.

	THE ORDER IS THE OWNER'S, NOT A GUESS. An earlier pass matched an older
	sheet to ores by measuring each icon's colour and solving an assignment
	problem against MineConfig.ORES. That was replaced wholesale the moment the
	owner stated the sheets are in roster order -- the art is a designed ladder
	and does not track the ore palette (measured mean colour distance 1.1,
	where a real colour match scores 0.25), so matching on colour would have
	been confidently wrong. Position is authoritative; colour was a proxy.

	Picks carry a wooden starter at index 1 and then the 82 ores; drills and
	bombs start at the first ore. The last icon of each sheet is the admin tool.
	The spare cells between the last ore and the admin icon are the artist
	filling out the grid and are left unused in build/.

	tools/icons/ holds the extractor and the manifest, so if a sheet is redrawn
	this table is regenerated rather than hand-edited.
]]
MineIcons.ORE_PICK_STARTER = "rbxassetid://108275179429292"
MineIcons.ADMIN_PICK = "rbxassetid://75053884636170"
MineIcons.ADMIN_DRILL = "rbxassetid://122925603465750"
MineIcons.ADMIN_BOMB = "rbxassetid://86189079658223"

MineIcons.ORE_PICK = {
	[1] = "rbxassetid://111856077539108", -- Stone
	[2] = "rbxassetid://81138165754921", -- Clay
	[3] = "rbxassetid://133592053579018", -- Limestone
	[4] = "rbxassetid://116586330516743", -- Pumice
	[5] = "rbxassetid://75227545832532", -- Halite
	[6] = "rbxassetid://129141946824513", -- Coal
	[7] = "rbxassetid://104754326792249", -- Flint
	[8] = "rbxassetid://123037947146628", -- Basalt
	[9] = "rbxassetid://110165926910937", -- Slate
	[10] = "rbxassetid://82280156345124", -- Bone
	[11] = "rbxassetid://134098332796521", -- Granite
	[12] = "rbxassetid://98804694624996", -- Copper
	[13] = "rbxassetid://117815058234129", -- Tin
	[14] = "rbxassetid://83858594832277", -- Ember
	[15] = "rbxassetid://79695351326457", -- Sulfur
	[16] = "rbxassetid://102128441036647", -- Lead
	[17] = "rbxassetid://79932961484671", -- Zinc
	[18] = "rbxassetid://139098777024428", -- Aluminum
	[19] = "rbxassetid://92335497767300", -- Iron
	[20] = "rbxassetid://137465929370392", -- Graphite
	[21] = "rbxassetid://93581788871268", -- Pyrite
	[22] = "rbxassetid://96935838229858", -- Marble
	[23] = "rbxassetid://116446761796598", -- Pearl
	[24] = "rbxassetid://87410864583497", -- Rime
	[25] = "rbxassetid://136966013409128", -- Quartz
	[26] = "rbxassetid://97842372386527", -- Amber
	[27] = "rbxassetid://130057184254350", -- Petrifact
	[28] = "rbxassetid://83227984769411", -- Nickel
	[29] = "rbxassetid://118119406393783", -- Onyx
	[30] = "rbxassetid://136131762481975", -- Bloodstone
	[31] = "rbxassetid://80603147922145", -- Garnet
	[32] = "rbxassetid://122354321894513", -- Citrine
	[33] = "rbxassetid://107573152620267", -- Chromium
	[34] = "rbxassetid://120766465367813", -- Turquoise
	[35] = "rbxassetid://108663013576497", -- Bismuth
	[36] = "rbxassetid://124190374678282", -- Silver
	[37] = "rbxassetid://128115369925654", -- Amethyst
	[38] = "rbxassetid://131924421437747", -- Tigereye
	[39] = "rbxassetid://124802642563975", -- Lapis
	[40] = "rbxassetid://76206751355912", -- Geode
	[41] = "rbxassetid://74190230564504", -- Topaz
	[42] = "rbxassetid://71881894350188", -- Phosphorus
	[43] = "rbxassetid://76480972009534", -- Peridot
	[44] = "rbxassetid://92048117238269", -- Jade
	[45] = "rbxassetid://73499649172334", -- Emberglass
	[46] = "rbxassetid://124233114922846", -- Tungsten
	[47] = "rbxassetid://86219699164531", -- Lithium
	[48] = "rbxassetid://106724987458494", -- Titanium
	[49] = "rbxassetid://91284677462521", -- Obsidian
	[50] = "rbxassetid://139350063238442", -- Cobalt
	[51] = "rbxassetid://110016498389900", -- Gold
	[52] = "rbxassetid://70428464393450", -- Regolith
	[53] = "rbxassetid://100510816599135", -- Sunstone
	[54] = "rbxassetid://114474644317785", -- Emerald
	[55] = "rbxassetid://91100900503924", -- Moonstone
	[56] = "rbxassetid://96250557654076", -- Sapphire
	[57] = "rbxassetid://98255153754499", -- Ruby
	[58] = "rbxassetid://101848740374076", -- Palladium
	[59] = "rbxassetid://91981574314270", -- Aquamarine
	[60] = "rbxassetid://111012715777725", -- Opal
	[61] = "rbxassetid://99192191465864", -- Platinum
	[62] = "rbxassetid://72080686176802", -- Stormstone
	[63] = "rbxassetid://137760012605926", -- Diamond
	[64] = "rbxassetid://94103143257239", -- Starmetal
	[65] = "rbxassetid://104383707172031", -- Aetherite
	[66] = "rbxassetid://111642325921022", -- Meteorite
	[67] = "rbxassetid://92808632514130", -- Soulstone
	[68] = "rbxassetid://82068255980074", -- Galaxite
	[69] = "rbxassetid://82869623933221", -- Frostfire
	[70] = "rbxassetid://77175763343125", -- Umbrite
	[71] = "rbxassetid://127111652569742", -- Celestine
	[72] = "rbxassetid://107075360353039", -- Orichalcum
	[73] = "rbxassetid://109991791098924", -- Spectrite
	[74] = "rbxassetid://88075969600855", -- Mythril
	[75] = "rbxassetid://81469067385923", -- Dragonstone
	[76] = "rbxassetid://96052661911414", -- Adamantite
	[77] = "rbxassetid://126949456240985", -- Thorium
	[78] = "rbxassetid://121793583592181", -- Uranium
	[79] = "rbxassetid://127734156675516", -- Plutonium
	[80] = "rbxassetid://111628531557256", -- Fermium
	[81] = "rbxassetid://138162712801362", -- Lawrencium
	[82] = "rbxassetid://132108642211634", -- Oganesson
}

MineIcons.ORE_DRILL = {
	[1] = "rbxassetid://99123341100679", -- Stone
	[2] = "rbxassetid://110386850824682", -- Clay
	[3] = "rbxassetid://131682472981930", -- Limestone
	[4] = "rbxassetid://77342420285535", -- Pumice
	[5] = "rbxassetid://100713943858287", -- Halite
	[6] = "rbxassetid://114098726769833", -- Coal
	[7] = "rbxassetid://102666557174202", -- Flint
	[8] = "rbxassetid://76239359560248", -- Basalt
	[9] = "rbxassetid://132144493288229", -- Slate
	[10] = "rbxassetid://100356539936241", -- Bone
	[11] = "rbxassetid://109854185103627", -- Granite
	[12] = "rbxassetid://93321856016506", -- Copper
	[13] = "rbxassetid://139609447523332", -- Tin
	[14] = "rbxassetid://79272952586116", -- Ember
	[15] = "rbxassetid://116111610571663", -- Sulfur
	[16] = "rbxassetid://101400015689578", -- Lead
	[17] = "rbxassetid://125686067229786", -- Zinc
	[18] = "rbxassetid://137447160517321", -- Aluminum
	[19] = "rbxassetid://85651963260047", -- Iron
	[20] = "rbxassetid://122796922729123", -- Graphite
	[21] = "rbxassetid://125201166750994", -- Pyrite
	[22] = "rbxassetid://135691398512155", -- Marble
	[23] = "rbxassetid://130968695622494", -- Pearl
	[24] = "rbxassetid://110535561190033", -- Rime
	[25] = "rbxassetid://104838959164308", -- Quartz
	[26] = "rbxassetid://121488344749952", -- Amber
	[27] = "rbxassetid://72747121560691", -- Petrifact
	[28] = "rbxassetid://93128312299419", -- Nickel
	[29] = "rbxassetid://88590076514288", -- Onyx
	[30] = "rbxassetid://136177670817090", -- Bloodstone
	[31] = "rbxassetid://124434077535738", -- Garnet
	[32] = "rbxassetid://71165946404276", -- Citrine
	[33] = "rbxassetid://122981010369519", -- Chromium
	[34] = "rbxassetid://74285218988334", -- Turquoise
	[35] = "rbxassetid://95307374776151", -- Bismuth
	[36] = "rbxassetid://96047517197782", -- Silver
	[37] = "rbxassetid://79448355862604", -- Amethyst
	[38] = "rbxassetid://72681742334592", -- Tigereye
	[39] = "rbxassetid://101952630897706", -- Lapis
	[40] = "rbxassetid://79762553812941", -- Geode
	[41] = "rbxassetid://108888315192784", -- Topaz
	[42] = "rbxassetid://135740381144185", -- Phosphorus
	[43] = "rbxassetid://128170167456749", -- Peridot
	[44] = "rbxassetid://133025169765221", -- Jade
	[45] = "rbxassetid://121310780269581", -- Emberglass
	[46] = "rbxassetid://76784417084242", -- Tungsten
	[47] = "rbxassetid://87099590540987", -- Lithium
	[48] = "rbxassetid://90087504193698", -- Titanium
	[49] = "rbxassetid://108002807235210", -- Obsidian
	[50] = "rbxassetid://109760215646091", -- Cobalt
	[51] = "rbxassetid://91899813687857", -- Gold
	[52] = "rbxassetid://123840393537118", -- Regolith
	[53] = "rbxassetid://94847115962511", -- Sunstone
	[54] = "rbxassetid://135232429637373", -- Emerald
	[55] = "rbxassetid://83141923586197", -- Moonstone
	[56] = "rbxassetid://92372873650320", -- Sapphire
	[57] = "rbxassetid://119887313393134", -- Ruby
	[58] = "rbxassetid://125091601709699", -- Palladium
	[59] = "rbxassetid://109104655629789", -- Aquamarine
	[60] = "rbxassetid://111329599619538", -- Opal
	[61] = "rbxassetid://95082741033359", -- Platinum
	[62] = "rbxassetid://79764044710955", -- Stormstone
	[63] = "rbxassetid://93881274000381", -- Diamond
	[64] = "rbxassetid://103298780812385", -- Starmetal
	[65] = "rbxassetid://117416855204382", -- Aetherite
	[66] = "rbxassetid://133385183176173", -- Meteorite
	[67] = "rbxassetid://72754040614556", -- Soulstone
	[68] = "rbxassetid://79028654999422", -- Galaxite
	[69] = "rbxassetid://125397905634787", -- Frostfire
	[70] = "rbxassetid://76494866446072", -- Umbrite
	[71] = "rbxassetid://111889889885732", -- Celestine
	[72] = "rbxassetid://99112838234015", -- Orichalcum
	[73] = "rbxassetid://108332928509108", -- Spectrite
	[74] = "rbxassetid://139902285204896", -- Mythril
	[75] = "rbxassetid://94422949862368", -- Dragonstone
	[76] = "rbxassetid://139554646072737", -- Adamantite
	[77] = "rbxassetid://137121253747418", -- Thorium
	[78] = "rbxassetid://75338986817454", -- Uranium
	[79] = "rbxassetid://129317333190011", -- Plutonium
	[80] = "rbxassetid://75811284621162", -- Fermium
	[81] = "rbxassetid://124064660508744", -- Lawrencium
	[82] = "rbxassetid://121681258484716", -- Oganesson
}

MineIcons.ORE_BOMB = {
	[1] = "rbxassetid://94734785294833", -- Stone
	[2] = "rbxassetid://129852641720865", -- Clay
	[3] = "rbxassetid://102803794260587", -- Limestone
	[4] = "rbxassetid://112066486700628", -- Pumice
	[5] = "rbxassetid://109820096565694", -- Halite
	[6] = "rbxassetid://105989361549929", -- Coal
	[7] = "rbxassetid://107517358083213", -- Flint
	[8] = "rbxassetid://78953366755016", -- Basalt
	[9] = "rbxassetid://75819138809860", -- Slate
	[10] = "rbxassetid://92684847732190", -- Bone
	[11] = "rbxassetid://126499126177735", -- Granite
	[12] = "rbxassetid://135706151709272", -- Copper
	[13] = "rbxassetid://126151990296602", -- Tin
	[14] = "rbxassetid://140412957279836", -- Ember
	[15] = "rbxassetid://110297691956803", -- Sulfur
	[16] = "rbxassetid://81594479047775", -- Lead
	[17] = "rbxassetid://123904939783585", -- Zinc
	[18] = "rbxassetid://92591026095511", -- Aluminum
	[19] = "rbxassetid://127760328054977", -- Iron
	[20] = "rbxassetid://126630496307327", -- Graphite
	[21] = "rbxassetid://134820138072861", -- Pyrite
	[22] = "rbxassetid://111054542796061", -- Marble
	[23] = "rbxassetid://72231098125683", -- Pearl
	[24] = "rbxassetid://124330155882502", -- Rime
	[25] = "rbxassetid://138129262373998", -- Quartz
	[26] = "rbxassetid://82689852730402", -- Amber
	[27] = "rbxassetid://132775352446011", -- Petrifact
	[28] = "rbxassetid://76742968881156", -- Nickel
	[29] = "rbxassetid://109457900578940", -- Onyx
	[30] = "rbxassetid://104649293061911", -- Bloodstone
	[31] = "rbxassetid://87074289776162", -- Garnet
	[32] = "rbxassetid://112974606262889", -- Citrine
	[33] = "rbxassetid://99919962564528", -- Chromium
	[34] = "rbxassetid://124654966108070", -- Turquoise
	[35] = "rbxassetid://101079519839960", -- Bismuth
	[36] = "rbxassetid://117435388548861", -- Silver
	[37] = "rbxassetid://140151317255976", -- Amethyst
	[38] = "rbxassetid://130275706593522", -- Tigereye
	[39] = "rbxassetid://72139380205184", -- Lapis
	[40] = "rbxassetid://100394580236879", -- Geode
	[41] = "rbxassetid://84008255410839", -- Topaz
	[42] = "rbxassetid://76759650641229", -- Phosphorus
	[43] = "rbxassetid://128953640908652", -- Peridot
	[44] = "rbxassetid://120463018879664", -- Jade
	[45] = "rbxassetid://135203134942173", -- Emberglass
	[46] = "rbxassetid://92277863465597", -- Tungsten
	[47] = "rbxassetid://116377668720173", -- Lithium
	[48] = "rbxassetid://127006673182612", -- Titanium
	[49] = "rbxassetid://91534235053340", -- Obsidian
	[50] = "rbxassetid://101612886786994", -- Cobalt
	[51] = "rbxassetid://103521138126383", -- Gold
	[52] = "rbxassetid://127692130549704", -- Regolith
	[53] = "rbxassetid://136037677234272", -- Sunstone
	[54] = "rbxassetid://122507058260712", -- Emerald
	[55] = "rbxassetid://84982402478557", -- Moonstone
	[56] = "rbxassetid://119350275212529", -- Sapphire
	[57] = "rbxassetid://104826883166707", -- Ruby
	[58] = "rbxassetid://82092462047664", -- Palladium
	[59] = "rbxassetid://130422151991202", -- Aquamarine
	[60] = "rbxassetid://115803787448829", -- Opal
	[61] = "rbxassetid://75476005352131", -- Platinum
	[62] = "rbxassetid://94666442998186", -- Stormstone
	[63] = "rbxassetid://127329788610387", -- Diamond
	[64] = "rbxassetid://71880524504230", -- Starmetal
	[65] = "rbxassetid://94051645125290", -- Aetherite
	[66] = "rbxassetid://130713434832043", -- Meteorite
	[67] = "rbxassetid://105450986489199", -- Soulstone
	[68] = "rbxassetid://118878323820293", -- Galaxite
	[69] = "rbxassetid://126124499400581", -- Frostfire
	[70] = "rbxassetid://134818732269217", -- Umbrite
	[71] = "rbxassetid://134440953152623", -- Celestine
	[72] = "rbxassetid://86902936660656", -- Orichalcum
	[73] = "rbxassetid://132810651380611", -- Spectrite
	[74] = "rbxassetid://127725241464216", -- Mythril
	[75] = "rbxassetid://103344664269992", -- Dragonstone
	[76] = "rbxassetid://129931970820708", -- Adamantite
	[77] = "rbxassetid://122524961162749", -- Thorium
	[78] = "rbxassetid://121848729311454", -- Uranium
	[79] = "rbxassetid://120034637953379", -- Plutonium
	[80] = "rbxassetid://129298424509914", -- Fermium
	[81] = "rbxassetid://138156278119755", -- Lawrencium
	[82] = "rbxassetid://71519154408925", -- Oganesson
}

-- The skin table for a forged family. Nil for a family with no art, which is
-- how forTool knows to fall back rather than draw a pickaxe on a fishing rod.
MineIcons.ORE_SKINS = {
	pickaxe = MineIcons.ORE_PICK,
	drill = MineIcons.ORE_DRILL,
	explosive = MineIcons.ORE_BOMB,
}

--[[
	The icon for a forged tool row.

	One lookup, so the hotbar, the Forge and the inventory cannot disagree about
	what a tool looks like. A family with no skin set falls back to its flat
	family icon rather than borrowing another family's art.
]]
function MineIcons.forTool(tool)
	if type(tool) ~= "table" then
		return MineIcons.IMAGES.pickaxe
	end
	local fam = tostring(tool.familyId or tool.family or "pickaxe")
	local skins = MineIcons.ORE_SKINS[fam]
	if skins then
		local skin = skins[math.floor(tonumber(tool.oreTier or tool.tier) or 0)]
		if skin then
			return skin
		end
	end
	return MineIcons.IMAGES[fam] or MineIcons.IMAGES.pickaxe
end

return MineIcons
