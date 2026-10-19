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
	-- enchant books (pass tiles, bundles): the Enchanter's book art
	books = "enchanter",
	book = "enchanter",
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

--[[
	HAMMER AND JACKHAMMER ICONS, one per ore (owner, 2026-10-11: "i need the
	hammers and jackhammers fully built in"; icons made in Canva to match the
	pick, drill and grenade sheets -- build/hammer-icons/, art/tool-icons/).
	Jackhammers 75-82 are still to come: Canva's AI allowance ran out mid-run,
	and a missing tier falls back to the flat family icon (forTool).

	They join ORE_SKINS only once NEW_TOOL_ICONS_SHARED is true. An uploaded image
	draws nothing in the game until the owner shares it with the experience in
	the Creator Hub (as with the case art), and a blank hotbar is worse than
	the flat icon.
]]
MineIcons.NEW_TOOL_ICONS_SHARED = false

MineIcons.ORE_HAMMER = {
	[1] = "rbxassetid://134468774478371", -- Stone
	[2] = "rbxassetid://129598472060743", -- Clay
	[3] = "rbxassetid://86787995602389", -- Limestone
	[4] = "rbxassetid://114544018521414", -- Pumice
	[5] = "rbxassetid://110390151520655", -- Halite
	[6] = "rbxassetid://104790661521973", -- Coal
	[7] = "rbxassetid://102929466476481", -- Flint
	[8] = "rbxassetid://90178811793577", -- Basalt
	[9] = "rbxassetid://118885720151712", -- Slate
	[10] = "rbxassetid://119125584960961", -- Bone
	[11] = "rbxassetid://107690855395598", -- Granite
	[12] = "rbxassetid://116815477036662", -- Copper
	[13] = "rbxassetid://109416847828746", -- Tin
	[14] = "rbxassetid://135464460169534", -- Ember
	[15] = "rbxassetid://106878478579511", -- Sulfur
	[16] = "rbxassetid://129290167811791", -- Lead
	[17] = "rbxassetid://81801838947519", -- Zinc
	[18] = "rbxassetid://92050008174776", -- Aluminum
	[19] = "rbxassetid://86469287149822", -- Iron
	[20] = "rbxassetid://92685330446090", -- Graphite
	[21] = "rbxassetid://84393904909522", -- Pyrite
	[22] = "rbxassetid://70553609444013", -- Marble
	[23] = "rbxassetid://122094750740344", -- Pearl
	[24] = "rbxassetid://127428948435568", -- Rime
	[25] = "rbxassetid://124515272205039", -- Quartz
	[26] = "rbxassetid://139629682295736", -- Amber
	[27] = "rbxassetid://70530840357777", -- Petrifact
	[28] = "rbxassetid://87945503187545", -- Nickel
	[29] = "rbxassetid://92335874308238", -- Onyx
	[30] = "rbxassetid://89517533986487", -- Bloodstone
	[31] = "rbxassetid://88213250977372", -- Garnet
	[32] = "rbxassetid://93905037592057", -- Citrine
	[33] = "rbxassetid://79171651946229", -- Chromium
	[34] = "rbxassetid://70401186186272", -- Turquoise
	[35] = "rbxassetid://95935299133389", -- Bismuth
	[36] = "rbxassetid://127193318250378", -- Silver
	[37] = "rbxassetid://118152560656284", -- Amethyst
	[38] = "rbxassetid://114900339250632", -- Tigereye
	[39] = "rbxassetid://76328848950743", -- Lapis
	[40] = "rbxassetid://136464488004336", -- Geode
	[41] = "rbxassetid://75381384028335", -- Topaz
	[42] = "rbxassetid://78897383702527", -- Phosphorus
	[43] = "rbxassetid://74887250577965", -- Peridot
	[44] = "rbxassetid://104222982631729", -- Jade
	[45] = "rbxassetid://104257767096549", -- Emberglass
	[46] = "rbxassetid://109718691941354", -- Tungsten
	[47] = "rbxassetid://133972852462462", -- Lithium
	[48] = "rbxassetid://139733776889332", -- Titanium
	[49] = "rbxassetid://133445568663013", -- Obsidian
	[50] = "rbxassetid://78751221519142", -- Cobalt
	[51] = "rbxassetid://80109623669818", -- Gold
	[52] = "rbxassetid://113528914503046", -- Regolith
	[53] = "rbxassetid://70506430406462", -- Sunstone
	[54] = "rbxassetid://135175060530103", -- Emerald
	[55] = "rbxassetid://86403013562167", -- Moonstone
	[56] = "rbxassetid://108334967929491", -- Sapphire
	[57] = "rbxassetid://98712420844523", -- Ruby
	[58] = "rbxassetid://94890405161433", -- Palladium
	[59] = "rbxassetid://74572275591231", -- Aquamarine
	[60] = "rbxassetid://116497907979760", -- Opal
	[61] = "rbxassetid://96159847610071", -- Platinum
	[62] = "rbxassetid://82511706535286", -- Stormstone
	[63] = "rbxassetid://71246229886334", -- Diamond
	[64] = "rbxassetid://77188336471913", -- Starmetal
	[65] = "rbxassetid://116538437791264", -- Aetherite
	[66] = "rbxassetid://96047658270252", -- Meteorite
	[67] = "rbxassetid://75511088974553", -- Soulstone
	[68] = "rbxassetid://131276532781571", -- Galaxite
	[69] = "rbxassetid://105294970056517", -- Frostfire
	[70] = "rbxassetid://128548299390409", -- Umbrite
	[71] = "rbxassetid://128192235961108", -- Celestine
	[72] = "rbxassetid://87220428134783", -- Orichalcum
	[73] = "rbxassetid://100950954675845", -- Spectrite
	[74] = "rbxassetid://91464140186703", -- Mythril
	[75] = "rbxassetid://117814919491144", -- Dragonstone
	[76] = "rbxassetid://80921009591041", -- Adamantite
	[77] = "rbxassetid://73510298489929", -- Thorium
	[78] = "rbxassetid://92147702315758", -- Uranium
	[79] = "rbxassetid://74180584098075", -- Plutonium
	[80] = "rbxassetid://122417097618471", -- Fermium
	[81] = "rbxassetid://98732951723982", -- Lawrencium
	[82] = "rbxassetid://123572082654489", -- Oganesson
}

