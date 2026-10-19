--[[
	MineOreTools: a forged tool IS its ore.

	Owner, 2026-10-03, on seeing the Forge for the first time:

	  "everything in forge should be called {ore} {tool}"
	  "i want crafting to be sorted by the actual ore"
	  "i dont want different tools to cost different ores. If i want to upgrade
	   my stone pick, it should cost stone, at an increasing amount each time."

	The data model was already most of the way there and the PANEL was the liar.
	A forged row is { uid, typeId, familyId, tier, level } and `tier` is the
	ORE's tier -- the server sets `tier = oreDef.tier` on craft, and upgrading
	charges `C.ORES[tool.tier]`, the tool's own ore, growing by TOOL_ORE_GROW
	each level. That part was right.

	What was wrong: the Forge listed TOOL TYPES down its rail, under the coin
	shop's invented names -- "Chipped Crown", "Widow's Notch", "Brightfracture"
	-- and then asked you to pick any ore at all to forge one out of. So the
	thing you selected had no ore in its name, and the same name could be made
	of forty different ores at forty different prices. Hence "none of this makes
	sense".

	This module makes the ore the identity and the frame a consequence:

	  name        {Ore} {Noun}  --  "Stone Pickaxe", "Clay Drill"
	  frame       derived from the ore's tier, never chosen
	  cost        that ore, and only that ore

	THE FRAME IS DERIVED, NOT PICKED. 82 ore tiers are mapped proportionally
	onto a family's priced rungs, the same way ToolModelFactory.oreLook spreads
	silhouette across the roster. Deterministic and pure, so the panel quoting a
	price and the verb charging it reach the same answer without passing a
	typeId between them -- which also means a modified client cannot ask for a
	deep ore in a cheap frame.

	The free starter is excluded: `wood_pick` is priced 0 because it is GIVEN,
	and the craft verb refuses it by id. Filtering on `price > 0` keeps it, and
	anything else unpriced, out of the pool by construction rather than by a
	second list that can drift.
]]
local MineOreTools = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local Tools = require(shared:WaitForChild("MineTools"))
-- The trait prefix. Loaded here so every caller that names a tool
-- gets the prefix for free rather than remembering to add it.

-- What one of these is called. Singular, because it names one tool.
MineOreTools.NOUN = {
	pickaxe = "Pickaxe",
	hammer = "Hammer",
	drill = "Drill",
	jackhammer = "Jackhammer",
	explosive = "Explosive",
	weapon = "Weapon",
}

-- The families a player can actually forge in, in rail order.
-- Hammer sits next to the pickaxe: both are single-target melee, and a player
-- choosing between "chip fast" and "hit hard" should see them side by side.
-- Jackhammer sits next to the drill for the same reason: both clear area, and
-- the choice between them is "aim anywhere" against "straight down, faster".
MineOreTools.FAMILY_ORDER = { "pickaxe", "hammer", "drill", "jackhammer", "explosive" }

function MineOreTools.familyNoun(familyId)
	local id = tostring(familyId or "pickaxe")
	return MineOreTools.NOUN[id] or (id:sub(1, 1):upper() .. id:sub(2))
end

