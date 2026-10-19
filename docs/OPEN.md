# OPEN — every unfinished task, one place

Generated 2026-10-05 from `docs/TODO.md` plus the decisions taken after it was
last rewritten. **89 open items in TODO.md §6, plus 11 from the final sessions.**

`docs/TODO.md` is still the authority — it carries the *reasoning* behind each
item, and §0 carries the locked rules. This file is the index: what is left, in
the order it matters. Each entry says where the detail lives.

**Read `docs/START-HERE.md` first if you have no context.**

> **2026-10-05 — every open NUMBER is now decided and signed off.**
> `docs/PROPOSAL.md` §0 is 38 approved lines covering boosts, craft, breaking,
> gems, coins, pity, sets and cleanup. Those are decisions, not suggestions, and
> the implementation order is at the top of that file. What remains open below
> is work, not choices — plus the three code bugs the proposal turned up.

---

# P0 — the game cannot launch without these

### 1. Seam purchase — CORRECTED 2026-10-05: wired, needs in-game confirmation
**This was wrongly recorded as an unwired ship blocker. It is wired end to end.**
The local agent caught it and the chain verifies:

| step | where |
|---|---|
| `swingBlock` refuses with `why == "need_seam"` | `MineServer.server.luau:6392` |
| server fires `seamGate` with seam, price, minutes, coins (throttled 1.5s) | `MineServer.server.luau:6406` |
| client routes it to `ClientFns.confirmSeam(payload)` | `MineClient.client.luau:10859` |
| panel is built and shown | `MineClient.client.luau:7415`–`7516` |
| buy button fires `buySeam` | `MineClient.client.luau:7489` |
| `Verbs.buySeam` handles it | `MineServer.server.luau:9266` |

So the task is **not** "write the missing call". It is **swing into locked rock at
layer 500 and confirm the panel appears, the price is right, and the purchase
lands.** That is a playthrough task, not a code task — it folds into item 2.

Why the error happened, so it is not repeated: the search was for callers of
`buySeam`, which found only the server. The client reaches it through the
`seamGate` event name, so a grep for one name missed the other half of the
round-trip. **When tracing a client/server chain here, grep the event names on
both sides, not just the verb.**

### 2. Play the branch
101 commits, essentially none of which have ever run in Roblox. The Forge
rewrite, the proc split, the two-layer boost system, the regenerated skill tree
and the whole traits system were written, statically verified, and pushed
**without the engine ever loading them once**. Exactly one change all session was
confirmed working in-game. Until someone plays it, every item below is built on
an unproven base.

### 3. Breaking power — RE-CUT 2026-10-05: the zone is the gate now
It lives in `MineBreaking.luau`: `LAYERS_PER_RUNG 50`, **`ZONE_STEP 100`**,
**`ORE_POW 1.0`**, **`MAX_LAYER 5000`**, **`MAX 1000`**. The reach table is in
`docs/PROPOSAL.md` §F0.

**What changed and why.** At `ZONE_STEP 1` the zone was not a gate at all:
measured at layer 2500, zone 1 demanded ore tier 41 and zone 11 demanded tier
44 — *three tiers for ×9.77 million HP*. It also ate the roster, since reaching
the bottom of zone 1 needed tier 57 of 82, leaving nine zones to share three
tiers. `MAX_LAYER` read 10000 while `MineConfig.LAYERS` exports 5000, so the
ladder pointed 100 rungs past anything reachable.

The ladder is continuous now — finishing a zone *is* entering the next, eight
tiers apiece, tier 82 landing exactly on zone 10's floor:

| zone | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| enter | t1 | t10 | t18 | t26 | t34 | t42 | t50 | t58 | t66 | t74 |
| finish | t9 | t18 | t26 | t34 | t42 | t50 | t58 | t66 | t74 | **t82** |

Event Horizon is off this ladder — it does not use ore tools.
- [x] ~~`ORE_REACH = 15` shown in the UI, never read by the gate.~~ **Wired
      2026-10-05.** `blockStrength` now asks `oreStrength` for the ore as if it
      sat `ORE_REACH` tiers lower; depth is untouched. The constant is
      duplicated into `MineBreaking` (that module has no requires by design) and
      `tools/verify/breaking.js` fails if the two ever drift apart.