MineIcons.ORE_JACKHAMMER = {
	[1] = "rbxassetid://79939587253007", -- Stone
	[2] = "rbxassetid://105902552941555", -- Clay
	[3] = "rbxassetid://71238482788035", -- Limestone
	[4] = "rbxassetid://83534449584456", -- Pumice
	[5] = "rbxassetid://134181518726665", -- Halite
	[6] = "rbxassetid://91997055611292", -- Coal
	[7] = "rbxassetid://134254706912783", -- Flint
	[8] = "rbxassetid://70434595749195", -- Basalt
	[9] = "rbxassetid://124614359311403", -- Slate
	[10] = "rbxassetid://99870553772160", -- Bone
	[11] = "rbxassetid://88834441126349", -- Granite
	[12] = "rbxassetid://86061441287672", -- Copper
	[13] = "rbxassetid://93122699227543", -- Tin
	[14] = "rbxassetid://81813918035469", -- Ember
	[15] = "rbxassetid://90087129456572", -- Sulfur
	[16] = "rbxassetid://83946052320856", -- Lead
	[17] = "rbxassetid://89806902740851", -- Zinc
	[18] = "rbxassetid://91426891833861", -- Aluminum
	[19] = "rbxassetid://89540296577502", -- Iron
	[20] = "rbxassetid://76857875344576", -- Graphite
	[21] = "rbxassetid://135546372597553", -- Pyrite
	[22] = "rbxassetid://77295803678646", -- Marble
	[23] = "rbxassetid://120179403945821", -- Pearl
	[24] = "rbxassetid://123291693745559", -- Rime
	[25] = "rbxassetid://114756261888974", -- Quartz
	[26] = "rbxassetid://82479305125131", -- Amber
	[27] = "rbxassetid://104000541915197", -- Petrifact
	[28] = "rbxassetid://81936978690121", -- Nickel
	[29] = "rbxassetid://81459641936247", -- Onyx
	[30] = "rbxassetid://116019419713635", -- Bloodstone
	[31] = "rbxassetid://109684757881964", -- Garnet
	[32] = "rbxassetid://73207988524018", -- Citrine
	[33] = "rbxassetid://78720585977052", -- Chromium
	[34] = "rbxassetid://81029758374375", -- Turquoise
	[35] = "rbxassetid://76679641487977", -- Bismuth
	[36] = "rbxassetid://85053825115141", -- Silver
	[37] = "rbxassetid://109368111048957", -- Amethyst
	[38] = "rbxassetid://98774039270838", -- Tigereye
	[39] = "rbxassetid://107283585638898", -- Lapis
	[40] = "rbxassetid://100615908738311", -- Geode
	[41] = "rbxassetid://84296362725821", -- Topaz
	[42] = "rbxassetid://134101541903629", -- Phosphorus
	[43] = "rbxassetid://106146594739664", -- Peridot
	[44] = "rbxassetid://108330284308498", -- Jade
	[45] = "rbxassetid://94885751025255", -- Emberglass
	[46] = "rbxassetid://133309061792098", -- Tungsten
	[47] = "rbxassetid://81863537852779", -- Lithium
	[48] = "rbxassetid://95140310954558", -- Titanium
	[49] = "rbxassetid://120634681226290", -- Obsidian
	[50] = "rbxassetid://131345263843285", -- Cobalt
	[51] = "rbxassetid://133401075708695", -- Gold
	[52] = "rbxassetid://91936534937874", -- Regolith
	[53] = "rbxassetid://110079278918847", -- Sunstone
	[54] = "rbxassetid://122241026114578", -- Emerald
	[55] = "rbxassetid://110504713585270", -- Moonstone
	[56] = "rbxassetid://76129818592277", -- Sapphire
	[57] = "rbxassetid://125810389214275", -- Ruby
	[58] = "rbxassetid://72441753395761", -- Palladium
	[59] = "rbxassetid://116021596397713", -- Aquamarine
	[60] = "rbxassetid://128463678466558", -- Opal
	[61] = "rbxassetid://87172220002298", -- Platinum
	[62] = "rbxassetid://106739961662023", -- Stormstone
	[63] = "rbxassetid://120314856079627", -- Diamond
	[64] = "rbxassetid://122969497760363", -- Starmetal
	[65] = "rbxassetid://111014861663842", -- Aetherite
	[66] = "rbxassetid://126428598338190", -- Meteorite
	[67] = "rbxassetid://111815801195532", -- Soulstone
	[68] = "rbxassetid://132287842203943", -- Galaxite
	[69] = "rbxassetid://135766527003688", -- Frostfire
	[70] = "rbxassetid://99829353411880", -- Umbrite
	[71] = "rbxassetid://76098789924793", -- Celestine
	[72] = "rbxassetid://111076092003197", -- Orichalcum
	[73] = "rbxassetid://120622713997592", -- Spectrite
	[74] = "rbxassetid://107786622215745", -- Mythril
}

