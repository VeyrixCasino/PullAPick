-- MineAudio: licensed SFX (Pro Sound Effects / APM), a nature bed and a quiet
-- music playlist. Tuned to keep players content rather than wound up: warm
-- major-key acoustic music at resting-heart-rate tempos, soft highs, no
-- alarm-like or casino-style escalation, and gaps of silence between tracks.
-- Digs layer a rock thunk with crackle, sit on the block, and run through a
-- gentle compressor so they read over the bed without stacking into noise.
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local MineAudio = {}

MineAudio.BGM_VOL = 0.16
-- Seconds of silence between tracks; constant music is what players mute.
MineAudio.MUSIC_GAP = { 18, 40 }

-- Surface: carefree, open, mid-tempo. Underground: slower and quieter, since
-- digging is repetitive focus work and lower-arousal music suits it.
MineAudio.MUSIC = {
	bright = {
		"rbxassetid://1839843882", -- A Welcome Smile: inviting carefree acoustic
		"rbxassetid://1839844012", -- Feel The Breeze: carefree open-air guitar
		"rbxassetid://1842285702", -- On the Go: light-hearted easy listening
		"rbxassetid://9039827617", -- Ponder Steps: 102 bpm chilled guitar
		"rbxassetid://9039827056", -- Bredie On A Sunday: 96 bpm warm guitar
		"rbxassetid://9038622067", -- Lakefront Days: soft hopeful ukulele
		"rbxassetid://1845913205", -- Walking On The Beach: ukulele solo
	},
	calm = {
		"rbxassetid://1842276007", -- Tranquilo: peaceful classical guitar
		"rbxassetid://9042458043", -- Down In The Valley: restful lullaby guitar
		"rbxassetid://1836754180", -- Little Moment Of Calm
		"rbxassetid://1839737612", -- Peaceful Forest
		"rbxassetid://1839835149", -- Mellow Out
		"rbxassetid://9038622067", -- Lakefront Days
	},
}

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
	},
	boom = "rbxassetid://9114086657", -- dirt explosion
	shop = {
		"rbxassetid://9113848518", -- coin toss
		"rbxassetid://9113704038", -- coin insert
		"rbxassetid://9125509503", -- heavy coin
	},
	pack = "rbxassetid://9125414959", -- burlap rip
	open = "rbxassetid://9125414959",
	pack_rise = "rbxassetid://9116394545", -- soft chime (was a searing build-up)
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
		"rbxassetid://9116395089",
		"rbxassetid://9116394876",
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
	click = "rbxassetid://9113885761", -- every UI button: tiny soft tick
	--[[
		A press that did NOTHING needs to say so.

		Clicking a greyed FORGE or an unaffordable buy was silent, which is the
		one thing a button must never be: silence is what a broken button sounds
		like, so a player who cannot afford something cannot tell that from a UI
		that failed. A short dull knock, well under the click in level, reads as
		"heard you, no" without scolding -- the thing to avoid here is the
		buzzer, which is the most aggravating sound a UI can make and gets worse
		every time.
	]]
	deny = "rbxassetid://9118596772", -- dull knock, trimmed hard and pitched down
	equip = "rbxassetid://9119717523", -- switch click
	rebirth = "rbxassetid://9116395424", -- warm chime cluster
	tick = "rbxassetid://9119717523",
	spin = "rbxassetid://9116394876",
	reveal = "rbxassetid://9116394876",
	jackpot = "rbxassetid://9116395089",
	flash = "rbxassetid://9116395424",
	thud = {
		"rbxassetid://9118596772",
		"rbxassetid://9118597103",
	},
	flip = "rbxassetid://9113848518",
	loot = {
		"rbxassetid://9113848518",
		"rbxassetid://9113704038",
	},
	riser = "rbxassetid://9116394545",
	rare = "rbxassetid://9116395089",
	crunch = {
		"rbxassetid://9118596772",
		"rbxassetid://9118597462",
		"rbxassetid://9118598722",
	},
}

