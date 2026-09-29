// Put back the tab that was never there, and give the ore tools a bench.
//
// TWO MISSING OPTIONS.
//
// 1. SECRETS. FAMILY_TINT has a `secrets` colour, rows() has a secrets branch,
//    paint() has a secrets branch, statusOf and the tab-count logic both special-
//    case it -- and TABS has no secrets entry, in any commit in the history. The
//    whole tab was wired and never given a button, so the forever tools could
//    not be browsed at all.
//
// 2. UPGRADE. upgradeOreTool and recycleOreTool have been on the server for a
//    while, both uid-keyed, and MineBenchView draws the list. Nothing ever
//    mounted it. The blacksmith is where a tool gets levelled, so it belongs
//    here as a tab rather than as a fourth building.
const fs = require("fs"), path = require("path");
const ROOT = path.join(__dirname, "..");
const F = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineShopView.luau");
const C = path.join(ROOT, "src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");

function load(p) {
  const raw = fs.readFileSync(p, "utf8");
  return { raw, crlf: raw.indexOf("\r\n") >= 0, s: raw.split("\r\n").join("\n") };
}
function makeOne(box) {
  return function one(old, nw) {
    const n = box.s.split(old).length - 1;
    if (n !== 1) throw new Error("expected 1 match, got " + n + " for: " + old.slice(0, 70));
    box.s = box.s.replace(old, nw);
  };
}

// ============================================================ MineShopView
const V = load(F);
const one = makeOne(V);

// ---- 1. the two missing tabs -------------------------------------------------
one(`	{ id = "backpack", label = "Backpacks", blurb = "Haul capacity. Coins for most rungs; the top pack is Robux." },
}`,
`	{ id = "backpack", label = "Backpacks", blurb = "Haul capacity. Coins for most rungs; the top pack is Robux." },
	--[[
		Secrets was wired everywhere and never given a button.

		FAMILY_TINT carries a secrets colour, rows() returns secretRankList() for
		it, paint() branches on it and the tab counter prints "have/total" for
		it -- but no commit in this file's history ever put it in TABS, so the
		forever tools could not be reached from the shop at all.
	]]
	{ id = "secrets", label = "Secrets", blurb = "Forever tools. Pulled from chests, never sold on a shelf." },
	{ id = "bench", label = "Upgrade", blurb = "Level the ore tools you found. Paid in their own ore, plus stardust." },
}`);

// Six tabs at 168 each overflow a phone; trim the width so the row still fits.
one(`			Name = "Tab_" .. tab.id, Size = UDim2.fromOffset(168, 44),`,
`			-- 168 -> 150: six tabs at the old width are 1058px before the
			-- UIScale a phone applies, which runs the row off both edges.
			Name = "Tab_" .. tab.id, Size = UDim2.fromOffset(150, 44),`);

// ---- 2. the bench panel ------------------------------------------------------
one(`	----------------------------------------------------------------------------
	-- TEMPERAMENT`,
`	----------------------------------------------------------------------------
	-- THE BENCH
	--
	-- MineBenchView already draws one row per ore tool with its next-level cost,
	-- what you are holding against that cost, and +1 / +10 / MAX / SCRAP. It was
	-- never mounted anywhere, so none of it could be reached. It hangs off the
	-- shop root at 86 -- above the stage, below the header -- and only the
	-- Upgrade tab shows it.
	--
	-- Required through pcall: if the module is missing from a build, the tab
	-- goes quiet instead of taking the whole shop down with it.
	----------------------------------------------------------------------------
	local okBench, Bench = pcall(function()
		return require(shared:WaitForChild("MineBenchView", 5))
	end)
	local benchPanel, benchCtl
	if okBench and Bench and Bench.mount then
		benchPanel = mk("Frame", {
			Name = "BenchPanel",
			Visible = false,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 156),
			Size = UDim2.new(0.86, 0, 1, -236),
			BackgroundTransparency = 1,
			ZIndex = 86,
		}, root)
		local okMount, ctl = pcall(Bench.mount, benchPanel, {
			-- The bench reads the same state the rest of the shop does, so a
			-- price it quotes cannot drift from the wallet shown above it.
			getSnap = function()
				return {
					oreTools = state.oreTools or {},
					ores = state.ores or {},
					dust = state.dust or 0,
				}
			end,
			onUpgrade = function(uid, n)
				if opts.onUpgradeOreTool then
					opts.onUpgradeOreTool(uid, n)
				end
			end,
			onRecycle = function(uid)
				if opts.onRecycleOreTool then
					opts.onRecycleOreTool(uid)
				end
			end,
		})
		benchCtl = okMount and ctl or nil
	end

	----------------------------------------------------------------------------
	-- TEMPERAMENT`);

