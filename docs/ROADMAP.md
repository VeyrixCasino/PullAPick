# Launch roadmap

Target: **balanced, launch-ready, an economy that survives its first month.**
Fun, grindy, full of dopamine.

Live board — items move, get added and get cut constantly. `docs/TODO.md` is the
record of what already landed; this is what is ahead and in what order.

Every item carries its **cheap path**: the game has to fund its own API bill.

---

## Standing rules

**Server-authoritative, always.** The client asks; the server decides, re-prices
and re-checks. Never trust a client-sent cost, count, id or rarity. Every new
verb validates ownership and affordability server-side even when the UI already
greyed the button out.

**Mobile-first UI.** Size in scale with a `UISizeConstraint`, never raw offsets.
Anchor button rows to the bottom edge. Scale-width buttons, `TextTruncate.AtEnd`,
tap targets ≥44px, smaller text under `UIS.TouchEnabled`. Copy
`MineGradeReveal:508` or `MineClient:2117`.

**Sinks before content, content before polish.** An economy dies from missing
sinks, not missing content.

**Never touch ore spawn chances without saying so.** `ORE_CHANCE`, `ORE_X0/K/S/W`,
`ORE_DMAX`, and the bodies of `oreWeights` / `oreIdentity` / `rollOre`. Any edit
to the depth axis rewrites every ore's rarity at once. Report numbers and stop.

---

## P0 — BLOCKING, fix before anything else

- [ ] **`ORE_DMAX` is calibrated to the old HP curve.** Landing linear HP
  collapsed ore progression: most-likely tier at layer 10,000 fell from **49 to
  1**, so ~73 of 82 ores are unreachable and it is Stone forever.

  `oreDifficulty = log(hp/20)/log(6)` assumes geometric HP. `ORE_DMAX` is still
  **32.09**, derived from the old `SECTIONS` top of `9.3e18`, while the new curve
  tops out at `1.5e4` in Meadow and `2.93e10` in Primordium — max reachable
  `dl` ≈ **11.8**.

  Re-derive `ORE_DMAX` from the live curve so 82 tiers span the reachable range.
  **Needs sign-off** — a previous `ORE_DMAX` edit made Oganesson the commonest
  ore in the game at 31.7%. Show the full distribution before and after.

- [ ] **Ore icons.** `Downloads/oreicons/src.txt` is **0 bytes** — nothing to
  import. Re-export and I will wire them.
  *Cheap path:* `MineOreArt` already packs art as base64 RLE pixels rebuilt via
  `AssetService:CreateEditableImage` — 480 KB → 53 KB, no upload, no moderation
  queue, no ownership wall. `tools/slice-ore-sheet.js` and `pack-ore-art.js`
  already do the slicing and packing.

---

## The redesign

### Breaking power — a hard wall, not a stat

- [x] ~~**Breaking power decides WHETHER you can damage a block at all**~~
  **CORE DONE, unshot** — `MineBreaking.luau`, gated server-side in the swing
  path before damage is computed, red hotbar warning on the client. Shop picks
  BP 1-5 reach layers 1-500, landing exactly on the first zone gate; forged
  tools carry BP equal to their ore strength, tier 82 reaching layer 10,000.
  A Wood pick cannot touch Oganesson even at layer 1, so breaking power
  BACKSTOPS the ORE_DMAX regression. Still to do: put BP on the tool UI, and
  stamp it at craft time once forging exists.

  - Every **block** and every **ore** carries a **strength**.
  - A tool damages it only if `blockStrength <= tool.breakingPower`.
  - Otherwise **zero** damage — a tool with 1,000 damage and insufficient
    breaking power physically cannot scratch the block.
  - Red text by the hotbar: **"Your tool is too weak to damage this block"**.