--[[
	The forgeable frames of a family, cheapest rung first.

	Cached per family: this is read once per rail row per redraw, and the rail
	redraws on every snapshot.
]]
local frameCache = {}
function MineOreTools.frames(familyId)
	local id = tostring(familyId or "pickaxe")
	if frameCache[id] then
		return frameCache[id]
	end
	local out = {}
	for _, td in ipairs((Tools.TOOLS or {})[id] or {}) do
		-- Priced rungs only. price == 0 is the given starter; no price at all
		-- is a chest flagship, which is found and never forged.
		if (tonumber(td.price) or 0) > 0 then
			out[#out + 1] = td
		end
	end
	table.sort(out, function(a, b)
		return (tonumber(a.tier) or 0) < (tonumber(b.tier) or 0)
	end)
	frameCache[id] = out
	return out
end

--[[
	Which frame an ore of this tier wears.

	Proportional, not nearest: there are 82 ore tiers and ~24 rungs, so
	"nearest" would park every ore past tier 24 on the top rung and make the
	whole back half of the roster look identical. Spreading them keeps the
	silhouette moving all the way down, which is the same choice oreLook makes.
]]
function MineOreTools.frameForTier(familyId, oreTier)
	local defs = MineOreTools.frames(familyId)
	local n = #defs
	if n == 0 then
		return nil
	end
	local span = math.max(1, (tonumber(C.ORE_COUNT) or 82) - 1)
	local t = math.clamp((math.floor(tonumber(oreTier) or 1) - 1) / span, 0, 1)
	local idx = math.clamp(math.floor(t * (n - 1) + 0.5) + 1, 1, n)
	return defs[idx]
end

-- The frame a forged row is wearing. Reads the row's stored typeId when it has
-- one -- rows forged before the frame was derived keep theirs -- and otherwise
-- derives it, so an old save never draws a blank.
function MineOreTools.frameOf(tool)
	if type(tool) ~= "table" then
		return nil
	end
	local fam = tostring(tool.familyId or "pickaxe")
	if tool.typeId then
		for _, td in ipairs((Tools.TOOLS or {})[fam] or {}) do
			if td.id == tool.typeId then
				return td
			end
		end
	end
	return MineOreTools.frameForTier(fam, tool.tier)
end

--[[
	THE COST MULTIPLIER, AS A FUNCTION OF THE ORE AND NOTHING ELSE.

	Owner, 2026-10-06: "delete all tools in the game besides for chest
	tools... and ore tools". The priced roster is gone, and this used to read
	it: it found the frame an ore wore, took that frame's rarity, and returned
	its rank.

	But frameForTier is deterministic in ore tier, so this was ALREADY a pure
	function of tier -- it just reached through a table to compute it. Measured
	across all 82 tiers before the roster was removed, it is a clean step
	function, and the steps are baked here exactly as they were:

	    pickaxe   1-6=1 7-16=2 17-27=3 28-37=4 38-48=5 49-59=6 60-69=7 70-82=8
	    drill     1-9=1 10-19=2 20-30=3 31-41=4 42-52=5 53-63=6 64-73=7 74-82=8
	    explosive (same as drill)

	They differ because a family's rungs were spread across the roster and the
	families had different rung counts -- 24 for pickaxes, 16 for the others.

	WHY NOT THE ORE'S RARITY BAND, which was the obvious replacement: measured,
	it drops the roster mean from 4.80 to 3.38 and cuts some tiers to a third,
	with nothing going up. That is a 30% cut to forge costs nobody asked for.
	Baking the real curve removes the dependency and changes no number at all.
]]
--[[
	PER-FAMILY DAMAGE, which the game had no way to express until now.

	Owner, 2026-10-10: "Hammers most damage".
	Owner, 2026-10-14 (B1 LOCKED): hammer niche = slow / heavy / single-target
	AND the highest single-block DPS of every family (hardest hit + best
	sustained DPS on one block). Not merely ≈ pickaxe.

	`C.toolPower(tier, level, typeMult)` has no family argument, and typeMult
	is the only family-dependent input -- so with the pickaxe's rung spacing a
	hammer came out at IDENTICAL damage per hit and HALF the swing rate, which
	is not a damage class, it is a worse pickaxe.

	Raising it through typeMult instead was the other option and it is the
	wrong one: typeMult also drives craft COST, so a hammer would have become
	expensive rather than hard-hitting, and the two knobs would be welded
	together forever.

	DECISION 2026-10-14 (was PROPOSED 2.2 for pickaxe parity): hammer = 3.7.
	Pickaxe parity only needs ~2.2 against the ~0.46 rate ratio, but drills
	peak at rate 4 while hammers sit near 1.1–1.2, so single-block DPS crown
	vs drill needs about 3.64 at the worst tier. 3.7 clears that with a small
	margin. tools/verify/tool-dps.js asserts hammer.dps >= every other family
	at the sample tiers.

	What a player feels: the hammer hits hardest per blow AND wins sustained
	DPS on a single block, paid for by being the slowest melee and only
	sinking two cells down (still single-target across). Block HP is a
	threshold, so the overkill trade vs a fast pick on chip-work remains real.
]]
MineOreTools.FAMILY_POWER = {
	pickaxe = 1,
	hammer = 3.7,
	drill = 1,
	--[[
		SAME DPS AS A DRILL, PAID FOR BY BEING FASTER.

		Owner, 2026-10-10: a jackhammer goes faster than a drill but lands on
		the same DPS, because it can only dig DOWN. FRAME_STATS gives it 1.5x
		the drill's swing rate, so its per-hit power has to come down by the
		same 1.5 or the extra speed would be free damage. 1 / 1.5 = 0.667.

		Keep this and the rate multiplier in step: they exist to cancel.
	]]
	jackhammer = 1 / 1.5,
	--[[
		DECISION 2026-10-14 (B2, was 1): explosive = 4.

		TODO B2: same-grade explosive *area* edps (full blast footprint) tops
		every other family; higher-grade tools may still beat a low explosive.
		Raising FAMILY_POWER alone to ~7 would also inflate single-cell dps and
		force the hammer crown higher — prefer a modest power floor here plus
		FRAME_STATS coverage / cooldown on the mid bands (below). Asserted by
		tools/verify/tool-dps.js.
	]]
	explosive = 4,
}

function MineOreTools.familyPower(familyId)
	return MineOreTools.FAMILY_POWER[tostring(familyId or "pickaxe")] or 1
end

MineOreTools.TYPE_MULT_STEPS = {
	pickaxe = { 6, 16, 27, 37, 48, 59, 69, 82 },
	drill = { 9, 19, 30, 41, 52, 63, 73, 82 },
	explosive = { 9, 19, 30, 41, 52, 63, 73, 82 },
	-- Hammers sit on the pickaxe's rung spacing: both are single-target melee,
	-- so a hammer and a pick of the same ore should cost the same to forge.
	-- (The hammer's EXTRA ore cost is MineConfig.FAMILY_CRAFT_COST, which is
	-- cost-only; typeMult here would move power too.)
	hammer = { 6, 16, 27, 37, 48, 59, 69, 82 },
	-- Jackhammers are drills that only point down, so they share the drill's
	-- rungs exactly.
	jackhammer = { 9, 19, 30, 41, 52, 63, 73, 82 },
}

--[[
	THE FRAME'S STATS, BAKED THE SAME WAY AND FOR THE SAME REASON.

	A frame carried far more than a cost multiplier: equippedTool read `rate`,
	`radius`, `cells`, `shape`, `width`, `axis`, `turn` and -- for explosives --
	`bombs`, `pattern` and `cooldown` straight off it. Delete the roster without
	these and every forged DRILL and EXPLOSIVE falls to the defaults, which are
	rate 2.6, cells 1, radius 0, shape "melee": a single-block melee pickaxe.
	The area clear and the blast would be gone, silently, with nothing erroring.

	Like typeMult, these were already pure functions of ore tier, because
	frameForTier is. They are run-length encoded as {upTo, value} and were
	EMITTED from the live roster rather than typed out, so nothing is a
	transcription. tools/verify/oreframes.js re-derives them and fails on any
	difference.

	Pickaxes barely vary -- always melee, one cell, only the swing rate moves.
	Drills and explosives are where the real shape is: a drill's cells go
	1 -> 9 -> 4 -> 1 -> 4 -> 1 -> 9 across the roster and its axis flips between
	`down` and `aim` four times, which is exactly the sort of detail that would
	not survive being re-invented by hand.
]]
MineOreTools.FRAME_STATS = {
	pickaxe = {
		rate = {
			{2,3}, {6,2.7}, {9,2.5}, {13,2.6}, {16,2.4}, {20,2.5},
			{23,2.3}, {27,2.6}, {30,2.4}, {34,2.7}, {37,2.5}, {41,2.8},
			{45,2.6}, {48,2.9}, {52,2.7}, {55,2.5}, {59,3}, {62,2.8},
			{66,3.1}, {69,2.9}, {73,3.2}, {76,3}, {80,3.1}, {82,3.2},
		},
		cells = { {82,1} },
		radius = { {82,0} },
		shape = { {82,"melee"} },
		width = { {82,false} },
		axis = { {82,false} },
		turn = { {82,false} },
		bombs = { {82,false} },
		pattern = { {82,false} },
		cooldown = { {82,false} },
	},
	--[[
		HAMMERS -- slow / heavy / single-target, hardest hit + best single-block DPS.

		Owner, 2026-10-10: "make another class (Hammers most damage; looks
		like sledge hammers)".
		Owner, 2026-10-14 B1 LOCKED: also highest sustained DPS on one block
		(FAMILY_POWER.hammer = 3.7). Pick stays faster; hammer stays single-
		target across (sink 2 is depth only).

		A hammer swings at roughly HALF a pickaxe's rate (1.1 to 1.6 against
		2.3 to 3.2). The rate curve rises a little across the roster so a deep
		hammer is not literally unplayable to hold.
	]]
	hammer = {
		rate = {
			{6,1.1}, {16,1.15}, {27,1.2}, {37,1.25}, {48,1.3},
			{59,1.4}, {69,1.5}, {82,1.6},
		},
		-- `cells` is what the SHOP quotes. A hammer touches two: the aimed
		-- block and the one under it, so this and `sink` have to move together
		-- or the shop is lying (MinePatterns' header says exactly that).
		cells = { {82,2} },
		radius = { {82,0} },
		shape = { {82,"melee"} },
		width = { {82,false} },
		axis = { {82,false} },
		turn = { {82,false} },
		bombs = { {82,false} },
		pattern = { {82,false} },
		cooldown = { {82,false} },
		-- Owner, 2026-10-10: hammers break 2 blocks down at a time. Depth only;
		-- still single-target across, which is what keeps it a hammer.
		sink = { {82,2} },
	},
	drill = {
		rate = {
			{3,2.6}, {14,4}, {19,3.5}, {30,4}, {57,2.5}, {63,3},
			{68,3.5}, {73,3}, {79,4}, {82,2.2},
		},
		cells = {
			{30,1}, {57,9}, {63,4}, {68,1}, {73,4}, {79,1},
			{82,9},
		},
		radius = { {82,0} },
		--[[
			NO MORE DOWN DRILLS. Owner, 2026-10-10: drills mine everywhere, and
			digging straight down is the jackhammer's job now.

			shape and axis both used to flip between down and dir/aim four times
			across the roster, so whether your drill could aim depended on which
			ore it was made of -- buy the next rung up and lose the ability. They
			are now "dir"/"aim" the whole way, which is the "mine everywhere"
			asked for and also removes that trap.
		]]
		shape = { {82,"dir"} },
		width = {
			{30,1}, {57,3}, {63,2}, {68,1}, {73,2}, {79,1},
			{82,3},
		},
		axis = { {82,"aim"} },
		-- Instant (owner, 2026-10-16: "drill is isntant"); the jackhammer is the
		-- one that spins up.
		turn = { {82,0} },
		bombs = { {82,false} },
		pattern = { {82,false} },
		cooldown = { {82,false} },
	},
	--[[
		THE JACKHAMMER. A drill that only points down, and is faster for it.

		Owner, 2026-10-10: like a drill except AUTO, a 3 second wind, straight
		down only, faster than a drill but the same DPS.

		rate is the drill's x1.5 and FAMILY_POWER.jackhammer is 1/1.5, so the
		two cancel and the DPS lands on the drill's. The speed buys you nothing
		but feel -- what you actually trade for is the ability to aim.

		`auto` and `windSec` are read by the swing path; they are not part of
		the old frame contract, which is why they are named here rather than
		left implied.
	]]
	jackhammer = {
		rate = {
			{3,3.9}, {14,6}, {19,5.25}, {30,6}, {57,3.75}, {63,4.5},
			{68,5.25}, {73,4.5}, {79,6}, {82,3.3},
		},
		cells = {
			{30,1}, {57,9}, {63,4}, {68,1}, {73,4}, {79,1},
			{82,9},
		},
		radius = { {82,0} },
		-- Down, always. This is the whole identity of the family.
		shape = { {82,"down"} },
		width = {
			{30,1}, {57,3}, {63,2}, {68,1}, {73,2}, {79,1},
			{82,3},
		},
		axis = { {82,"down"} },
		turn = { {3,1.4}, {82,1.2} },
		bombs = { {82,false} },
		pattern = { {82,false} },
		cooldown = { {82,false} },
		-- Holds to dig rather than swinging per click.
		auto = { {82,true} },
		-- Three seconds to spin up before the first block gives.
		windSec = { {82,3} },
	},
	--[[
		EXPLOSIVES — area king (TODO B2 / owner 2026-10-14).

		edps is hit × (blocks per bomb) × bombs × (1/cooldown). blocks per bomb
		is `cells` for sphere/cluster/splash, and `depth` for line (MinePatterns
		line() reads tool.depth; without it live coverage was 1 while the shop
		quoted 7+). Bake depth with the line cells so the quote matches the blast.

		DECISION 2026-10-14 retune (was roster bake):
		- FAMILY_POWER.explosive 1 → 4 (see above).
		- line 42–46 cells/depth 7 → 13; line 53–57 cells/depth 9 → 13 so
		  long-range frames clear same-grade drill 3×3 edps.
		- mid sphere cooldown {36,1.75}/{41,1.9} → {36,1.15}/{41,1.2} so
		  radius-1 spheres keep honest geometry while still topping edps
		  against area drills (raising radius would jump cells 7→33).
	]]
	explosive = {
		rate = { {82,1} },
		cells = {
			{41,7}, {46,13}, {52,33}, {57,13}, {63,11}, {82,33},
		},
		radius = {
			{41,1}, {46,0}, {52,2}, {63,0}, {82,2},
		},
		shape = { {82,false} },
		width = { {82,false} },
		axis = { {82,false} },
		turn = { {82,false} },
		bombs = {
			{25,1}, {30,3}, {46,1}, {52,3}, {68,1}, {82,3},
		},
		pattern = {
			{25,"sphere"}, {30,"cluster"}, {41,"sphere"}, {46,"line"}, {52,"cluster"}, {63,"line"},
			{68,"splash"}, {82,"cluster"},
		},
		-- Line length into the wall. Must match cells on line bands; false
		-- elsewhere (sphere/cluster/splash ignore depth).
		depth = {
			{41,false}, {46,13}, {52,false}, {57,13}, {63,11}, {82,false},
		},
		cooldown = {
			{3,2.05}, {9,1.15}, {14,1.25}, {19,1.4}, {25,1.6}, {30,1.95},
			{36,1.15}, {41,1.2}, {46,2.15}, {52,2.45}, {57,2.3}, {63,2.6},
			{68,2.75}, {73,3.15}, {79,3.65}, {82,4.25},
		},
	},
}

