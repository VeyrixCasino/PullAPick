-- MineAudio: punchy licensed SFX (Pro Sound Effects / APM) plus a quiet bed.
-- Digs layer a rock thunk with crackle, sit on the block, and run through a
-- compressor so they read over ambience without stacking into noise.
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local MineAudio = {}

MineAudio.BGM_VOL = 0.10

-- One id, or a list to pick from at random.
MineAudio.IDS = {
	bgm = "",
	pickaxe = {
		"rbxassetid://9118598279", -- Rock Hit Dirt 14
		"rbxassetid://9118598469", -- 15
		"rbxassetid://9118598729", -- 20
		"rbxassetid://9118598470", -- 16
		"rbxassetid://9118598720", -- 19, shortest
		"rbxassetid://9118598288", -- 13
		"rbxassetid://9118598973", -- 21
		"rbxassetid://9118597117", -- 4
	},
	gravel = {
		"rbxassetid://9118598720",
		"rbxassetid://9118598279",
		"rbxassetid://9118598470",
	},
	drill = {
		"rbxassetid://9114242638", -- 0.9s burst
		"rbxassetid://9114242779", -- 0.6s burst
		"rbxassetid://9114242039", -- 1.3s
	},
	explosive = {
		"rbxassetid://9116973611", -- mortar thump
		"rbxassetid://9114362114", -- dull charge
		"rbxassetid://9120705982", -- whoosh blast
	},
	boom = "rbxassetid://9114086657", -- dirt explosion
	shop = {
		"rbxassetid://9113848518", -- coin toss
		"rbxassetid://9113704038", -- coin insert
		"rbxassetid://9125509503", -- heavy coin
	},
	pack = "rbxassetid://9125414959", -- burlap rip
	open = "rbxassetid://9125414959",
	pack_rise = "rbxassetid://9120057087",
	pack_foil = {
		"rbxassetid://9113848518",
		"rbxassetid://9116397026",
	},
	pack_tear = {
		"rbxassetid://9125414959",
		"rbxassetid://9119717523",
	},
	pack_sparkle = {
		"rbxassetid://9116394545",
		"rbxassetid://9116395424",
		"rbxassetid://9116396987",
	},
	pack_burst = {
		"rbxassetid://9120705982",
		"rbxassetid://9116395089",
	},
	sell = {
		"rbxassetid://9114058693",
		"rbxassetid://9113848518",
		"rbxassetid://9125509503",
	},
	found = {
		"rbxassetid://9116394545",
		"rbxassetid://9116394876",
		"rbxassetid://9116395424",
	},
	lucky = {
		"rbxassetid://9116394545",
		"rbxassetid://9116394876",
		"rbxassetid://9116395424",
	},
	lucky_rattle = {
		"rbxassetid://9118596772",
		"rbxassetid://9118597103",
		"rbxassetid://9119717523",
	},
	lucky_pop = {
		"rbxassetid://9116395089",
		"rbxassetid://9116394876",
	},
	equip = "rbxassetid://9119717523", -- switch click
	rebirth = "rbxassetid://1840076509", -- APM sting
	tick = "rbxassetid://9119717523",
	spin = "rbxassetid://9120705982",
	reveal = "rbxassetid://9116394876",
	jackpot = "rbxassetid://9116395089",
	flash = "rbxassetid://9120705982",
	thud = {
		"rbxassetid://9118596772",
		"rbxassetid://9118597103",
	},
	flip = "rbxassetid://9113848518",
	loot = {
		"rbxassetid://9113848518",
		"rbxassetid://9113704038",
	},
	riser = "rbxassetid://9120057087",
	rare = "rbxassetid://9116395089",
	crunch = {
		"rbxassetid://9118596772",
		"rbxassetid://9118597462",
		"rbxassetid://9118598722",
	},
}