--[[
	THE CANVA PICKAXES, tiers 1-81 (owner, 2026-10-11: "i like PICKAXE 82, BUT
	REDO THE RESTs ... make sure the colors make sense"). They replace ORE_PICK's
	entries once NEW_TOOL_ICONS_SHARED is true; tier 82 and the wooden starter
	keep the original art the owner liked. build/tool-icons/, art/tool-icons/.
]]
MineIcons.ORE_PICK_CANVA = {
	[1] = "rbxassetid://104656250958206", -- Stone
	[2] = "rbxassetid://82880795348674", -- Clay
	[3] = "rbxassetid://105604585976249", -- Limestone
	[4] = "rbxassetid://78603390635564", -- Pumice
	[5] = "rbxassetid://90867967727798", -- Halite
	[6] = "rbxassetid://127169666546626", -- Coal
	[7] = "rbxassetid://128754452222890", -- Flint
	[8] = "rbxassetid://116361891550539", -- Basalt
	[9] = "rbxassetid://128906926966676", -- Slate
	[10] = "rbxassetid://125352834103406", -- Bone
	[11] = "rbxassetid://140364783334268", -- Granite
	[12] = "rbxassetid://75735819954316", -- Copper
	[13] = "rbxassetid://72377949994832", -- Tin
	[14] = "rbxassetid://122649830913218", -- Ember
	[15] = "rbxassetid://77973993693965", -- Sulfur
	[16] = "rbxassetid://89156578788333", -- Lead
	[17] = "rbxassetid://93748629235505", -- Zinc
	[18] = "rbxassetid://111398172088771", -- Aluminum
	[19] = "rbxassetid://92879870374844", -- Iron
	[20] = "rbxassetid://101488118294813", -- Graphite
	[21] = "rbxassetid://127232479326208", -- Pyrite
	[22] = "rbxassetid://122993923476117", -- Marble
	[23] = "rbxassetid://97254979326763", -- Pearl
	[24] = "rbxassetid://97927173333251", -- Rime
	[25] = "rbxassetid://132430787763226", -- Quartz
	[26] = "rbxassetid://99681611120686", -- Amber
	[27] = "rbxassetid://105272233645589", -- Petrifact
	[28] = "rbxassetid://109803647524432", -- Nickel
	[29] = "rbxassetid://89913427047823", -- Onyx
	[30] = "rbxassetid://75485794348692", -- Bloodstone
	[31] = "rbxassetid://86206111970385", -- Garnet
	[32] = "rbxassetid://132348355210024", -- Citrine
	[33] = "rbxassetid://74901388817432", -- Chromium
	[34] = "rbxassetid://137978451250024", -- Turquoise
	[35] = "rbxassetid://113845427271399", -- Bismuth
	[36] = "rbxassetid://105051812484209", -- Silver
	[37] = "rbxassetid://127020291209159", -- Amethyst
	[38] = "rbxassetid://133885276024926", -- Tigereye
	[39] = "rbxassetid://133593114256282", -- Lapis
	[40] = "rbxassetid://84796942031066", -- Geode
	[41] = "rbxassetid://117336946362653", -- Topaz
	[42] = "rbxassetid://89664035013106", -- Phosphorus
	[43] = "rbxassetid://102590824868218", -- Peridot
	[44] = "rbxassetid://106949357311937", -- Jade
	[45] = "rbxassetid://132534976438067", -- Emberglass
	[46] = "rbxassetid://132697534836112", -- Tungsten
	[47] = "rbxassetid://103169945851979", -- Lithium
	[48] = "rbxassetid://80923694463978", -- Titanium
	[49] = "rbxassetid://95255403242115", -- Obsidian
	[50] = "rbxassetid://117656794373371", -- Cobalt
	[51] = "rbxassetid://77645555085307", -- Gold
	[52] = "rbxassetid://108288859705413", -- Regolith
	[53] = "rbxassetid://120871846606987", -- Sunstone
	[54] = "rbxassetid://80482331104757", -- Emerald
	[55] = "rbxassetid://120288868707523", -- Moonstone
	[56] = "rbxassetid://120097395949709", -- Sapphire
	[57] = "rbxassetid://109630776935523", -- Ruby
	[58] = "rbxassetid://89380026565673", -- Palladium
	[59] = "rbxassetid://94925626810947", -- Aquamarine
	[60] = "rbxassetid://85820788590824", -- Opal
	[61] = "rbxassetid://127350029282685", -- Platinum
	[62] = "rbxassetid://105230962834160", -- Stormstone
	[63] = "rbxassetid://97580884882555", -- Diamond
	[64] = "rbxassetid://121462348934732", -- Starmetal
	[65] = "rbxassetid://104887851454185", -- Aetherite
	[66] = "rbxassetid://136507268887979", -- Meteorite
	[67] = "rbxassetid://71132141509902", -- Soulstone
	[68] = "rbxassetid://94266404257320", -- Galaxite
	[69] = "rbxassetid://135205626950575", -- Frostfire
	[70] = "rbxassetid://110557581728286", -- Umbrite
	[71] = "rbxassetid://114872516362876", -- Celestine
	[72] = "rbxassetid://97450213081694", -- Orichalcum
	[73] = "rbxassetid://111493784518219", -- Spectrite
	[74] = "rbxassetid://126461794063270", -- Mythril
	[75] = "rbxassetid://108524103799857", -- Dragonstone
	[76] = "rbxassetid://104161802688353", -- Adamantite
	[77] = "rbxassetid://93243982200614", -- Thorium
	[78] = "rbxassetid://71462477783238", -- Uranium
	[79] = "rbxassetid://85723260477758", -- Plutonium
	[80] = "rbxassetid://97767783861408", -- Fermium
	[81] = "rbxassetid://136549260031806", -- Lawrencium
}

--[[
	THE CANVA DRILLS AND EXPLOSIVES, tiers 1-81 (owner, 2026-10-11: "Do drills
	and explosives and pickaxes.. make sure the colors make sense"). Like the
	pickaxes above, they replace ORE_DRILL's and ORE_BOMB's entries once
	NEW_TOOL_ICONS_SHARED is true, and tier 82 keeps its original art.
	Explosives 19, 29, 65, 67, 68, 71 and 77 are being redrawn (the cut-out
	clipped the fuse spark); until they land, those tiers keep the old art.
]]
MineIcons.ORE_DRILL_CANVA = {
	[1] = "rbxassetid://118561017705130", -- Stone
	[2] = "rbxassetid://70814831250313", -- Clay
	[3] = "rbxassetid://87167824756386", -- Limestone
	[4] = "rbxassetid://86456961652327", -- Pumice
	[5] = "rbxassetid://115817381040321", -- Halite
	[6] = "rbxassetid://87254817382833", -- Coal
	[7] = "rbxassetid://90885941825124", -- Flint
	[8] = "rbxassetid://83743826361345", -- Basalt
	[9] = "rbxassetid://79057592357526", -- Slate
	[10] = "rbxassetid://80506573341924", -- Bone
	[11] = "rbxassetid://91705416307624", -- Granite
	[12] = "rbxassetid://107008073474738", -- Copper
	[13] = "rbxassetid://87208169800844", -- Tin
	[14] = "rbxassetid://102050307476304", -- Ember
	[15] = "rbxassetid://96384944017459", -- Sulfur
	[16] = "rbxassetid://74872561023892", -- Lead
	[17] = "rbxassetid://100786056060193", -- Zinc
	[18] = "rbxassetid://97226127407297", -- Aluminum
	[19] = "rbxassetid://121825915912139", -- Iron
	[20] = "rbxassetid://72995590952141", -- Graphite
	[21] = "rbxassetid://98627350996880", -- Pyrite
	[22] = "rbxassetid://122423874006858", -- Marble
	[23] = "rbxassetid://100698840839417", -- Pearl
	[24] = "rbxassetid://96785759372586", -- Rime
	[25] = "rbxassetid://118112301359072", -- Quartz
	[26] = "rbxassetid://116511571370562", -- Amber
	[27] = "rbxassetid://120423781568006", -- Petrifact
	[28] = "rbxassetid://112935401864324", -- Nickel
	[29] = "rbxassetid://136686906599449", -- Onyx
	[30] = "rbxassetid://85606525403363", -- Bloodstone
	[31] = "rbxassetid://107524649128941", -- Garnet
	[32] = "rbxassetid://72565673339359", -- Citrine
	[33] = "rbxassetid://86813614178241", -- Chromium
	[34] = "rbxassetid://70414667270407", -- Turquoise
	[35] = "rbxassetid://138089370750426", -- Bismuth
	[36] = "rbxassetid://99289587571972", -- Silver
	[37] = "rbxassetid://126605276703501", -- Amethyst
	[38] = "rbxassetid://85165407154414", -- Tigereye
	[39] = "rbxassetid://139125938543484", -- Lapis
	[40] = "rbxassetid://110765015674087", -- Geode
	[41] = "rbxassetid://76779674127167", -- Topaz
	[42] = "rbxassetid://105235399900129", -- Phosphorus
	[43] = "rbxassetid://92780292164669", -- Peridot
	[44] = "rbxassetid://131123525282432", -- Jade
	[45] = "rbxassetid://89229611929021", -- Emberglass
	[46] = "rbxassetid://89979222655011", -- Tungsten
	[47] = "rbxassetid://83517146527246", -- Lithium
	[48] = "rbxassetid://87725511313974", -- Titanium
	[49] = "rbxassetid://76722719142674", -- Obsidian
	[50] = "rbxassetid://127242383322245", -- Cobalt
	[51] = "rbxassetid://117719114899752", -- Gold
	[52] = "rbxassetid://136860391857049", -- Regolith
	[53] = "rbxassetid://81035322073980", -- Sunstone
	[54] = "rbxassetid://137413915177755", -- Emerald
	[55] = "rbxassetid://127673856253609", -- Moonstone
	[56] = "rbxassetid://91101358422016", -- Sapphire
	[57] = "rbxassetid://100873005069458", -- Ruby
	[58] = "rbxassetid://115093465381546", -- Palladium
	[59] = "rbxassetid://132814741050348", -- Aquamarine
	[60] = "rbxassetid://102270041463765", -- Opal
	[61] = "rbxassetid://85942592397202", -- Platinum
	[62] = "rbxassetid://111245150246263", -- Stormstone
	[63] = "rbxassetid://136269057574956", -- Diamond
	[64] = "rbxassetid://108234004985931", -- Starmetal
	[65] = "rbxassetid://119762749928914", -- Aetherite
	[66] = "rbxassetid://77831716344758", -- Meteorite
	[67] = "rbxassetid://92007220043378", -- Soulstone
	[68] = "rbxassetid://133484613220954", -- Galaxite
	[69] = "rbxassetid://113724745569788", -- Frostfire
	[70] = "rbxassetid://90679313772697", -- Umbrite
	[71] = "rbxassetid://112965925536975", -- Celestine
	[72] = "rbxassetid://78674273437518", -- Orichalcum
	[73] = "rbxassetid://111534169597196", -- Spectrite
	[74] = "rbxassetid://136328848433908", -- Mythril
	[75] = "rbxassetid://105349328069762", -- Dragonstone
	[76] = "rbxassetid://75963722382671", -- Adamantite
	[77] = "rbxassetid://105793601559148", -- Thorium
	[78] = "rbxassetid://115033944144862", -- Uranium
	[79] = "rbxassetid://118227249881532", -- Plutonium
	[80] = "rbxassetid://80118378537979", -- Fermium
	[81] = "rbxassetid://75452082843008", -- Lawrencium
}

MineIcons.ORE_BOMB_CANVA = {
	[1] = "rbxassetid://105904532962955", -- Stone
	[2] = "rbxassetid://70819577273417", -- Clay
	[3] = "rbxassetid://135036674911979", -- Limestone
	[4] = "rbxassetid://120772536484539", -- Pumice
	[5] = "rbxassetid://93495697076429", -- Halite
	[6] = "rbxassetid://102834801069278", -- Coal
	[7] = "rbxassetid://122022175220511", -- Flint
	[8] = "rbxassetid://133939021209376", -- Basalt
	[9] = "rbxassetid://130777502231224", -- Slate
	[10] = "rbxassetid://125693853200784", -- Bone
	[11] = "rbxassetid://112269317620825", -- Granite
	[12] = "rbxassetid://110935928013473", -- Copper
	[13] = "rbxassetid://77549784987336", -- Tin
	[14] = "rbxassetid://121959468452574", -- Ember
	[15] = "rbxassetid://116072036500432", -- Sulfur
	[16] = "rbxassetid://124004501759515", -- Lead
	[17] = "rbxassetid://91124629403146", -- Zinc
	[18] = "rbxassetid://80981112719358", -- Aluminum
	[20] = "rbxassetid://82122909987792", -- Graphite
	[21] = "rbxassetid://91869013319813", -- Pyrite
	[22] = "rbxassetid://130254045536091", -- Marble
	[23] = "rbxassetid://103844744452711", -- Pearl
	[24] = "rbxassetid://92381467410451", -- Rime
	[25] = "rbxassetid://95446369942657", -- Quartz
	[26] = "rbxassetid://105866526927898", -- Amber
	[27] = "rbxassetid://71881543153673", -- Petrifact
	[28] = "rbxassetid://123659711346545", -- Nickel
	[30] = "rbxassetid://74136088240112", -- Bloodstone
	[31] = "rbxassetid://71952078604869", -- Garnet
	[32] = "rbxassetid://86610000189284", -- Citrine
	[33] = "rbxassetid://88213729369412", -- Chromium
	[34] = "rbxassetid://98296951392809", -- Turquoise
	[35] = "rbxassetid://91251103185713", -- Bismuth
	[36] = "rbxassetid://96465074454811", -- Silver
	[37] = "rbxassetid://73241224276746", -- Amethyst
	[38] = "rbxassetid://125754454292218", -- Tigereye
	[39] = "rbxassetid://107478533279594", -- Lapis
	[40] = "rbxassetid://86572938404841", -- Geode
	[41] = "rbxassetid://86585428346927", -- Topaz
	[42] = "rbxassetid://76041169090461", -- Phosphorus
	[43] = "rbxassetid://89371265648816", -- Peridot
	[44] = "rbxassetid://130436482392553", -- Jade
	[45] = "rbxassetid://74132945240920", -- Emberglass
	[46] = "rbxassetid://109984155916188", -- Tungsten
	[47] = "rbxassetid://104915628853560", -- Lithium
	[48] = "rbxassetid://118570877368074", -- Titanium
	[49] = "rbxassetid://105676289100899", -- Obsidian
	[50] = "rbxassetid://102450952716037", -- Cobalt
	[51] = "rbxassetid://105553651740641", -- Gold
	[52] = "rbxassetid://107570491202835", -- Regolith
	[53] = "rbxassetid://102884990022795", -- Sunstone
	[54] = "rbxassetid://121052211606537", -- Emerald
	[55] = "rbxassetid://79836425448745", -- Moonstone
	[56] = "rbxassetid://79321582931856", -- Sapphire
	[57] = "rbxassetid://132769884084168", -- Ruby
	[58] = "rbxassetid://100978511220210", -- Palladium
	[59] = "rbxassetid://125631442647337", -- Aquamarine
	[60] = "rbxassetid://133100366947019", -- Opal
	[61] = "rbxassetid://78379509249185", -- Platinum
	[62] = "rbxassetid://135958946943659", -- Stormstone
	[63] = "rbxassetid://77612989390597", -- Diamond
	[64] = "rbxassetid://75107276474277", -- Starmetal
	[66] = "rbxassetid://112580454179894", -- Meteorite
	[69] = "rbxassetid://113349213632967", -- Frostfire
	[70] = "rbxassetid://118912656395695", -- Umbrite
	[72] = "rbxassetid://138421185789687", -- Orichalcum
	[73] = "rbxassetid://114669080413522", -- Spectrite
	[74] = "rbxassetid://112511320432476", -- Mythril
	[75] = "rbxassetid://73977190463237", -- Dragonstone
	[76] = "rbxassetid://91663486636100", -- Adamantite
	[78] = "rbxassetid://138385813183877", -- Uranium
	[79] = "rbxassetid://125310857099158", -- Plutonium
	[80] = "rbxassetid://135392678682578", -- Fermium
	[81] = "rbxassetid://139031436591240", -- Lawrencium
}

-- The skin table for a forged family. Nil for a family with no art, which is
-- how forTool knows to fall back rather than draw a pickaxe on a fishing rod.
MineIcons.ORE_SKINS = {
	pickaxe = MineIcons.ORE_PICK,
	drill = MineIcons.ORE_DRILL,
	explosive = MineIcons.ORE_BOMB,
}
if MineIcons.NEW_TOOL_ICONS_SHARED then
	MineIcons.ORE_SKINS.hammer = MineIcons.ORE_HAMMER
	MineIcons.ORE_SKINS.jackhammer = MineIcons.ORE_JACKHAMMER
	for tier, id in pairs(MineIcons.ORE_PICK_CANVA) do
		MineIcons.ORE_PICK[tier] = id
	end
	for tier, id in pairs(MineIcons.ORE_DRILL_CANVA) do
		MineIcons.ORE_DRILL[tier] = id
	end
	for tier, id in pairs(MineIcons.ORE_BOMB_CANVA) do
		MineIcons.ORE_BOMB[tier] = id
	end
end

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