--[[
	`false` means the frame had NOTHING here, and that is not the same as 0.

	The first bake wrote a default in place of a missing key -- 0 for numbers,
	"" for strings -- and 738 of 2,460 values came back wrong against the
	roster. It matters because 0 is TRUTHY in Lua: a caller reading
	`typeDef.turn or 1.2` gets 1.2 from nil but 0 from a baked zero, so a
	pickaxe would have been handed a turn rate of zero instead of the default.

	And 0 is a real value elsewhere -- an explosive's radius is genuinely 0 at
	tiers 42-46 -- so "treat 0 as absent" would have been wrong in the other
	direction. A marker that cannot collide with any real value is the only
	thing that works.
]]
local function statValue(steps, tier)
	for _, pair in ipairs(steps) do
		if tier <= pair[1] then
			local v = pair[2]
			if v == false then
				return nil
			end
			return v
		end
	end
	return nil
end

--[[
	Every stat a forged tool of this family and ore tier carries.

	Returns a fresh table, because callers write finish multipliers onto what
	they get back and a shared one would leak between tools.
]]
function MineOreTools.frameStats(familyId, oreTier)
	local fam = MineOreTools.FRAME_STATS[tostring(familyId or "pickaxe")]
		or MineOreTools.FRAME_STATS.pickaxe
	local t = math.clamp(math.floor(tonumber(oreTier) or 1), 1, 82)
	local out = {}
	for key, steps in pairs(fam) do
		out[key] = statValue(steps, t)
	end
	return out