-- Per-zone soft beds under the music. Natural sounds only (birds, leaves,
-- water, light wind): groans, howls and low rumbles read as threat and keep
-- players on edge, so the darker zones get wind and water instead.
MineAudio.ZONE_BEDS = {
	lobby = { id = "rbxassetid://9112835068", vol = 0.05 },
	meadow = { id = "rbxassetid://9112781510", vol = 0.05 },
	sunscar = { id = "rbxassetid://9114057104", vol = 0.04 },
	mistreef = { id = "rbxassetid://9112805227", vol = 0.045 },
	arcwork = { id = "rbxassetid://9120505513", vol = 0.05 },
	bloodmoon = { id = "rbxassetid://9114057104", vol = 0.035 },
	eclipse = { id = "rbxassetid://9114057104", vol = 0.03 },
	riftmarch = { id = "rbxassetid://9120505513", vol = 0.06 },
	starfall = { id = "rbxassetid://9120505513", vol = 0.045 },
	mythral = { id = "rbxassetid://273398061", vol = 0.045 },
	primordium = { id = "rbxassetid://9120505513", vol = 0.04 },
	bigbang = { id = "rbxassetid://9114057104", vol = 0.03 },
	surface = { id = "rbxassetid://9112835068", vol = 0.055 },
	mine = { id = "rbxassetid://9120505513", vol = 0.065 },
}
MineAudio.AMBIENCE = MineAudio.ZONE_BEDS
MineAudio.MINE_Y = -3

-- Sounds heard hundreds of times an hour (digs, clicks) sit lowest; rewards
-- are pleasant but only a little louder than the work, never a blast.
local VOL = {
	pickaxe = 0.50,
	gravel = 0.28,
	drill = 0.40,
	explosive = 0.48,
	boom = 0.38,
	shop = 0.36,
	sell = 0.42,
	found = 0.46,
	pack = 0.50,
	open = 0.50,
	pack_rise = 0.30,
	pack_foil = 0.36,
	pack_tear = 0.50,
	pack_sparkle = 0.44,
	pack_burst = 0.46,
	lucky = 0.44,
	lucky_rattle = 0.30,
	lucky_pop = 0.46,
	click = 0.24,
	deny = 0.20,
	equip = 0.30,
	rebirth = 0.48,
	tick = 0.16,
	spin = 0.28,
	reveal = 0.46,
	jackpot = 0.50,
	flash = 0.30,
	thud = 0.42,
	flip = 0.30,
	loot = 0.24,
	riser = 0.30,
	rare = 0.48,
	crunch = 0.55,
}

-- Celebrations dip the music briefly instead of shouting over it.
local DUCK = { jackpot = 2.2, rare = 1.6, rebirth = 2.5, lucky_pop = 1.2, found = 1.0 }

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
	click = 0.035,
	deny = 0.10,
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
	click = 0.12,
	deny = 0.14,
	equip = 0.26,
	rebirth = 2.4,
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
local musicMood = "bright"
local duckUntil = 0
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
	-- A gentle leveller, not a squash: hard compression plus a big treble lift
	-- made every hit bright and fatiguing over a long session.
	local punch = Instance.new("CompressorSoundEffect")
	punch.Name = "Punch"
	punch.Threshold = -16
	punch.Ratio = 4
	punch.Attack = 0.006
	punch.Release = 0.12
	-- CompressorSoundEffect has no Gain (nor MakeupGain) property; setting one
	-- throws inside groups(), which runs on the first line of MineClient.
	punch.Parent = sfxGroup
	-- Warm body, rolled-off highs: soft attack is what reads as friendly.
	local eq = Instance.new("EqualizerSoundEffect")
	eq.Name = "Body"
	eq.LowGain = 5
	eq.MidGain = 3
	eq.HighGain = -3
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

-- Dip the music for `secs`, then ease it back.
function MineAudio.duck(secs)
	local now = os.clock()
	local untilAt = now + (tonumber(secs) or 1.5)
	if untilAt <= duckUntil then
		return
	end
	duckUntil = untilAt
	local s = bgmSound
	if not s or not s.Parent then
		return
	end
	TweenService:Create(s, TweenInfo.new(0.25), { Volume = MineAudio.BGM_VOL * 0.4 }):Play()
	task.delay(untilAt - now, function()
		if os.clock() + 0.05 >= duckUntil and s.Parent and s:GetAttribute("Live") then
			TweenService:Create(s, TweenInfo.new(1.4, Enum.EasingStyle.Sine), { Volume = MineAudio.BGM_VOL }):Play()
		end
	end)
end

