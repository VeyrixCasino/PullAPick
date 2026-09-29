# Launch roadmap

Target: **balanced, launch-ready, economy that survives its first month.**

This is the live board. Items move, get added and get deleted constantly —
that is the point of it. `docs/TODO.md` stays the record of what has already
landed; this is what is ahead and in what order.

Every item carries the **cheap path**, because cost is a constraint: the game
has to fund its own API bill.

---

## The one rule that orders this list

An economy dies from **missing sinks**, not from missing content. Coins have
three sinks in the entire game (shop tool, depth-shop tool, rebirth); gems have
eight or more. Seam access fixed the coin problem structurally — it repeats
forever and scales at exactly the rate income does. Ore and tokens still have
no recurring sink worth the name.

So: **sinks before content, content before polish.** An item that adds a sink
outranks an item that adds a thing to look at, every time.

---

## P0 — launch blockers

- [ ] **Depth gate UI.** The gate is live and priced (13 seams, 30 min each)
  but nothing calls `Verbs.buySeam`, so players stop dead at layer 500.
  **The game cannot ship in this state.**
  *Cheap path:* `MineDepthPlazas` already owns the seam prompt geometry and
  already runs an unlock check there. Extend that prompt rather than building
  a new panel. `MineDepth.seamPrice(seam, zi)` gives the figure.

- [ ] **Nowhere to equip a tool.** You cannot change your pickaxe. Everything
  else about tools — 82 baked models, bench, upgrade, recycle, `equipOreTool`
  — is built and reachable, and the one verb that makes it matter has no
  button. Same shape of bug as the depth gate.

- [ ] **Battle pass claim does not persist.** Notification still says 2 to
  claim, and a relog lets you claim again. That is a duplication bug in a
  *monetised* system, so it is a launch blocker on money grounds, not polish.
  *Suspect:* claim writes to the profile but never `markDirty`, so it is never
  saved. Cheap to confirm, cheap to fix.

- [ ] **Redo the tutorial, end to end.** It predates ores, packs, the bench,
  charms and depth entirely, so it teaches a game that no longer exists.
  Requirements: ends by handing a **Stone pickaxe**, and the charm it grants
  must be **stone-upgradeable** (see the charm sink below).
  *Note:* there is no tutorial module — the logic is smeared across
  `MineServer`, `MineClient` and `MineConfig`. Pulling it into one module is
  most of the work and makes the rest trivial.

- [ ] **Materials tab in the bag.** One place that ranks everything by rarity:
  all 82 ores and all unsold blocks. This is not only QoL — it is the screen
  that makes an ore sink legible, and it has to exist before ore sinks mean
  anything.

---

## Economy — the part that decides whether this survives

- [ ] **Ore sink.** Ore is a pure source today: it is mined, banked, and never
  consumed. Candidates already designed: ore as a rebirth ingredient (large,
  recurring, and safe because the rebirth curve is a hard gate the loop does
  not control), and ore → gem sell pad (`MineConfig` already carries the
  curve: `gemBase 2`, `gemSpan 1.5`).
- [ ] **Stone as charm upgrade material.** From the tutorial requirement, and
  it doubles as the early ore sink. **Constraint, not negotiable:** no charm
  that drops from ore may boost ore acquisition, or it is the bootstrap loop
  again. Three charms currently carry `oreYield`.
- [ ] **Token sink.** Temperament tokens buy rolls and nothing else.
- [ ] **Gem sinks** — confirmed eight or more already. Likely fine; verify, do
  not add.
- [ ] **Coin sinks beyond seams.** Bag capacity, cosmetics (infinite, zero
  power), re-rolling an ore tool's *type* while keeping the ore.
- [ ] **The rebirth knee at 9.** `rebirthCost` grows ×2.08 forever but there
  are only 10 zones, so past the last gate cost outruns income 54-fold. The
  code comment already warns about exactly this.
- [ ] **`REBIRTH_BASE` 7500 → ~3600**, and the whole price ladder re-derived
  in minutes rather than coins.

---

## The four curves — one change, not four

HP, coin value, ore power and shop power were tuned against each other and any
one alone is worse than today. Do not ship them piecemeal.

- [ ] `dirtHp(Z,L) = (20 + 1.5L) · 5^(Z-1)` — replaces a curve that multiplies
  ×2.1495 every 40 layers.
- [ ] `coinValue(Z,L) = 5^(Z-1) · (1 + 0.075L)^0.9`
- [ ] `orePower(Z,L) = (5 + 0.36L) · 5^(Z-1) · tierMult`, **`tierMult` inside
  1.0–3.0.** Today the spread is 500×, which is why builds feel pointless: a
  committed skill build is worth 2–4× and a 500× term drowns it.