end

function MineOreTools.typeMult(familyId, oreTier)
	local steps = MineOreTools.TYPE_MULT_STEPS[tostring(familyId or "pickaxe")]
		or MineOreTools.TYPE_MULT_STEPS.pickaxe
	local t = math.max(1, math.floor(tonumber(oreTier) or 1))
	for i, upTo in ipairs(steps) do
		if t <= upTo then
			return i
		end
	end
	return #steps
end

-- The ore a forged row is made of. `tier` is the ore's tier and always has
-- been; this is the one place that turns it back into a row.
function MineOreTools.oreOf(tool)
	if type(tool) ~= "table" then
		return nil
	end
	return (C.ORES or {})[math.floor(tonumber(tool.tier) or 0)]
end

--[[
	"Stone Pickaxe", or "Sharp Stone Pickaxe" with an trait on it.

	The prefix is part of the name and not a decoration added by whichever
	screen remembered to: owner, 2026-10-04, "its a prefix too your tool
	(Sharp Stone Pickaxe, Lucky Stone Drill)". Every caller that names a tool
	goes through here, so there is nowhere for an unprefixed name to leak out.
]]
-- `_trait` is ignored: tool traits (the prefix) were retired on 2026-10-12,
-- when enchants took their field. Kept in the signature for old callers.
function MineOreTools.name(oreDef, familyId, _trait)
	local ore = (type(oreDef) == "table" and (oreDef.name or oreDef.id)) or "Unknown"
	return tostring(ore) .. " " .. MineOreTools.familyNoun(familyId)