- [ ] **Breaking power CANNOT be upgraded.** Only damage can. Breaking power is
  a property of the tool you crafted — which ore it is made of. That is what
  forces progression: you cannot grind your way past a wall, you must go and
  make a better tool out of better ore.

  Why this is the right shape: it is a **step gate on a bounded ladder**, so it
  can carry depth and ore access with no runaway. Every previous attempt used a
  *multiplicative* term on an ungated axis, which is what produced the 561×
  overpowered pickaxe. A wall cannot compound.

  It also takes the gating job away from ore rarity — which is exactly the job
  `ORE_DMAX` is currently doing badly. **Do breaking power before re-tuning the
  d-ladder**, so rarity can be retuned to something gentle rather than being
  the sole gate.

### Runes — total overhaul

The 2%–0.5% per-ore rate moves here. Runes are the ore-specific drop; tools are
crafted, not found.

- [ ] **Runes are for TOOLS only.** Everything else loses rune sockets — pets,
  gear, all of it.
- [ ] **Ore-specific.** Each ore has its own rune, dropping at that ore's own
  rate, **2% down to 0.5%** across the roster.
- [ ] **Rarity F → SSS**, a wide spread.
- [ ] **One rune slot per tool.** Exactly one.
- [ ] **Binding is permanent.** A bound rune cannot be removed — only destroyed.
  This is the sink: every rune bound is a rune consumed, and re-rolling a build
  costs you the rune.
- [ ] **Presented like charms** in the UI, but the effect is a tool buff.

### Ore, crafting and upgrades

- [ ] **Ore blocks drop ORE directly.** No ore packs. Removes a whole layer of
  indirection and the "new ore packs are annoying to open" complaint with it.
- [ ] **Tools are CRAFTED from ore**, not found.
- [ ] **Tools stay upgradeable with ore**, and upgrades cost *a lot* — endgame
  tools should be genuinely hard to reach.
- [ ] **Anti-flood on tools.** Four levers, all sinks:
  - Sell price in **gems**, deliberately generous.
  - **Recycle** value deliberately generous.
  - **Ore-for-ore upgrade trading** — recycled ore converts to gems or to other
    ore, so players trade up for a better deal.
  - **Downgrading is blocked.** Conversion is a one-way ratchet upward. Without
    it, a player reaches a good mine, grabs a little rare ore and converts it
    down into a mountain of common ore — rare ore becomes a printing press for
    cheap ore, and deep access floods the shallow market.

### Skins (was temperaments)

- [ ] **Tool skins are a cosmetic wrap only** — zero power.
- [ ] **Rare drops from chests.**
- [ ] **Big rarity disparity**, and **no single case may contain every skin.**

### Temperament buffs

- [ ] **Drastically stronger, and specific.** Each temperament does a named
  thing rather than nudging a generic stat, with a large rarity spread.
  *Constraint:* anything the boost stack multiplies must be capped — the stack
  is multiplicative across 8 pet slots.

### Hats, faces, pets

- [ ] **Nerf hats and faces**, and add them as a chest drop.
- [ ] **Not every pack can spawn every pet.**
- [ ] Fix pet slots 2–3 and render hats on pets. Remove pet slot 4.

### Progression rework

- [ ] **Your pickaxe and all equipment survive rebirth.** Rebirth stops being a
  wipe.
- [ ] **Zones become coin-purchased.**
- [ ] **The nine prestige gates STAY.** Rebirth is not retired.
- [ ] **Rebirth grants a coin-value increase.**
- [ ] **The dirt price boost applies only BELOW each zone gate.** The zone's
  upper reaches pay base rate; the boost starts under the gate. So depth pays
  because you bought through the gate, not because the layer number is large —
  which is what keeps depth from substituting for breadth without needing a
  tuned exponent to hold it back.
- [ ] **Therefore soften the zone and depth coin multipliers.** Rebirth now
  carries income growth, so the ×5 zone term and the depth term both come down.
  *Note:* zone prices and seam prices are derived, so they re-price themselves
  once the multipliers move. Do not hardcode.

### The Forge (was the Blacksmith)