-- Per-zone soft beds (ambience-first, not melodic earworms). Quiet vols.
MineAudio.ZONE_BEDS = {
	lobby = { id = "rbxassetid://9112835068", vol = 0.055 },
	meadow = { id = "rbxassetid://9112781510", vol = 0.06 },
	sunscar = { id = "rbxassetid://9114057104", vol = 0.05 },
	mistreef = { id = "rbxassetid://9112805227", vol = 0.055 },
	arcwork = { id = "rbxassetid://9112775175", vol = 0.035 },
	bloodmoon = { id = "rbxassetid://9114228774", vol = 0.04 },
	eclipse = { id = "rbxassetid://9118747853", vol = 0.03 },
	riftmarch = { id = "rbxassetid://9120505513", vol = 0.07 },
	starfall = { id = "rbxassetid://9112775175", vol = 0.032 },
	mythral = { id = "rbxassetid://273398061", vol = 0.05 },
	primordium = { id = "rbxassetid://9118747853", vol = 0.028 },
	bigbang = { id = "rbxassetid://9114228774", vol = 0.03 },
	surface = { id = "rbxassetid://9112835068", vol = 0.055 },
	mine = { id = "rbxassetid://9120505513", vol = 0.08 },
}
MineAudio.AMBIENCE = MineAudio.ZONE_BEDS
MineAudio.MINE_Y = -3

local VOL = {
	pickaxe = 0.62,
	gravel = 0.34,
	drill = 0.48,
	explosive = 0.58,
	boom = 0.46,
	shop = 0.40,
	sell = 0.48,
	found = 0.52,
	pack = 0.64,
	open = 0.64,
	pack_rise = 0.36,
	pack_foil = 0.42,
	pack_tear = 0.68,
	pack_sparkle = 0.52,
	pack_burst = 0.56,
	lucky = 0.50,
	lucky_rattle = 0.38,
	lucky_pop = 0.56,
	equip = 0.34,
	rebirth = 0.50,
	tick = 0.20,
	spin = 0.36,
	reveal = 0.54,
	jackpot = 0.66,
	flash = 0.40,
	thud = 0.50,
	flip = 0.34,
	loot = 0.28,
	riser = 0.38,
	rare = 0.54,
	crunch = 0.72,
}

local CD = {
	pickaxe = 0.06,
	gravel = 0.04,
	drill = 0.12,
	explosive = 0.28,
	boom = 0.24,
	shop = 0.18,
	sell = 0.35,
	found = 0.40,
	pack = 0.25,
	open = 0.25,
	pack_rise = 0.40,
	pack_foil = 0.30,
	pack_tear = 0.25,
	pack_sparkle = 0.18,
	pack_burst = 0.40,
	lucky = 0.18,
	lucky_rattle = 0.05,
	lucky_pop = 0.35,
	equip = 0.08,
	rebirth = 0.80,
	tick = 0.016,
	spin = 0.22,
	reveal = 0.10,
	jackpot = 0.55,
	flash = 0.18,
	thud = 0.07,
	flip = 0.04,
	loot = 0.14,
	riser = 0.70,
	rare = 0.25,
	crunch = 0.08,
}

-- Cut long library takes so a 3s dirt boom does not linger under the next swing.
local TRIM = {
	pickaxe = 0.38,
	gravel = 0.24,
	drill = 0.50,
	equip = 0.26,
	tick = 0.08,
	flip = 0.36,
	shop = 0.55,
	sell = 0.70,
	found = 0.85,
	flash = 0.40,
	spin = 0.55,
	pack_rise = 0.55,
	pack_foil = 0.45,
	pack_tear = 0.55,
	pack_sparkle = 0.70,
	pack_burst = 0.55,
	lucky_rattle = 0.22,
}

local lastAt = {}
local musicGroup, sfxGroup, bgmSound
local worldEmit
-- The Settings panel's switches; remembered so groups made later obey them.
local sfxEnabled, ambienceEnabled = true, true