end

-- The same, from a forged row.
function MineOreTools.toolName(tool)
	if type(tool) ~= "table" then
		return "Unknown Tool"
	end
	return MineOreTools.name(MineOreTools.oreOf(tool), tool.familyId)
end

--[[
	THE FORGE'S NUMBERS, ONE COPY EACH (launch audit 2026-10-19, S9-S11).

	Each of these used to be worked out twice -- once by the verb that charges
	or swings, once by the card that quotes it -- and every pair had drifted:

	  S9   the craft verb built typeMult with no ore tier (always step 1), the
	       card used the tier, so from ore tier 7 up the card and the charge
	       were different numbers;
	  S10  SCRAP quoted base level 1, the verb refunded from the tool's real
	       `base`, so the card promised ore the server never paid;
	  S11  the card's damage left out the family, the skin and the finish (a
	       Stone Hammer card said 10 and hit 37), and showed "Lv 1" for a craft
	       that arrives at your best level.

	Rule 3 of the build spec: a card uses the function the server uses. So the
	server's craftOreTool, recycleOreTool and equippedTool call these, and so
	does every Forge panel. Neither side may compute its own.
]]

-- What forging this family out of this ore costs, in that ore.
function MineOreTools.craftCost(familyId, oreTier)
	local fam = tostring(familyId or "pickaxe")
	return C.toolCraftCost(oreTier, MineOreTools.typeMult(fam, oreTier), fam)
