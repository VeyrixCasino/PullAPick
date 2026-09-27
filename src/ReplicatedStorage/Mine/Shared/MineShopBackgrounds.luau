-- MineShopBackgrounds: full-screen ShopBg art by zone + depth seam.
-- Art source: assets/art/shop-backgrounds/

local MineShopBackgrounds = {}

local DEPTHS = { 0, 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000 }

-- zoneId -> { [seam] = "rbxassetid://..." }  seam 0 = surface
local ART = {
	meadow = {
		[0] = "rbxassetid://99417529955573",
		[500] = "rbxassetid://126104274066887",
		[1000] = "rbxassetid://102518411135004",
		[1500] = "rbxassetid://124457455786432",
		[2000] = "rbxassetid://140361241018834",
		[2500] = "rbxassetid://124468012234589",
		[3000] = "rbxassetid://102954409138232",
		[3500] = "rbxassetid://80934932467224",
		[4000] = "rbxassetid://136954905877762",
		[4500] = "rbxassetid://84102007366830",
		[5000] = "rbxassetid://71721922272381",
	},
	sunscar = {
		[0] = "rbxassetid://122981991569475",
		[500] = "rbxassetid://104979724796926",
		[1000] = "rbxassetid://86562067636905",
		[1500] = "rbxassetid://111086086954208",
		[2000] = "rbxassetid://126089178318499",
		[2500] = "rbxassetid://119221914721055",
		[3000] = "rbxassetid://117030950612695",
		[3500] = "rbxassetid://98664426494429",
		[4000] = "rbxassetid://119235253030168",
		[4500] = "rbxassetid://127127144568416",
		[5000] = "rbxassetid://91709923302580",
	},
	mistreef = {
		[0] = "rbxassetid://138500588472198",
		[500] = "rbxassetid://134483646202713",
		[1000] = "rbxassetid://88192326482869",
		[1500] = "rbxassetid://130021821829313",
		[2000] = "rbxassetid://132850147834755",
		[2500] = "rbxassetid://82275370843531",
		[3000] = "rbxassetid://91616107381804",
		[3500] = "rbxassetid://86662523088207",
		[4000] = "rbxassetid://118336273258027",
		[4500] = "rbxassetid://84241186193561",
		[5000] = "rbxassetid://118529115572671",
	},
	arcwork = {
		[0] = "rbxassetid://103917060694512",
		[500] = "rbxassetid://116518201641394",
		[1000] = "rbxassetid://109745772251820",
		[1500] = "rbxassetid://137620698080128",
		[2000] = "rbxassetid://102905529855929",
		[2500] = "rbxassetid://109767759246655",
		[3000] = "rbxassetid://83871762446007",
		[3500] = "rbxassetid://135855422390899",
		[4000] = "rbxassetid://124344522954312",
		[4500] = "rbxassetid://130002005077375",
		[5000] = "rbxassetid://126770354888777",
	},
	bloodmoon = {
		[0] = "rbxassetid://106350227848173",
		[500] = "rbxassetid://101650554068890",
		[1000] = "rbxassetid://139291564467491",
		[1500] = "rbxassetid://78028663315324",
		[2000] = "rbxassetid://76575606898059",
		[2500] = "rbxassetid://97251330331190",
		[3000] = "rbxassetid://129351308533141",
		[3500] = "rbxassetid://110891324737307",
		[4000] = "rbxassetid://129308176550195",
		[4500] = "rbxassetid://121915141180911",
		[5000] = "rbxassetid://91355333356772",
	},
	eclipse = {
		[0] = "rbxassetid://82344231323770",
		[500] = "rbxassetid://92963014032569",
		[1000] = "rbxassetid://122073134509561",
		[1500] = "rbxassetid://78388459637503",
		[2000] = "rbxassetid://138638075896455",
		[2500] = "rbxassetid://138091208852092",
		[3000] = "rbxassetid://91983044357816",
		[3500] = "rbxassetid://107578464832670",
		[4000] = "rbxassetid://98658454141348",
		[4500] = "rbxassetid://89942503656678",
		[5000] = "rbxassetid://72488172981400",
	},
	riftmarch = {
		[0] = "rbxassetid://107150795954326",
		[500] = "rbxassetid://72560867677241",
		[1000] = "rbxassetid://112895934105573",
		[1500] = "rbxassetid://113358969402018",
		[2000] = "rbxassetid://89581835968263",
		[2500] = "rbxassetid://80972216585663",
		[3000] = "rbxassetid://102369486378455",
		[3500] = "rbxassetid://130126567591047",
		[4000] = "rbxassetid://105238109514828",
		[4500] = "rbxassetid://110920000422738",
		[5000] = "rbxassetid://97952277700271",
	},
	starfall = {
		[0] = "rbxassetid://132142526894747",
		[500] = "rbxassetid://122716054647473",
		[1000] = "rbxassetid://77121651140016",
		[1500] = "rbxassetid://132240693757432",
		[2000] = "rbxassetid://134749794738987",
		[2500] = "rbxassetid://73235080338445",
		[3000] = "rbxassetid://100093495480509",
		[3500] = "rbxassetid://126091773343285",
		[4000] = "rbxassetid://117030962726496",
		[4500] = "rbxassetid://84937225044804",
		[5000] = "rbxassetid://100867398227806",
	},
	mythral = {
		[0] = "rbxassetid://129972287934876",
		[500] = "rbxassetid://115156397411571",
		[1000] = "rbxassetid://102746412701208",
		[1500] = "rbxassetid://100388031623799",
		[2000] = "rbxassetid://103939029972993",
		[2500] = "rbxassetid://138857284923507",
		[3000] = "rbxassetid://128047678956997",
		[3500] = "rbxassetid://94428068693922",
		[4000] = "rbxassetid://136596706451433",
		[4500] = "rbxassetid://130701780195422",
		[5000] = "rbxassetid://132436009138203",
	},
	primordium = {
		[0] = "rbxassetid://136446637174169",
		[500] = "rbxassetid://82144787728806",
		[1000] = "rbxassetid://129833301872659",
		[1500] = "rbxassetid://76456186199047",
		[2000] = "rbxassetid://111884015130587",
		[2500] = "rbxassetid://70952578251654",
		[3000] = "rbxassetid://130084471284418",
		[3500] = "rbxassetid://103229264082837",
		[4000] = "rbxassetid://103892176452934",
		[4500] = "rbxassetid://105477858549009",
		[5000] = "rbxassetid://72769703113683",
	},
	bigbang = {
		[0] = "rbxassetid://78503775344359",
		[500] = "rbxassetid://115736664029040",
		[1000] = "rbxassetid://104316672072547",
		[1500] = "rbxassetid://113579111770415",
		[2000] = "rbxassetid://89519418214607",
		[2500] = "rbxassetid://72759820958248",
		[3000] = "rbxassetid://86162445906494",
		[3500] = "rbxassetid://131382961556960",
		[4000] = "rbxassetid://92327898976303",
		[4500] = "rbxassetid://134833207676861",
		[5000] = "rbxassetid://86132363122247",
	},
}

local function nearestSeam(depth)
	depth = math.max(0, math.floor(tonumber(depth) or 0))
	local best = 0
	for _, s in ipairs(DEPTHS) do
		if s <= depth then
			best = s
		end
	end
	return best
end

function MineShopBackgrounds.image(zoneId, depthOrSeam)
	zoneId = tostring(zoneId or "meadow")
	local pack = ART[zoneId] or ART.meadow
	local seam = nearestSeam(depthOrSeam)
	return pack[seam] or pack[0] or ART.meadow[0]
end

function MineShopBackgrounds.apply(imageLabel, zoneId, depthOrSeam)
	if not imageLabel then
		return
	end
	local img = MineShopBackgrounds.image(zoneId, depthOrSeam)
	if img and img ~= "" then
		imageLabel.Image = img
		imageLabel.ScaleType = Enum.ScaleType.Crop
	end
end

MineShopBackgrounds.ART = ART
MineShopBackgrounds.DEPTHS = DEPTHS

return MineShopBackgrounds
