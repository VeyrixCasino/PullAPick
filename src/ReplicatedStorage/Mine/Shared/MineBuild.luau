--[[
	MineBuild: which build of src/ is this Studio actually running?

	Written after the second "there is still no Forge". Both times the Forge was
	in the repo and had been for days; both times Studio was running a copy of
	ReplicatedStorage from before the Forge existed, because the clone Rojo
	serves had not been pulled. Nothing on screen said so. The shop simply had
	one fewer tab, which reads exactly like a Forge that was never written.

	The receipt that settled it was a string: the on-screen tab blurb was the
	one from 2026-09-28, deleted in the commit that put the Forge on the front
	line. Nobody should have to go string-hunting through git to answer "is this
	Studio running my code".

	So this module answers it out loud, two ways:

	  STAMP   a label bumped when src/ ships. Compare it to the one in the repo.
	          It can go stale -- it is a string somebody maintains -- so it is
	          the hint, never the proof.

	  EXPECT  the modules this build knows it needs. This CANNOT go stale in a
	          way that lies: it is checked against the live DataModel, so a
	          Studio missing MineForge says MISSING MineForge, whatever the
	          stamp claims. A build older than src/ is missing src/'s newest
	          modules, which is the whole tell.

	announce() prints one line either way, so the output window answers the
	question on every Play without anybody asking it.
]]
local MineBuild = {}

--[[
	Bump this when src/ ships. Date it, and name the headline of the change --
	the point is that a human can eyeball it against the repo, not that it
	parses. It is a hint: EXPECT below is what actually proves anything.
]]
MineBuild.STAMP = "2026-10-04 traits + centred pets"

--[[
	Modules this build requires to be in ReplicatedStorage.Mine.Shared, with the
	thing the player loses when one is absent. Keep the reason in player terms:
	"no Forge tab" is a bug report, "MineForge nil" is a shrug.

	Only modules whose absence is VISIBLE belong here. A list of all eighty is a
	list nobody reads.
]]
MineBuild.EXPECT = {
	{ name = "MineForge", lost = "the Forge tab -- no crafting or levelling ore tools" },
	{ name = "MineOrePouchView", lost = "the Ore Pouch tab -- no selling ore" },
	{ name = "MineOreTools", lost = "the Forge -- tool names, frames and craft prices" },
	{ name = "MineTraitView", lost = "the Enchanter's Traits tab -- traits are unreachable" },
	{ name = "MineTraits", lost = "traits -- tools lose their prefix and their boost" },
	{ name = "MineBoostLayers", lost = "layered boosts -- every multiplier collapses into one pile" },
	{ name = "MineScrapSelect", lost = "multi-select scrapping" },
	{ name = "MineForgeView", lost = "the Enchanter's temper and socket panes" },
	{ name = "MineCharms", lost = "charms -- every charm row reads as empty" },
	{ name = "MineAbbrev", lost = "four-figure currency; numbers read wrong" },
}

--[[
	What is missing, as a list. Separated from the printing so a panel can ask
	the same question without writing to the output window.

	FindFirstChild, never WaitForChild: this runs to report on a tree that has
	already loaded, and a five-second stall per missing module would turn a
	diagnostic into a hang.
]]
function MineBuild.missing(shared)
	local out = {}
	if not shared then
		return out
	end
	for _, row in ipairs(MineBuild.EXPECT) do
		if not shared:FindFirstChild(row.name) then
			out[#out + 1] = row
		end
	end
	return out
end

--[[
	Say it once, on start.

	A clean build gets one quiet line. A stale one gets a warn naming every
	missing module, what the player loses, and the actual fix -- because the fix
	has never once been in the code: it is `git pull` in the clone `rojo serve`
	is running out of.
]]
function MineBuild.announce(shared)
	if MineBuild._said then
		return
	end
	MineBuild._said = true

	local gone = MineBuild.missing(shared)
	if #gone == 0 then
		print("[MineBuild] src stamp " .. MineBuild.STAMP .. " -- all expected panels present")
		return MineBuild.STAMP, gone
	end

	local lines = {}
	for _, row in ipairs(gone) do
		lines[#lines + 1] = "  MISSING  " .. row.name .. "  ->  " .. row.lost
	end
	warn("[MineBuild] THIS STUDIO IS RUNNING OLDER CODE THAN src/.\n"
		.. "  It claims stamp " .. MineBuild.STAMP .. ", but "
		.. #gone .. " module(s) that build needs are not in "
		.. "ReplicatedStorage.Mine.Shared:\n"
		.. table.concat(lines, "\n")
		.. "\n  Fix it in the clone `rojo serve` is running out of, not here:\n"
		.. "    git pull, then reconnect the Rojo plugin and Play again.\n"
		.. "  (Rojo uses $ignoreUnknownInstances, so a disconnected Studio keeps\n"
		.. "   serving whatever scripts were last written into the place.)")
	return MineBuild.STAMP, gone
end

return MineBuild