- [ ] `shopPower(Z,r) = 5 · 2^(r-1) · 5^(Z-1)`
- [ ] **Blocks/hour is unmeasured.** Every coin price scales off an assumed
  2,000. Measure in Studio before any price is final.
- [ ] **2⁵³ overflow.** `SECTIONS` authors layer 10040 at `9.3e18` — 1,033×
  over. The linear HP curve removes this; nothing else does.

---

## Bugs and removals — cheap, do them in one pass

- [ ] **Remove remote sell.** Broken, and coming back later by decision.
- [ ] **Remove fossil packs.** 28 references.
- [ ] **Remove pet slot 4.**
- [ ] **Fix pet slots 2–3**, and render hats on pets.
- [ ] **Close inventory when a lucky block or case opens.**
- [ ] **Open-all: click anywhere to dismiss** when the run finishes.
- [ ] **Fossil code is still live** — two sites roll `Fossils.RECIPES` into
  `p.fossilPieces`, scaled by `fossilFind`, which is now labelled "Ore Finder".
  A stat called Ore Finder multiplying fossil pieces needs resolving.

---

## Packs and icons

- [ ] **Ore packs are annoying to open.** Reduce steps; make tools always
  show as hits.
- [ ] **Pack icons**, matching every other pack.
- [ ] **Card icon on everything** — gems use the gem icon, each ore uses its
  own ore icon.
- [ ] **Icons for every inventory item.**
- [ ] **Icons for all 82 ores.**
- [ ] **Icons for all ore tools** — 15 bodies (5 pickaxe, 5 drill, 5
  explosive) × 82 ores, recolouring the tip or the ore-bearing part.

**How art gets made here — no Canva, no uploads.** Two pipelines already
exist and both cost nothing:

1. `MineOreArt` encodes art as base64 RLE pixels and rebuilds them at runtime
   with `AssetService:CreateEditableImage`. 480 KB of pixels packs to 53 KB.
   No upload, no moderation queue, no group-ownership wall. `MineIcons`,
   `MineToolIcons` and `MineGearIcons` are the existing homes.
2. For the 82 ore tools specifically: `ServerStorage.OreToolBaker` already
   bakes every one with colour, material and glow read from
   `MineConfig.ORES`. **A `ViewportFrame` render of the baked model is the
   icon** — 82 × 15 combinations for free, always in sync with the model,
   nothing to draw and nothing to upload.

- [ ] **Replace the ore block pattern.** Current pattern is weak. Flat
  per-ore colours are an acceptable interim and are nearly free via the same
  palette the baker reads.
- [ ] **Find the tool models and put them on shop tools** / replace shop
  tools with ore tools. `ToolModelFactory.luau`, `MassToolGenHelper.luau` and
  `ReplicatedStorage.ToolModels_50` are the three pieces; `ToolModels_50` is
  place-only and untracked, which is its own risk.

---

## Flagged — do not act on these without reading the note

- [ ] **"Make way fewer ores — 1 in 100–200."** `ORE_CHANCE` is **already
  `1/200`** (`MineConfig.luau:2058`), the rarer end of the ask. So the felt
  problem is not the spawn rate.
  **Most likely cause:** blast, zap and echo destroy many blocks per swing and
  *every* block rolls independently, so a 20-block blast is 20 rolls — an ore
  roughly every 10 swings. If that is it, the fix is rolling per *swing* or
  damping the roll by blocks-broken, **not** lowering `ORE_CHANCE`.
  Standing rule: report the numbers and stop. **Measure first.**

- [ ] **Ore rarity has no scarcity dimension.** `oreWeights` normalises to
  1.0, so depth decides *which* ore and nothing decides *whether*. The fix is
  a real per-ore weight with the leftover probability becoming "no ore" —
  not another `ORE_DMAX` value. A previous `ORE_DMAX` change made Oganesson
  the commonest ore in the game at 31.7%.

- [ ] **`_c.luau` is dead** — a 1,700-line `MineConfig` copy that nothing
  requires but Rojo still syncs into Studio. Awaiting a decision to delete.

---

## Honest notes on the 2–3 day target

- **The four curves are the whole ballgame.** A stable economy is those plus
  the sinks. Everything under Packs and icons is polish and can ship after
  launch; none of it stabilises anything.
- **Several items need Studio** and cannot be done from the repo: the depth
  gate prompt, equip UI placement, tool model wiring, anything visual. The
  Studio MCP attaches at session start, so those need a session launched with
  it live.
- **Blocks/hour being unmeasured** is the single largest risk to the number
  work. Every price scales off it. It is a short measurement and it should
  happen first, in Studio.