end

--[[
	What scrapping a forged row pays back: ore, stardust. Only the levels the
	tool BOUGHT come back -- `base` is the level it was forged at (inherited
	levels cost nothing, MineConfig.toolRecycle). A row saved before `base`
	existed reads 1, the generous side.
]]
function MineOreTools.recycleRefund(tool)
	local fam = tostring(tool.familyId or "pickaxe")
	local level = math.max(1, tonumber(tool.level) or 1)
	local base = math.clamp(math.floor(tonumber(tool.base) or 1), 1, level)
	return C.toolRecycle(tool.tier, level, MineOreTools.typeMult(fam, tool.tier), base)
end

--[[
	The level a NEW forge arrives at: the best level on the rack, clamped to the
	cap. Forging carries your levelling (Verbs.craftOreTool explains why).
]]
function MineOreTools.inheritedLevel(oreTools)
	local best = 1
	for _, t in ipairs(type(oreTools) == "table" and oreTools or {}) do
		if type(t) == "table" then
			local lv = math.floor(tonumber(t.level) or 1)
			if lv > best then
				best = lv
			end
		end
	end
	return math.clamp(best, 1, tonumber(C.TOOL_MAX_LEVEL) or 30)
end

--[[
	WHAT ONE BLOW OF A FORGED TOOL HITS FOR.

	`row` is a forged row: { familyId, tier, level, shiny?, shadow?, nightmare? }.
	Ore tier and level through MineConfig.toolPower, times the family's
	FAMILY_POWER and the worn skin's base (`skinMult`, MineSkins.BASE; 1 for
	none), floored once -- then the finish. The highest finish wins outright;
	finishes never stack. This is the order equippedTool has always used, so no
	held tool's number moved when it was lifted out of the server.
]]
function MineOreTools.hitPower(row, skinMult)
	local fam = tostring(row.familyId or "pickaxe")
	local lvl = math.max(1, tonumber(row.level) or 1)
	local power = math.max(1, math.floor(C.toolPower(row.tier, lvl, MineOreTools.typeMult(fam, row.tier))
		* MineOreTools.familyPower(fam) * (tonumber(skinMult) or 1)))
	if row.nightmare then
		power = math.max(1, math.floor(power * (C.NIGHTMARE_MULT or 4.5)))
	elseif row.shadow then
		power = math.max(1, math.floor(power * (C.SHADOW_MULT or 3)))
	elseif row.shiny then
		power = math.max(1, math.floor(power * (C.SHINY_MULT or 1.5)))
	end
	return power