-- A small soft tick on every button under `root`, now and later. Buttons can
-- opt out with the NoClickSfx attribute.
function MineAudio.bindUiClicks(root)
	if not root or root:GetAttribute("UiClicksBound") then
		return
	end
	root:SetAttribute("UiClicksBound", true)
	--[[
		Activated does not fire on a button with Active = false, which is how
		most disabled buttons in this game are built -- so the press that most
		needs feedback was the one press that made no sound at all. InputBegan
		still fires there, so the deny knock hangs off that and is gated on the
		button being inactive, which is exactly the case Activated misses.

		Order matters: a button that IS active gets its click from Activated as
		before and must not also knock, or every normal press doubles up.
	]]
	local function hook(b)
		if not b:IsA("GuiButton") then
			return
		end
		b.Activated:Connect(function()
			if not b:GetAttribute("NoClickSfx") then
				MineAudio.play("click")
			end
		end)
		b.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if b.Active or b:GetAttribute("NoClickSfx") then
				return
			end
			MineAudio.play("deny")
		end)
	end
	for _, d in root:GetDescendants() do
		hook(d)
	end
	root.DescendantAdded:Connect(hook)
end

--[[
	A SHUFFLE BAG, NOT A DICE ROLL. This is the single biggest thing standing
	between eight pickaxe samples and a sound that grates.

	math.random over a list does not sound random, it sounds BROKEN. With eight
	variants there is a 1-in-8 chance each swing repeats the last one and a
	1-in-64 chance of three in a row, so across a few hundred swings -- which is
	a couple of minutes of mining -- a player hears the same clip back to back
	dozens of times. A repeat is the exact event the ear flags as "this is a
	recording", and once it is flagged every later repeat is louder for it. The
	variants were already there; randomness was wasting them.

	So: draw without replacement. Every variant plays once before any plays
	twice, and the reshuffle refuses to start a fresh bag with the clip that
	just ended the last one -- otherwise the seam between bags is the one place
	an immediate repeat can still happen.

	Keyed per sound name, because the bags must not share state: a drill swing
	drawing from the pickaxe bag would reintroduce the repeats this removes.
]]
local bags = {}