local function groups()
	if musicGroup then
		return
	end
	musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "MineMusic"
	musicGroup.Volume = ambienceEnabled and 1 or 0
	musicGroup.Parent = SoundService
	sfxGroup = Instance.new("SoundGroup")
	sfxGroup.Name = "MineSfx"
	sfxGroup.Volume = sfxEnabled and 1 or 0
	sfxGroup.Parent = SoundService
	local punch = Instance.new("CompressorSoundEffect")
	punch.Name = "Punch"
	punch.Threshold = -18
	punch.Ratio = 10
	punch.Attack = 0.003
	punch.Release = 0.09
	-- No makeup gain here. CompressorSoundEffect has no Gain (nor MakeupGain)
	-- property at all, so this line threw, and it threw inside groups(), which
	-- startBgm() calls on the first line of MineClient -- taking every UI in the
	-- game down with it. The 9 dB it wanted is folded into the EQ below instead,
	-- applied evenly so the tone is unchanged.
	punch.Parent = sfxGroup
	local eq = Instance.new("EqualizerSoundEffect")
	eq.Name = "Body"
	eq.LowGain = 9
	eq.MidGain = 6
	eq.HighGain = 7
	eq.Parent = sfxGroup
end

-- Sound effects on or off (the Settings panel).
function MineAudio.setSfxEnabled(on)
	sfxEnabled = on ~= false
	groups()
	sfxGroup.Volume = sfxEnabled and 1 or 0
end

-- Ambience (and music, if any is ever set) on or off.
function MineAudio.setAmbienceEnabled(on)
	ambienceEnabled = on ~= false
	groups()
	musicGroup.Volume = ambienceEnabled and 1 or 0
end

local function validId(id)
	return type(id) == "string" and id ~= "" and id ~= "rbxassetid://0"
end