end

--[[
	WHAT A FORGE CARD PRINTS. Owner, 2026-10-19: cards show "true damage per hit,
	hits per second, area, use".

	Everything comes from what the server builds the held row out of --
	hitPower and frameStats -- so a card cannot describe a tool the hand does
	not hold. Boosts (pets, gear, enchants) are left out: they are the player's,
	not the tool's, and they move while the card is open.

	  hit     power per blow (hitPower)
	  perSec  blows a second: the frame's rate; a thrown explosive lands its
	          bombs once per cooldown
	  area    "1 block", "1 block, 2 deep", "3x3", "33 blocks", "3 x 13 blocks"
	  use     "swing", "hold", "hold, down only", "throw"
]]
function MineOreTools.cardStats(row, skinMult)
	local fam = tostring(row.familyId or "pickaxe")
	local s = MineOreTools.frameStats(fam, row.tier)
	local out = { hit = MineOreTools.hitPower(row, skinMult) }
	if s.cooldown then
		local bombs = math.max(1, math.floor(tonumber(s.bombs) or 1))
		-- A line blast runs `depth` into the wall; every other pattern is `cells`.
		local per = math.max(tonumber(s.cells) or 1, (s.pattern == "line" and tonumber(s.depth)) or 0)
		out.perSec = bombs / math.max(0.05, tonumber(s.cooldown) or 1)
		out.area = (bombs > 1) and string.format("%d x %d blocks", bombs, per) or string.format("%d blocks", per)
		out.use = "throw"
	else
		out.perSec = tonumber(s.rate) or 1
		local w = math.max(1, math.floor(tonumber(s.width) or 1))
		if w > 1 then
			out.area = string.format("%dx%d", w, w)
		elseif (tonumber(s.sink) or 1) > 1 then
			out.area = string.format("1 block, %d deep", s.sink)
		else
			out.area = "1 block"
		end
		if s.shape == "down" or s.axis == "down" then
			out.use = "hold, down only"
		elseif s.shape == "dir" or s.auto then
			out.use = "hold"
		else
			out.use = "swing"
		end
	end
	return out
end

return MineOreTools