local function pick(entry, key)
	if type(entry) ~= "table" then
		return entry
	end
	local n = #entry
	if n == 0 then
		return nil
	end
	if n == 1 then
		return entry[1]
	end
	key = key or tostring(entry)
	local bag = bags[key]
	if not bag or #bag.order == 0 or bag.n ~= n then
		local order = {}
		for i = 1, n do
			order[i] = i
		end
		-- Fisher-Yates, then push a seam-repeat to the back.
		for i = n, 2, -1 do
			local j = math.random(1, i)
			order[i], order[j] = order[j], order[i]
		end
		if bag and bag.last and order[#order] == bag.last and n > 1 then
			order[#order], order[1] = order[1], order[#order]
		end
		bag = { order = order, n = n, last = bag and bag.last }
		bags[key] = bag
	end
	local idx = table.remove(bag.order)
	bag.last = idx
	return entry[idx]
end

--[[
	SUSTAINED FIRE RECEDES.

	A sound at full volume every 0.3 seconds for an hour is fatiguing however
	nice the sample is, and mining is exactly that. Holding a swing now walks
	the level down a little and settles there; stopping for a breath brings it
	straight back. The player stops noticing the hits while they are mining and
	still gets the full one when they start again, which is when it carries
	information.

	Deliberately shallow -- REPEAT_FLOOR is 0.72, so this is a touch under a
	quarter off and never a fade to nothing. The hit still has to read as a
	hit; this is the difference between a sound you stop hearing and a sound
	you turn off.
]]
local REPEAT_FLOOR = 0.72
local REPEAT_STEP = 0.055
local REPEAT_FORGET = 1.1
local repeatRun = {}

local function repeatGain(name, now)
	local r = repeatRun[name]
	if not r or (now - r.at) > REPEAT_FORGET then
		repeatRun[name] = { at = now, n = 1 }
		return 1
	end
	r.at = now
	r.n += 1
	return math.max(REPEAT_FLOOR, 1 - (r.n - 1) * REPEAT_STEP)
end

-- `pitch` (optional) sets PlaybackSpeed; case ticks climb as the reel slows.
-- `at` (optional Vector3) puts the sound on the block so it sits in the world.
-- `skipCd` lets a layer fire under a swing without eating the next swing's CD.
function MineAudio.play(name, extraVol, pitch, at, skipCd)
	groups()
	if name == "open" then
		name = "pack"
	end
	local id = pick(MineAudio.IDS[name], name)
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
	-- Held-down repetition eases off; a pause brings it back to full.
	local run = repeatGain(name, now)
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
	s.Volume = (VOL[name] or 0.3) * (extraVol or 1) * run
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 10
	s.RollOffMaxDistance = 90
	s.SoundGroup = sfxGroup
	-- Digs and UI clicks drift so eight swings in a row never machine-gun.
	if name == "pickaxe" or name == "gravel" or name == "drill" or name == "equip" or name == "crunch"
		or name == "lucky_rattle" or name == "pack_tear" or name == "loot" then
		s.PlaybackSpeed = 0.88 + math.random() * 0.22
	elseif name == "click" then
		--[[
			Widened from 0.94-1.04. `click` is a SINGLE 0.12s sample and the
			most-played sound in the game by a wide margin, so it is the one
			that cannot lean on variants the way the eight-sample pickaxe bag
			does -- drift is all it has. At +/-9% a short tick reads as a
			different press rather than a detuned one.
		]]
		s.PlaybackSpeed = 0.91 + math.random() * 0.18
	elseif name == "deny" then
		-- Down an octave-ish and dead short: a knock, not a buzzer.
		s.PlaybackSpeed = 0.55 + math.random() * 0.06
	end
	-- The button already ticked; a second full click on top reads as a stutter.
	if name == "equip" and lastAt.click and (now - lastAt.click) < 0.15 then
		s.Volume *= 0.5
	end
	if DUCK[name] then
		MineAudio.duck(DUCK[name])
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
	local fat = math.clamp(((tonumber(coins) or 0) + (tonumber(gems) or 0) * 8) / 5000, 0.9, 1.1)
	MineAudio.play("sell", fat)
	task.delay(0.08, function()
		MineAudio.play("shop", 0.7 * fat, nil, nil, true)
	end)
end

function MineAudio.playFound(oneIn)
	local n = tonumber(oneIn) or 50
	if n >= 1000 then
		MineAudio.play("rare", 1.05)
		MineAudio.play("reveal", 0.6, 1.12, nil, true)
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
	-- One warm chime per tier, no strobe-and-siren stacking: a win should feel
	-- nice, not like a slot machine paying out.
	if rank >= 6 then
		MineAudio.play("jackpot", 1)
		MineAudio.play("pack_sparkle", 0.6, nil, nil, true)
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
		MineAudio.play("jackpot", 1, nil, nil, true)
		MineAudio.play("pack_sparkle", 0.7, 1.1, nil, true)
	elseif band == "CHASE" then
		MineAudio.play("rare", 0.95, nil, nil, true)
		MineAudio.play("pack_sparkle", 0.5, nil, nil, true)
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
			local plr = Players.LocalPlayer
			local root = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local pos = root and root.Position
			if pos then
				musicMood = (pos.Y < MineAudio.MINE_Y and not (atSurface and atSurface(pos))) and "calm" or "bright"
			end
			if not want then
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

-- Shuffled without an immediate repeat; the mood is read fresh for each track
-- so going underground changes the next song rather than cutting this one.
local lastTrack
local function nextTrack()
	local list = MineAudio.MUSIC[musicMood] or MineAudio.MUSIC.bright
	if not list or #list == 0 then
		return nil
	end
	local id = list[math.random(1, #list)]
	if id == lastTrack and #list > 1 then
		id = list[(table.find(list, id) % #list) + 1]
	end
	lastTrack = id
	return id
end

function MineAudio.startBgm()
	groups()
	MineAudio.startAmbience()
	if bgmSound then
		return
	end
	local s = Instance.new("Sound")
	s.Name = "MineBgm"
	s.Looped = false
	s.Volume = 0
	s.SoundGroup = musicGroup
	s.Parent = SoundService
	bgmSound = s
	task.spawn(function()
		-- Let the world load and the player settle before the first note.
		task.wait(4)
		while s.Parent do
			local id = nextTrack() or (validId(MineAudio.IDS.bgm) and MineAudio.IDS.bgm)
			if not id then
				return
			end
			s.SoundId = id
			s.TimePosition = 0
			s.Volume = 0
			s:SetAttribute("Live", true)
			s:Play()
			TweenService:Create(s, TweenInfo.new(5, Enum.EasingStyle.Sine), { Volume = MineAudio.BGM_VOL }):Play()
			local t0 = os.clock()
			while s.Parent and not s.IsLoaded and os.clock() - t0 < 10 do
				task.wait(0.25)
			end
			local len = s.TimeLength > 1 and s.TimeLength or 120
			-- Fade the tail rather than letting a track stop dead.
			while s.Parent and s.IsPlaying and s.TimePosition < len - 4 do
				task.wait(0.5)
			end
			s:SetAttribute("Live", false)
			TweenService:Create(s, TweenInfo.new(3.5, Enum.EasingStyle.Sine), { Volume = 0 }):Play()
			task.wait(3.6)
			s:Stop()
			local gap = MineAudio.MUSIC_GAP
			task.wait(gap[1] + math.random() * (gap[2] - gap[1]))
		end
	end)
end

return MineAudio