- [x] **Reach split by zone progress, 2026-10-05** (owner: *"make the ore
      requirement elevated until they go to next zone"*). `ORE_REACH_HOME 5`
      in the zone you are working, `ORE_REACH 15` once you have unlocked past
      it; `MineBreaking.reachFor` picks, and the server passes
      `p.maxUnlockedZone`. The Forge now quotes the **home** number, so it
      under-promises rather than repeating the promise/gate mismatch.
      **Do not set the home reach to 0** — measured, it deadlocks progression
      at tier 4, and `breaking.js` asserts that.
- [x] **Block strength as a function of layer and zone, and nothing else.**
      `blockStrength` takes the *harder* of `layerStrength` and
      `oreStrength(tier − reach)`, never a sum. Dials re-cut above.
- [x] **Tool breaking power strictly a function of the ore.** Verified
      2026-10-05: `MineBreaking.toolBreakingPower` reads a stamped value first
      (so a forged tool never silently re-derives if the roster moves), then
      falls back to `oreStrength(oreTier)`. Level, damage, skins and runes do
      not reach it.
- [x] **Server-authoritative gate.** `MineServer.server.luau:6769` — `canBreak`
      is checked server-side and returns *before* any damage. Client may predict;
      the server decides.
- [x] **Red hotbar text, throttled.** Both halves confirmed, per this file's own
      rule about greping event names on both sides: server fires `tooWeak` with
      `need`/`have`/`ore` on a 1.2 s throttle, and `ClientFns.tooWeak`
      (`MineClient.client.luau:7350`) renders it in red (255, 96, 96).
- [x] **Procs no longer route around the gate.** `canBreak` had exactly ONE call
      site while TWO functions dealt damage — `swingNeighbour` predates the gate
      and never got it, so blast, zap, ricochet, earthquake and echo all chipped
      rock the tool could not scratch. Gated 2026-10-05 (owner: full rule, ore
      included). `tools/verify/gate-coverage.js` fails if a third damage path
      appears ungated.
- [x] **Re-derive the real ladder.** Done above — and the consequence this item
      asked about is now measured: `ORE_REACH 15` means a tier-67 tool reaches
      every ore in the game, so tiers 68–82 buy no new *access* and damage has to
      carry them. That is what `MineConfig.TOOL_BAND_DMG` is for.
- [ ] Document damage ≠ breaking power everywhere both appear.

### 4. Crafting transaction integrity
- [ ] Server owns crafting: ore debited and tool minted in **one** transaction.
      No client-supplied costs, no partial debits on failure.
- [ ] The crafting ore must set the tool's breaking power — blocked on item 3.
- [ ] Upgrades cost ore, a lot of it. Endgame tools are a real grind.
- [ ] Keep the uid-keyed contract of `upgradeOreTool` / `recycleOreTool`.

### 5. Economy removals — ore must not be purchasable
- [ ] Remove any path where gems buy better ore.
- [ ] Remove any path where ore buys or upgrades into better ore. No merging, no
      tier-up, no trade-up. *(A first grep found no such path — verify, don't
      trust the grep.)*
- [ ] Skin / temperament crates buyable with **ore only**.
- [ ] Hat crates must not increase on rebirth. Find and remove any rebirth-scaled
      hat-crate yield.

---

# P1 — launch quality

### 6. Underground outposts — DONE 2026-10-05
Each seam gets an outpost **1:1 with the surface one** — same shop, same sell —
underground-themed, deeper and darker at every seam. Owner's spec, 2026-10-04.

~~Needs Studio for the geometry.~~ **It never did.** The geometry was already
there and had been for a long time: `dressOutpostFromSurface` clones the surface
template down to the seam Y, so "1:1 with the surface one" is literally how every
outpost is built — `SurfaceClone` (56 parts), `sell_depth`, `shop_depth`,
`OutpostWalls`, sign, mineshaft, return pad, in all eleven zones. This entry read
as unstarted work for weeks because nobody looked in `Workspace.MineWorld.Pits`.

Three things were genuinely missing and are now done:

- [x] **Every 500, all the way down.** `SEAMS` widened to every 1000 past 3000;
      it is every 500 to the floor now (owner, 2026-10-05). **3500 and 4500 were
      not new geometry** — the ladder ran every 500 once before and the world
      still carried `DepthPlaza_<zone>_3500` / `_4500`, dressed and walled, for
      all eleven zones. Every loop in `MineDepthPlazas` iterates `SEAMS`, so when
      the ladder widened the builder stopped maintaining them, the elevator
      stopped giving them a floor, and no gate landed on them. Putting them back
      on the ladder **adopts** that geometry. `MineDepthShop.DESK_SEAM` never
      lost its `outpost_3500` / `outpost_4500` keys either. Ten per zone now.
- [x] **A reserved station bay behind each one** (owner: "extra space behind it
      for another station… high tier enchanters, pack recyclers"). `wallOutpost`
      grows the room by `BAY_DEPTH` along `zoneAxes`' `back` axis — the one wall
      the elevator is not using — and leaves a `StationBay` folder holding a deck
      and a RESERVED sign. One room, not an alcove behind a door: a walled-off
      annexe reads as a locked area a player should be trying to get into, and
      this is not content yet. Dropping a station in later means parenting into
      `StationBay`, with no change to `wallOutpost`.
- [x] **Deeper outposts look deeper.** They did not: seams 500, 2500 and 5000
      measured byte-identical — same eleven lights, same twenty-one neon parts,
      same wall colour — because every colour in the file was a constant.
      `depthLook(seam)` drives wall, deck, light brightness, range and tint off
      one clamped 0..1. Outpost 1 keeps its current look; 10 is 20,18,17 walls at
      55% brightness with an ember tint. Neon is untouched (wayfinding), and the
      dimming bottoms out rather than going dark. Guarded by
      `tools/verify/outpost-depth.js`.

Still open here: **what actually goes in the bay.** That is a design decision,
not geometry — the space, the floor and the sign are built.

### 7a. Coin economy — TWO BUGS FOUND 2026-10-05, both P0
- [x] ~~**Chest coin reward crashes.**~~ **Fixed 2026-10-05** — now
      `Dig.Depth.dirtHp(zoneTierOf(zone), layer)`, the same one-coin-per-HP rule
      the dig path uses. Was: `MineServer:4726` calls
      `C.coinsFor("dirt", zone, layer)` with a zone *table*; `coinsFor(kind, mult)`
      does `base × mult` and this Luau throws on `number × table` (reproduced).
      Every chest that rolls the `coins` kind errors before paying. Fix:
      `Depth.dirtHp(zoneTierOf(zone), layer)`. Likely one of the owner's
      reported lucky-block/chest bugs.
- [x] ~~Seams cost 5–60× their stated 30 minutes.~~ **Resolved 2026-10-05 by
      making seams free** (owner: *"buy seams shouldnt cost anything"*).
      `seamPrice` returns 0, `Verbs.buySeam` charges nothing, and the client
      panel reads "Break the seam". Depth is still gated by breaking power and
      seams still open in order. **Watch for:** the client used to bail on
      `price <= 0`, which would have swallowed every seam panel — that guard
      was changed in the same commit, so the chain stays live.
- [ ] **Coins lost their biggest sink.** Seams were one of three (with rebirth
      and shop tools). Potions priced in coins (PROPOSAL line 23) is now the
      load-bearing sink, and §7 below is more open than before, not less.

### 7. Coin economy
Coins are currently near-useless. Proposal on the table and **not yet agreed**:
*ore = power, gems = gambling, coins = consumables and access*, with potions as
the sink. Also: remove the base 2× coin multiplier from rebirths.
- [ ] Get the model signed off before building against it.
- [ ] Decide whether the coin shop survives at all. Kept and working for now;
      **do not polish it before that call.**

### 8. Charms rewrite
Owner, 2026-10-04: *"charms should not just be a huge family of clones. they
would each be different and special in their own way."*
- [ ] 164 generated charms → roughly 24 hand-authored, each with its own rule.
- [ ] Merging costs **gems** (owner's call), not the current path.
- [ ] Jewellery-style icons — owner supplied a reference image (in
      `transcripts/images/`).
- [ ] Decide the legacy 31 (15 zone-grant + 15 gem-pack + 1 limited). They
      predate the ore-drop rule and still drop. Retire, or keep both sources?

### 9. Ore cases and skins
- [ ] Ore packs become **Ore cases**. Assets: `{Ore}` icon, `{Ore}Case` case.
- [ ] 82 cases, one per ore — not per tool rarity.
- [ ] The case rolls 2% → 0.5% to decide whether you get a tool.
- [ ] Reuse the existing charm-find pull-from-pack animation.
- [ ] A case yields a **skin that applies to a whole tool family**.
- [ ] Drop rates identical to tempers today: F 50 / D 27.63 / C 12.5 / B 6.75 /
      A 2.5 / S 0.5 / SS 0.1 / SSS 0.02.
- [ ] Every skin name states which ore and what type of skin.
- [ ] **A skin must not change the tool's colour** — it is a wrap.
- [ ] Rename tempers → skins across `MineTemper.luau` and its views. Keep
      `LEGACY_RARITY` / `normalizeRarity` so old saves load.
- [ ] The skin system inherits what the tool system used to be: rarity ladder,
      drop pacing, the chase.
- [ ] Nerf anything competing with skins for "most desired buff".

### 10. Boost balance — the big one
**Anchor settled 2026-10-05, measured not guessed — see `docs/BALANCE-MEASURED.md`.**
SSS hat +80%, face +100%, pet +375% → Layer 2 ceiling ×15.65, against a measured
Layer 1 ceiling of ×17.55 on `dirtBreak`. Near parity. Three implementation gaps
make the Layer 1 figure an under-count: skins bypass the layers
(`MineServer:2578`), tools never enter `T1` at all, and the Layer 1 skill filter
passes 5 keys while the tree grants 20 (`swingRate` at +698% is outside the
system). Closing those raises Layer 1, so these Layer 2 numbers get more
conservative over time, not less.
- [ ] Wire skins into `T1` — the owner named them in layer 1 and they bypass it
- [ ] Wire tools into `T1` — same
- [ ] Widen the `T1` skill filter past its five keys, and drop the dead
      `walkSpeed` entry (no node grants it)

- [ ] Far fewer pets grant blast on normal pickaxes. At current strength this is
      game-breaking and makes every other pet stack pointless.
- [ ] Fewer pets affect blast radius.
- [ ] Nerf zap and blast.
- [ ] **Almost no effect should do full pickaxe damage** without a dedicated
      amplifier. This is the main lever against every build collapsing into one.
- [ ] Hats nerfed substantially — re-derive the budget with real tests: each
      boost alone, then stacked with its amplifiers.
- [ ] Hats and faces give 1–2 boosts directly to the player; faces bigger than hats.
- [ ] Add hats and faces as chest drops.
- [ ] Make pet and hat buffs more easily matchable with setups.
- [ ] Add drill-friendly boosts.
- [ ] Guardrails preventing too many boosts overlapping.
- [ ] No gear set rolls the new lucks yet. Ten sets, Umbra on generic `luck`;
      pointing three at the new channels changes three sets.

### 11. Four new build boosts — designed, not built
- [ ] **Fracture** — a break lowers adjacent blocks' *strength* (not HP) by X%
      for N seconds. Touches breaking power instead of damage, so it opens
      progression rather than inflating numbers.
- [ ] **Resonance** — consecutive breaks of the *same ore* stack a damage bonus,
      reset by breaking a different ore. Rewards deliberate mining.
- [ ] **Siphon** — a chance to yield ore without consuming the block's normal
      drop roll. Pure economy, zero damage overlap.
- [ ] **Permafrost** — damage persists longer before a block heals. Helps slow,
      heavy builds without raising peak damage.

### 12. Packs — make them fun
Owner, 2026-10-04. Open-all and buy-N already ship. Still open:
- [ ] Pity counters on packs **and** on trait rolls.
- [ ] New drop tables — **still ambiguous, never clarified.** Ask before building.

### 13. Universal recycling
- [ ] Recycle returns 50% in ore and stardust, plus an extra scaled to the item's
      value — "decent but not game breaking". **Needs a curve and sign-off.**
      Current payouts are the old scrap rates, not this.

### 14. Rebirth
- [ ] Multiple rebirths at once.
- [x] ~~Remove the base 2× coin multiplier~~ **It does not exist.** Searched
      every prestige/rebirth/coinMult/`2 ^` path server and shared, 2026-10-05.
      Prestige grants +5% luck per rebirth and skill points, nothing on coins.
- [ ] Confirm: an earlier pass planned "rebirth raises coin value" and "soften
      the zone/depth coin multipliers". Partly motivated by a since-reverted
      change — re-decide rather than inherit.

### 15. The Forge — finishing the rewrite
- [ ] Fold `MineForgeView.luau` (780 lines, temperaments) in as the skin/rune
      application area.
- [ ] Keep the full-screen 3D display from `583d9ad`.
- [ ] Decide whether the Temper/Sockets tabs **move** here, so the Enchanter
      stops owning them. A design call, not a side effect.
- [ ] The bag stays out of the Forge. Cards, packs, runes and gear remain
      inventory-only — the pouch was the part that mattered for forging.

### 16. Depth leaderboard
- [ ] Live update. Deepest-depth tracking already exists server-side.

---

# P2 — after launch

- [ ] 28 legacy packs onto the ore system in `MinePackConfig` (anomaly, apex,
      ashen, cinder, clay, cobalt, crimson, end, heirloom, hopper, iron, loam,
      magma, night, omen, …).
- [ ] Luck → Treasure Hunter refactor. 47 `luck` references. Names floated:
      Divining Rod, Loadstone, Assayer's Eye. Overlaps the P1 luck split.
- [ ] Zone-1 case rates lower. `MineZonePacks.cardOdds(zoneIndex, heat)` takes
      the zone index and then ignores it.
- [ ] Chests spawn everywhere but supremely rare, like ore.
- [ ] Space ores — 40, a separate set. Spec in `docs/ore-remake.md`, unapplied.
- [ ] Tool generator LOOKS table needs the live roster.
- [ ] Export `OreShapes` and other place-only instances to `.rbxm`.
- [ ] Delete the duplicate Event Horizon pet module — 34 KB that never loads.
- [ ] Event Horizon `minRebirth` is 0 while its surface is 1.30e9 HP.
- [ ] Group wheel and battle pass — both archived in `src/ServerStorage/MineParked/`.
- [ ] Retire runes (stage 3). **Deliberately deferred** until someone has
      verified traits in-engine. Do not start this before P0 item 2.

---

# Deferred, with a reason — do not "fix" these

- **1.5× per 25 layers HP curve.** Not applied, on purpose. It makes L4921
  1.4e23× harder and breaks every hand-tuned chest and fossil tool. **Breaking
  power may remove the need for it entirely** — settle item 3 first.
- **Chests → packs only.** Superseded by the chest table rework and by skins and
  hats moving into chests.
- ~~**`ORE_GEM_SPREAD` magnitude.**~~ **SETTLED 2026-10-08.** The deferral
  (*"we tackle that later"*) was superseded by `docs/PROPOSAL.md` §0 line 16,
  which the owner approved on 2026-10-05 — 1e6 → **1e4**. Applied. This note
  outliving the sign-off is why it sat unimplemented for three days, so it is
  struck rather than deleted. `tools/verify/gem-spread.js` now pins the code to
  the approved line, in both directions.

---

# BLOCKED — needs the owner, not an agent

`docs/BLOCKED.md` explains each in detail and gives a suggested default for
every one. **Paste that file's copy-paste block back with the lines you disagree
with changed** and most of these clear at once.

| # | blocked on | kind |
|---|---|---|
| 1 | Ore icon source — art is on the owner's local drive | REACH |
| 2 | Charm and ore icons — owner is drawing them; the 164 generated ones are rejected | FACT |
| 3 | Asset uploads — no agent here can upload to Roblox (§7 of TODO governs) | REACH |
| 4 | `ToolBakers.OreToolBaker` syncback — 82-row roster needs diffing against `MineConfig` | REACH |
| 5 | Rojo syncback — reported connected, never actually run | REACH |
| 6 | `ORE_GEM_SPREAD` magnitude — deferred by the owner | TASTE |
| 7 | ~~Seam purchase~~ **CLEARED** — wired end to end, see P0 item 1. Confirm in-game. | — |
| 8 | Zone and rune gem prices — flat tables the ore curve will outrun | TASTE |
| 9 | The legacy 31 charms — retire, or keep both sources? | TASTE |
| 10 | VIP lost a perk when the 4th pet seat went. Replace, or leave at three? | TASTE |
| 11 | Suffixes past `Nod` (10^63) — two docs disagree, `bignum.js` pins the current one | TASTE |
| 12 | Hat/pet/face boost budget — every nerf above needs target numbers | TASTE |
| 13 | `OreBalanceSim` is broken — reads five `MineConfig` symbols the `c59bec5` merge removed | FACT |

---

# Housekeeping

- [ ] **Delete `src/ReplicatedStorage/Mine/Shared/_c.luau`** — a 1,710-line copy
      of MineConfig, required by nothing, with its own `ORES` and `coinsFor`.
- [x] ~~193 pets carry a retired stat line~~ **Done 2026-10-10.** Every named
      pet's kit was regenerated onto the PROPOSAL ladder (`tools/gen/zone-pets.js`),
      with no `backpack` or `walkSpeed`. `MineStats.TYPE_KITS` and the X/Y bags are deleted.

- [x] **A skip was being reported as a pass — fixed 2026-10-05 by
      `tools/verify/suite.sh`.** 11 of the 23 checks shell out to the luau
      binary; without it they print "skipping" and exit 0. Measured with the
      binary removed: 10 passed, 11 did not run, and the old hand-run reported
      that as clean. The runner now separates DID NOT RUN from pass and exits
      non-zero. **Always run `syntax.sh` before `suite.sh`.**
- [ ] **Three negative assertions still need a non-zero floor.**
      `check(x.length === 0)` passes when the regex finds nothing, so these
      assert over an empty slice if their pattern ever stops matching:
      `skilltree.js:48`, `skilltree.js:100`, `forge-snap.js:63`. The roster
      parsers (`charms`, `orepacks`, `build-stamp`) already floor their counts
      and are fine.
- [ ] `tools/verify/luau-balance.js` is a **utility, not a check** — it scans one
      chunk passed as `argv[2]` and crashes on `readFileSync(undefined)` when run
      bare. Give it an arg guard so it prints usage instead. `suite.sh` excludes
      it.
- [x] **`check.js` was reading a deleted design — fixed 2026-10-05.** The
      calculator is now generated from `MineConfig` by
      `tools/gen/upgrade-calculator.js` (82 ores, cap 100, down from a
      hand-written 121/1000 that priced Sandstone, Electrum and Zircon).
      `--check` fails if it goes stale. `check.js` now derives `TOP` and `CAP`
      from the data instead of hardcoding 121 and 1000, and its two frozen
      thresholds were replaced with live ones: the "levelling is a real climb"
      floor is now one tier step read off `tierPower` (maxing a tool is worth
      **8.2 tiers**), and the deepest-block floor is computed from
      `MineDepth.dirtHp` rather than the `2e20` that came from the formula
      MineConfig labels *"Dead constants. Do not revive"*. Real hardest block is
      **1.47e11**, cleared in **2.04 raw swings**.
- [ ] **`zones.js` is the same bug a third time, and it is RED on this branch.**
      Its header says "ore spread vs live MineConfig.oreWeights" but it has one
      `readFileSync` (the HTML), never opens a `.luau`, and never computes
      `oreWeights` — the "game" column is a **hardcoded `SPREAD` table**. With
      the roster current, 9 of its 10 rows agree exactly and one diverges:
      `bigbang` layer 5000, top share 11.1 game / 12.1 page, n95 17 / 13.
      The live game's expectation is identical at bigbang layer 1 and layer 5000
      (11.1 / 17) despite D going 10.04 → 24.41, so the game plateaus and the
      page does not. **Not a constant:** `DMAX` was the obvious suspect and
      sweeping it over 23.41 / 28 / 32.09 / 40 changes nothing, so the page's
      own documented "DMAX is stale" note is a red herring for this row. Fixing
      it means porting MineConfig's `oreWeights` clamp into the page, or better,
      making `zones.js` actually read the Luau it claims to.
      **Deliberately not added to `suite.sh`'s `KNOWN_FAIL`** — it is a real
      disagreement, newly visible, and hiding it is how `trap.js` taught
      everyone to ignore red.
- [ ] ~~`check.js` reads a deleted design.~~ `tools/verify/check.js:3` loads
      `upgrade-calculator.html` and runs its embedded tables — still the
      121-ore/1000-level roster, pricing Sandstone, Electrum and Zircon, none of
      which exist. Live `MineConfig.ORES` is 82, Stone → Oganesson. Point the
      check at `MineConfig`; keep the HTML only as a generated view if it is
      wanted at all. **Until then the one check with "ore" and "gems" in its
      output is measuring a design that was deleted.**
- [ ] `tools/verify/trap.js` **fails on clean main.** Pre-existing, and listed in
      `suite.sh`'s `KNOWN_FAIL` so it does not mask a new failure. Either fix it
      or delete it — right now it trains everyone to ignore a red suite.
- [ ] `roadmap/CHARMS.md` is on disk from a merge. Read it, but TODO §0 wins
      wherever it disagrees.
- [ ] Wire `MineCharmIcons.icon(charmId)` into the charm rows once ids exist.
      Nothing reads it yet.
- [ ] Regenerate block **face** textures procedurally — no shadow, every chunk
      fully on its own face, never across a corner. The supplied images have
      specks as chunks and chunks half-off the block.
- [ ] PR #2 `ore-face-art` does **not** cover the face problem — owner checked.
      Do not merge it expecting a fix.