// ---- 3. rows() has nothing to carousel on the bench --------------------------
one(`	function rows()
		if activeTab == "backpack" then`,
`	function rows()
		-- The bench is a list, not a shelf: no rungs to step through.
		if activeTab == "bench" then
			return {}
		end
		if activeTab == "backpack" then`);

// ---- 4. paint() switches the whole stage off for the bench -------------------
one(`		local isSecrets = activeTab == "secrets"
		creditsStage.Visible = false
		card.Visible = true`,
`		--[[
			The bench replaces the stage rather than sitting beside it.

			Everything the carousel owns -- the card, both arrows, the counter,
			the track, the temperament bar and the 3D preview itself -- is about
			ONE tool you are choosing between rungs. The bench is a list of tools
			you already own, so leaving the pedestal running behind it would show
			a tool that has nothing to do with the rows.
		]]
		if activeTab == "bench" then
			creditsStage.Visible = false
			card.Visible = false
			leftBtn.Visible = false
			rightBtn.Visible = false
			counter.Visible = false
			track.Visible = false
			temperBar.Visible = false
			vp.Visible = false
			if benchPanel then
				benchPanel.Visible = true
			end
			if benchCtl and benchCtl.refresh then
				pcall(benchCtl.refresh)
			end
			return
		end
		if benchPanel then
			benchPanel.Visible = false
		end
		vp.Visible = true

		local isSecrets = activeTab == "secrets"
		creditsStage.Visible = false
		card.Visible = true`);

// ---- 5. the tab counter for the bench ----------------------------------------
one(`			if id == "secrets" then
				local have = 0`,
`			if id == "bench" then
				-- How many tools there are to work on, not a have/total: every
				-- ore tool you own is levellable, so a denominator is noise.
				t.count.Text = tostring(#(state.oreTools or {}))
			elseif id == "secrets" then
				local have = 0`);

// ---- 6. the state the bench reads --------------------------------------------
one(`		state.tools = snapshot.tools or {}`,
`		state.tools = snapshot.tools or {}
		-- Banked ore and the ore tools themselves: the bench prices every row
		-- against these two.
		state.ores = snapshot.ores or {}
		state.oreTools = snapshot.oreTools or {}`);

one(`	local state = { coins = 0, gems = 0, credits = 0, dust = 0, tokens = 0,`,
`	local state = { coins = 0, gems = 0, credits = 0, dust = 0, tokens = 0, ores = {}, oreTools = {},`);

fs.writeFileSync(F, V.crlf ? V.s.split("\n").join("\r\n") : V.s);

// ============================================================ MineClient
const K = load(C);
const oneC = makeOne(K);

oneC(`	onBuyScroll = function(id, bundle)
		net:FireServer("buyScroll", { id = id, bundle = bundle and true or nil })
	end,
})`,
`	onBuyScroll = function(id, bundle)
		net:FireServer("buyScroll", { id = id, bundle = bundle and true or nil })
	end,
	--[[
		The blacksmith bench.

		Both verbs take a UID, never a row index: the list reorders whenever a
		tool is found or scrapped, and an index captured when the panel was drawn
		names a different tool by the time the button is pressed. Levels are a
		count, and the server clamps it to what is left below the cap.
	]]
	onUpgradeOreTool = function(uid, count)
		net:FireServer("upgradeOreTool", { uid = uid, count = count })
	end,
	onRecycleOreTool = function(uid)
		net:FireServer("recycleOreTool", { uid = uid })
	end,
})`);

fs.writeFileSync(C, K.crlf ? K.s.split("\n").join("\r\n") : K.s);
console.log("secrets + upgrade tabs added; bench mounted and wired to the server verbs");