local function pick(entry)
	if type(entry) == "table" then
		if #entry == 0 then
			return nil
		end
		return entry[math.random(1, #entry)]
	end
	return entry
end

-- `pitch` (optional) sets PlaybackSpeed; case ticks climb as the reel slows.
-- `at` (optional Vector3) puts the sound on the block so it sits in the world.
-- `skipCd` lets a layer fire under a swing without eating the next swing's CD.
function MineAudio.play(name, extraVol, pitch, at, skipCd)
	groups()
	if name == "open" then
		name = "pack"
	end
	local id = pick(MineAudio.IDS[name])
	if not validId(id) then
		return
	end
	local now = os.clock()
	local waitFor = CD[name] or 0.2
	if not skipCd then
		if lastAt[name] and (now - lastAt[name]) < waitFor then
			return
		end
		lastAt[name] = now
	end
	local parent = SoundService
	if typeof(at) == "Vector3" then
		if not worldEmit or not worldEmit.Parent then
			local emitter = Instance.new("Part")
			emitter.Name = "MineSfxAt"
			emitter.Anchored = true
			emitter.CanCollide = false
			emitter.CanQuery = false
			emitter.CanTouch = false
			emitter.Transparency = 1
			emitter.Size = Vector3.new(0.4, 0.4, 0.4)
			emitter.Parent = workspace
			worldEmit = emitter
		end
		worldEmit.CFrame = CFrame.new(at)
		parent = worldEmit
	end
	local s = Instance.new("Sound")
	s.Name = "MineSfx_" .. tostring(name)
	s.SoundId = id
	s.Volume = (VOL[name] or 0.3) * (extraVol or 1)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 10
	s.RollOffMaxDistance = 90
	s.SoundGroup = sfxGroup
	-- Digs and UI clicks drift so eight swings in a row never machine-gun.
	if name == "pickaxe" or name == "gravel" or name == "drill" or name == "equip" or name == "crunch"
		or name == "lucky_rattle" or name == "pack_tear" or name == "loot" then
		s.PlaybackSpeed = 0.88 + math.random() * 0.22
	end
	if tonumber(pitch) then
		s.PlaybackSpeed = math.clamp(tonumber(pitch), 0.25, 3)
	end
	s.Parent = parent
	s:Play()
	local trim = TRIM[name]
	if trim then
		task.delay(trim, function()
			if s.Parent then
				TweenService:Create(s, TweenInfo.new(0.08), { Volume = 0 }):Play()
			end
		end)
	end
	Debris:AddItem(s, 8)
end

function MineAudio.playDig(tool, at)
	local fam = ""
	if type(tool) == "table" then
		fam = tostring(tool.family or tool.kind or "")
	end
	if fam == "drill" then
		MineAudio.play("drill", 1, nil, at)
		MineAudio.play("gravel", 0.6, 1.18, at, true)
	elseif fam == "explosive" then
		MineAudio.play("explosive", 1, nil, at)
		MineAudio.play("boom", 0.8, 0.94, at, true)
		MineAudio.play("gravel", 0.45, 0.9, at, true)
	else
		MineAudio.play("pickaxe", 1, nil, at)
		MineAudio.play("gravel", 0.75, 1.12, at, true)
	end
end

function MineAudio.playSell(coins, gems)
	local fat = math.clamp(((tonumber(coins) or 0) + (tonumber(gems) or 0) * 8) / 5000, 0.85, 1.25)
	MineAudio.play("sell", fat)
	task.delay(0.08, function()
		MineAudio.play("shop", 0.7 * fat, nil, nil, true)
	end)
end

function MineAudio.playFound(oneIn)
	local n = tonumber(oneIn) or 50
	if n >= 1000 then
		MineAudio.play("rare", 1.1)
		MineAudio.play("riser", 0.85, nil, nil, true)
	elseif n >= 150 then
		MineAudio.play("found", 1)
		MineAudio.play("reveal", 0.7, nil, nil, true)
	else
		MineAudio.play("found", 0.85)
	end
end

function MineAudio.playPackCeremony()
	MineAudio.play("pack_rise", 1)
	task.delay(0.35, function()
		MineAudio.play("pack_foil", 1)
	end)
	task.delay(0.85, function()
		MineAudio.play("pack", 1)
		MineAudio.play("pack_tear", 0.9, nil, nil, true)
	end)
	task.delay(1.05, function()
		MineAudio.play("pack_sparkle", 1)
	end)
	task.delay(1.25, function()
		MineAudio.play("pack_burst", 0.9)
		MineAudio.play("pack_sparkle", 0.7, 1.15, nil, true)
	end)
end

function MineAudio.playLuckyOpen()
	MineAudio.play("lucky_rattle", 1)
	task.delay(0.12, function()
		MineAudio.play("lucky", 1)
	end)
end

function MineAudio.playLuckyWin(rank)
	rank = tonumber(rank) or 1
	if rank >= 6 then
		MineAudio.play("jackpot", 1.1)
		MineAudio.play("flash", 1, nil, nil, true)
		MineAudio.play("pack_sparkle", 0.9, nil, nil, true)
	elseif rank >= 4 then
		MineAudio.play("lucky_pop", 1)
		MineAudio.play("reveal", 0.85, nil, nil, true)
	else
		MineAudio.play("thud", 0.85)
		MineAudio.play("reveal", 0.6, nil, nil, true)
	end
end

-- Card flip / pull-hit bands from PackReveal + PackFX.
function MineAudio.playCard(band)
	band = tostring(band or "HIT")
	MineAudio.play("flip")
	if band == "GOD" then
		MineAudio.play("jackpot", 1.15, nil, nil, true)
		MineAudio.play("flash", 1, nil, nil, true)
		MineAudio.play("pack_sparkle", 1, 1.1, nil, true)
		task.delay(0.12, function()
			MineAudio.play("pack_burst", 0.85, nil, nil, true)
		end)
	elseif band == "CHASE" then
		MineAudio.play("rare", 1, nil, nil, true)
		MineAudio.play("reveal", 0.9, nil, nil, true)
		MineAudio.play("pack_sparkle", 0.75, nil, nil, true)
	elseif band == "HIT" then
		MineAudio.play("reveal", 0.85, nil, nil, true)
		MineAudio.play("pack_foil", 0.55, nil, nil, true)
	elseif band == "NICE" then
		MineAudio.play("thud", 0.65)
	end
end

function MineAudio.playPull(band)
	band = tostring(band or "HIT")
	if band == "DUD" or band == "" then
		return
	end
	if band == "GOD" then
		MineAudio.play("jackpot", 1)
		MineAudio.play("flash", 0.9, nil, nil, true)
	elseif band == "CHASE" then
		MineAudio.play("rare", 0.95)
	elseif band == "HIT" then
		MineAudio.play("reveal", 0.7)
	else
		MineAudio.play("thud", 0.5)
	end
end

function MineAudio.playLoot()
	MineAudio.play("loot", 1, 1.12)
end

function MineAudio.setZoneResolver(fn)
	MineAudio._zoneResolver = fn
end

--------------------------------------------------------------------------------
-- AMBIENCE
--------------------------------------------------------------------------------

local beds = {}
local ambienceOn = false

local function bed(key)
	if beds[key] then
		return beds[key]
	end
	local def = MineAudio.AMBIENCE[key]
	if not def or not validId(def.id) then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = "MineAmbience_" .. key
	s.SoundId = def.id
	s.Looped = true
	s.Volume = 0
	s.SoundGroup = musicGroup
	s.Parent = SoundService
	s:Play()
	beds[key] = s
	return s
end

-- Fade to one bed and out of the other. Called once a second.
function MineAudio.setAmbience(key)
	groups()
	if not key or not MineAudio.AMBIENCE[key] then
		key = "surface"
	end
	for k, def in pairs(MineAudio.AMBIENCE) do
		local s = bed(k)
		if s then
			local goal = (k == key) and (def.vol or 0.05) or 0
			if math.abs(s.Volume - goal) > 0.001 then
				TweenService:Create(s, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ Volume = goal }):Play()
			end
		end
	end
end

MineAudio.setZone = MineAudio.setAmbience

function MineAudio.startAmbience()
	if ambienceOn then
		return
	end
	ambienceOn = true
	task.spawn(function()
		local okCfg, Config = pcall(function()
			return require(script.Parent:WaitForChild("MineConfig", 10))
		end)
		local atSurface = okCfg and type(Config) == "table" and Config.atSurface or nil
		local current
		while ambienceOn do
			local want
			local zr = MineAudio._zoneResolver
			if zr then
				local ok, zid = pcall(zr)
				if ok and type(zid) == "string" and zid ~= "" and MineAudio.AMBIENCE[zid] then
					want = zid
				end
			end
			if not want then
				local plr = Players.LocalPlayer
				local root = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				local pos = root and root.Position
				if pos and atSurface and atSurface(pos) then
					want = "lobby"
				elseif pos and pos.Y < MineAudio.MINE_Y then
					want = "mine"
				else
					want = "surface"
				end
			end
			if want ~= current then
				current = want
				MineAudio.setAmbience(want)
			end
			task.wait(1.1)
		end
	end)
end

-- Fade the beds out and stop following the player (a mute toggle can call this).
function MineAudio.stopAmbience()
	ambienceOn = false
	for _, s in pairs(beds) do
		TweenService:Create(s, TweenInfo.new(1), { Volume = 0 }):Play()
	end
end

function MineAudio.startBgm()
	groups()
	MineAudio.startAmbience()
	if bgmSound then
		return
	end
	local id = MineAudio.IDS.bgm
	if not validId(id) then
		return
	end
	local s = Instance.new("Sound")
	s.Name = "MineBgm"
	s.SoundId = id
	s.Looped = true
	s.Volume = 0
	s.SoundGroup = musicGroup
	s.Parent = SoundService
	s:Play()
	bgmSound = s
	TweenService:Create(s, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Volume = MineAudio.BGM_VOL,
	}):Play()
end

return MineAudio