- [ ] **Rename Blacksmith → Forge** throughout.
- [ ] **Keep the 3D display exactly as it is.** The full-screen stage, camera
  framing and plinth all stay; this is a menu change around them.
- [ ] **Scroll a vertical recipe list** to pick which tool to craft.
- [ ] **Only discovered ores appear.** An undiscovered ore must not leak its
  existence through the recipe list — that is a server-side filter, not a
  client-side hide.
- [ ] **Each recipe shows the ore cost** to make that tool.
- [ ] **A separate Upgrades area**, which is also where **runes and skins** get
  applied.
- [ ] **The whole inventory shows here**, bag included.
- [ ] **Bag upgrades cost gems and are PERMANENT** — they survive rebirth.
  *Note:* bag rungs already price in gems (`100 × 1.08^x`), so the change is
  permanence, not currency.

---

## Economy sinks — the survival test

- [ ] **Ore sink** — ore is still a pure source. Crafting and upgrades become
  the big one; ore as a rebirth ingredient is the other.
- [ ] **Token sink** — temperament tokens buy rolls and nothing else.
- [ ] **Coin sinks beyond seams** — bag capacity, cosmetics, re-rolling a
  tool's type while keeping the ore.
- [ ] **Gem sinks** — eight or more already; verify rather than add.
- [ ] **The rebirth knee.** `rebirthCost` grows ×2.08 forever against 10 zones.
  Reworking rebirth into a coin-value grant may retire this entirely.

---

## Curves — status

- [x] ~~**Block HP linear**~~ **done, verified live** —
  `(20 + 1.5L)·5^(Z-1)`, `ZONE_HP_MULT` 6→5. Max 29.3B vs 2⁵³, **307,036×
  headroom**; the precision bug is gone. Smooth every layer, 0 flat pairs and 0
  decreases across 10,000. `SECTIONS` keeps its 138 names as signposting.
  **Caused the `ORE_DMAX` regression above.**
- [x] ~~**Blocks/hour measured**~~ **429/hr fresh, not 2,000.** Real model is
  `dmg = tool.power × mineSpeed × dirtBreak`; `PICKAXES` power is 1/2/3/5/8.
  Collapses to 1/hr by layer 499 with shop tools, which is why depth is
  currently unreachable.
- [ ] **Coin value** — `5^(Z-1)·(1+0.075L)^0.19` was agreed, but the
  progression rework changes the inputs. Re-derive after rebirth/zone pricing
  is settled, or it gets priced twice.
- [ ] **Shop power** — `5·2^(r-1)·5^(Z-1)`. Unblocked.
- [ ] **Ore power** — blocked on crafting existing.
- [ ] **Seam price** is denominated in a currency curve the game does not use
  yet: it assumes 2,000 blocks/hour and the target coin curve, while the game
  pays a flat 3 coins a block. Reads 14,428 coins = **673 minutes** against a
  30-minute design. Derived, so it self-corrects — do not hand-edit.

---

## Bugs and removals — one pass

- [x] ~~Remove remote sell~~ **done**
- [x] ~~Battle pass double-claim~~ **done** — `markDirty` does not save.
  **Sweep pending:** any other verb granting something valuable and calling only
  `markDirty` has the same 45-second hole.
- [ ] **Remove fossil packs** (28 refs), and resolve fossil code still rolling
  `Fossils.RECIPES` scaled by `fossilFind`, now labelled "Ore Finder".
- [ ] **Close inventory when a lucky block or case opens.**
- [ ] **Open-all: click anywhere to dismiss** when the run finishes.
- [ ] **Nowhere to equip a tool** — `equipOreTool` exists, no button.
- [ ] **`MineFossils.ZONE_HP_MULT` is still 6** and now disagrees with
  `MineDepth`.
- [ ] **`_c.luau` is dead** — 1,700-line `MineConfig` copy nothing requires,
  still synced into Studio. Awaiting a delete decision.
